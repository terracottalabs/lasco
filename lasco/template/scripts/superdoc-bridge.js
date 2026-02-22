#!/usr/bin/env node
/**
 * SuperDoc Bridge — Headless DOCX manipulation for Claude Code
 *
 * Uses @superdoc-dev/cli for text extraction (getDocument) and leverages
 * direct DOCX XML manipulation via JSZip for comments, highlights, tracked
 * changes, and text insertion (features not yet in the CLI).
 * The SuperDoc VS Code extension auto-refreshes when the file changes on disk.
 *
 * Commands:
 *   getDocument      --file <path> --format text|json
 *   addComment       --file <path> --find "<text>" --author "<name>" --text "<annotation>"
 *   addHighlight     --file <path> --find "<text>" --color "#FFE0E0"
 *   suggestEdit      --file <path> --find "<old>" --replace "<new>" --author "<name>"
 *   insertText       --file <path> --at end|start --text "<content>"
 *   addLink          --file <path> --find "<text>" --url "<href>"
 *   createDocument   --file <path>   (reads JSON from stdin)
 *   refresh          --file <path>
 */

import { readFileSync, writeFileSync, renameSync, existsSync } from "fs";
import { resolve, dirname, join } from "path";
import { execSync } from "child_process";
import { fileURLToPath } from "url";
import crypto from "crypto";

const __dirname = dirname(fileURLToPath(import.meta.url));
import minimist from "minimist";
import JSZip from "jszip";
import {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  ExternalHyperlink, HeadingLevel, AlignmentType, WidthType,
  ShadingType, UnderlineType, BorderStyle, TableLayoutType,
} from "docx";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function die(msg) {
  console.error(`Error: ${msg}`);
  process.exit(1);
}

function requireArg(args, name) {
  if (!args[name]) die(`Missing required argument: --${name}`);
  return args[name];
}

function resolveFile(filePath) {
  const abs = resolve(filePath);
  if (!existsSync(abs)) die(`File not found: ${abs}`);
  return abs;
}

/** Escape XML special characters. */
const escXml = (s) =>
  s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");

/**
 * Extract <w:rPr>...</w:rPr> from the nearest <w:r> run containing or
 * preceding `position` in `docXml`.  Returns the full <w:rPr>…</w:rPr>
 * string, or "" if none is found.  Optionally strips specific child
 * elements (e.g. color/underline) via `stripTags`.
 */
function extractRPr(docXml, position, stripTags) {
  // Walk backwards to find the nearest <w:r> or <w:r ...> opening tag
  const before = docXml.slice(0, position);
  const runStartA = before.lastIndexOf("<w:r>");
  const runStartB = before.lastIndexOf("<w:r ");
  const runStart = Math.max(runStartA, runStartB);
  if (runStart === -1) return "";

  const runEnd = docXml.indexOf("</w:r>", runStart);
  if (runEnd === -1) return "";
  const runXml = docXml.slice(runStart, runEnd + "</w:r>".length);

  const rPrMatch = runXml.match(/<w:rPr>[\s\S]*?<\/w:rPr>/);
  if (!rPrMatch) return "";

  let rPr = rPrMatch[0];
  if (stripTags && stripTags.length) {
    for (const tag of stripTags) {
      // Remove both self-closing and open/close forms
      rPr = rPr.replace(new RegExp(`<w:${tag}[^/]*/>`, "g"), "");
      rPr = rPr.replace(new RegExp(`<w:${tag}[^>]*>[\\s\\S]*?</w:${tag}>`, "g"), "");
    }
  }
  // If stripping left an empty rPr, return empty
  if (rPr.replace(/<\/?w:rPr\s*>/g, "").trim() === "") return "";
  return rPr;
}

/**
 * Merge an existing <w:rPr> string with additional child elements.
 * `additions` is a string of raw XML child elements to insert.
 * Returns a complete <w:rPr>...</w:rPr> string.
 */
function mergeRPr(existingRPr, additions) {
  if (!existingRPr && !additions) return "";
  if (!existingRPr) return `<w:rPr>${additions}</w:rPr>`;
  if (!additions) return existingRPr;
  // Insert additions before the closing </w:rPr>
  return existingRPr.replace("</w:rPr>", `${additions}</w:rPr>`);
}

/**
 * Atomic write: write to a .tmp file then rename to avoid corrupt reloads
 * by the SuperDoc VS Code extension.
 */
function atomicWrite(destPath, buffer) {
  const tmp = destPath + ".tmp";
  writeFileSync(tmp, buffer);
  renameSync(tmp, destPath);
}

/** Load a DOCX as a JSZip instance. */
async function loadDocx(filePath) {
  const buffer = readFileSync(filePath);
  return JSZip.loadAsync(buffer);
}

/** Get word/document.xml from the zip, or die. */
async function getDocXml(zip) {
  const xml = await zip.file("word/document.xml")?.async("string");
  if (!xml) die("Cannot find word/document.xml in DOCX");
  return xml;
}

/** Write the zip back to disk atomically. */
async function saveDocx(zip, filePath) {
  const output = await zip.generateAsync({ type: "nodebuffer" });
  atomicWrite(filePath, output);
}

/**
 * Trigger SuperDoc VS Code extension to refresh by touching the file.
 * SuperDoc watches for file changes on disk — a brief delay + re-touch
 * ensures the extension picks up changes reliably.
 */
async function triggerRefresh(filePath) {
  // Small delay to let the filesystem settle, then touch the file
  // to ensure the VS Code file watcher fires
  await new Promise((r) => setTimeout(r, 200));
  const now = new Date();
  try {
    const { utimesSync } = await import("fs");
    utimesSync(filePath, now, now);
  } catch {
    // If utimes fails, do a no-op read+write to trigger the watcher
    const buf = readFileSync(filePath);
    writeFileSync(filePath, buf);
  }
}

// ---------------------------------------------------------------------------
// createDocument — build a DOCX from a JSON schema piped via stdin
// ---------------------------------------------------------------------------

/** Read all of stdin as a string. */
async function readStdin() {
  const chunks = [];
  for await (const chunk of process.stdin) chunks.push(chunk);
  return Buffer.concat(chunks).toString("utf-8");
}

/** Convert a JSON inline element to a docx TextRun or ExternalHyperlink. */
function buildInline(item) {
  if (typeof item === "string") return new TextRun(item);

  if (item.type === "link") {
    return new ExternalHyperlink({
      link: item.url,
      children: [
        new TextRun({
          text: item.text || item.url,
          bold: item.bold || false,
          italics: item.italics || false,
          color: "0563C1",
          underline: { type: UnderlineType.SINGLE },
          ...(item.font ? { font: { name: item.font } } : {}),
        }),
      ],
    });
  }

  // Default: text run
  const opts = { text: item.text || "" };
  if (item.bold) opts.bold = true;
  if (item.italics) opts.italics = true;
  if (item.color) opts.color = item.color;
  if (item.size) opts.size = item.size;
  if (item.underline) opts.underline = { type: UnderlineType.SINGLE };
  if (item.font) opts.font = { name: item.font };
  return new TextRun(opts);
}

/** Convert a JSON block to a Paragraph. */
function buildParagraph(block) {
  // Resolve inline children
  let children;
  if (block.children && Array.isArray(block.children)) {
    children = block.children.map(buildInline);
  } else if (block.text != null) {
    children = [new TextRun(String(block.text))];
  } else {
    children = [];
  }

  const opts = { children };

  // Heading level
  if (block.type === "heading" && block.level) {
    const levelMap = {
      1: HeadingLevel.HEADING_1,
      2: HeadingLevel.HEADING_2,
      3: HeadingLevel.HEADING_3,
      4: HeadingLevel.HEADING_4,
      5: HeadingLevel.HEADING_5,
      6: HeadingLevel.HEADING_6,
    };
    opts.heading = levelMap[block.level] || HeadingLevel.HEADING_1;
  }

  // Bullet / numbering
  if (block.bullet != null) {
    opts.bullet = { level: block.bullet };
  }

  // Alignment
  if (block.alignment) {
    const alignMap = {
      center: AlignmentType.CENTER,
      right: AlignmentType.RIGHT,
      justify: AlignmentType.JUSTIFIED,
      left: AlignmentType.LEFT,
    };
    opts.alignment = alignMap[block.alignment] || AlignmentType.LEFT;
  }

  // Spacing
  if (block.spacing) opts.spacing = block.spacing;

  // Thematic break
  if (block.type === "rule") opts.thematicBreak = true;

  return new Paragraph(opts);
}

/** Convert a cell definition to a TableCell. */
function buildTableCell(cellDef, colWidthTwips) {
  const paragraphs = (cellDef.paragraphs || []).map((p) => buildParagraph(p));
  // If no paragraphs provided, use a simple text shorthand
  if (paragraphs.length === 0 && cellDef.text != null) {
    paragraphs.push(new Paragraph({ children: [new TextRun(String(cellDef.text))] }));
  }
  // TableCell requires at least one child
  if (paragraphs.length === 0) {
    paragraphs.push(new Paragraph(""));
  }

  const opts = { children: paragraphs };
  if (cellDef.shading) {
    opts.shading = { type: ShadingType.CLEAR, fill: cellDef.shading };
  }
  // Explicit cell width from JSON takes priority, then column width from table grid
  if (cellDef.width) {
    opts.width = cellDef.width;
  } else if (colWidthTwips) {
    opts.width = { size: colWidthTwips, type: WidthType.DXA };
  }
  if (cellDef.columnSpan) opts.columnSpan = cellDef.columnSpan;
  if (cellDef.rowSpan) opts.rowSpan = cellDef.rowSpan;
  return new TableCell(opts);
}

/** Convert a table JSON block to a Table. */
function buildTable(block) {
  const defaultBorder = { style: BorderStyle.SINGLE, size: 1, color: "000000" };

  // Available page width in twips: A4 (11906) minus default margins (1440 each side)
  const AVAILABLE_WIDTH = 11906 - 1440 - 1440; // 9026 twips

  // Scale column widths to fit within available page width
  let columnWidths = block.columnWidths;
  if (columnWidths) {
    const totalRequested = columnWidths.reduce((sum, w) => sum + w, 0);
    if (totalRequested > AVAILABLE_WIDTH) {
      const scale = AVAILABLE_WIDTH / totalRequested;
      columnWidths = columnWidths.map((w) => Math.round(w * scale));
    }
  }

  const rows = (block.rows || []).map((rowDef) => {
    const cells = (rowDef.cells || []).map((cellDef, colIdx) => {
      // Pass column width to each cell so it gets an explicit w:tcW
      const colWidth = columnWidths ? columnWidths[colIdx] : undefined;
      return buildTableCell(cellDef, colWidth);
    });
    const rowOpts = { children: cells };
    if (rowDef.isHeader) rowOpts.tableHeader = true;
    return new TableRow(rowOpts);
  });

  const tableOpts = {
    rows,
    borders: {
      top: defaultBorder,
      bottom: defaultBorder,
      left: defaultBorder,
      right: defaultBorder,
      insideHorizontal: defaultBorder,
      insideVertical: defaultBorder,
    },
    // Use DXA (twips) for table width to avoid pct interpretation issues
    width: { size: AVAILABLE_WIDTH, type: WidthType.DXA },
    layout: TableLayoutType.FIXED,
  };

  if (columnWidths) tableOpts.columnWidths = columnWidths;

  return new Table(tableOpts);
}

/** Build a Document from the top-level JSON schema. */
function buildDocument(json) {
  const defaultFont = json.defaultStyle?.font;
  const defaultSize = json.defaultStyle?.size;
  const children = [];
  for (const block of json.content) {
    // Inject defaults into children that don't specify their own
    if (defaultFont || defaultSize) {
      const injectDefaults = (items) => {
        if (!Array.isArray(items)) return items;
        return items.map(item => {
          if (typeof item === "string") {
            const opts = { text: item };
            if (defaultFont) opts.font = defaultFont;
            if (defaultSize) opts.size = defaultSize;
            return opts;
          }
          return {
            ...item,
            font: item.font || defaultFont,
            size: item.size || defaultSize,
          };
        });
      };
      if (block.children) block.children = injectDefaults(block.children);
      if (block.text != null && !block.children) {
        block.children = [{ type: "text", text: String(block.text), font: defaultFont, size: defaultSize }];
        delete block.text;
      }
    }
    switch (block.type) {
      case "heading":
      case "paragraph":
        children.push(buildParagraph(block));
        break;
      case "rule":
        children.push(new Paragraph({ thematicBreak: true }));
        break;
      case "table":
        children.push(buildTable(block));
        break;
      default:
        break;
    }
  }

  const docOpts = { sections: [{ children }] };
  // Apply default font as document-level style
  if (defaultFont) {
    docOpts.styles = {
      default: {
        document: {
          run: { font: { name: defaultFont } },
        },
      },
    };
  }
  if (defaultSize) {
    docOpts.styles = docOpts.styles || { default: { document: { run: {} } } };
    docOpts.styles.default.document.run.size = defaultSize;
  }

  return new Document(docOpts);
}

/** createDocument handler: read JSON from stdin, build DOCX, write to disk. */
async function createDocument(outputPath, noRefresh) {
  const jsonStr = await readStdin();
  let json;
  try {
    json = JSON.parse(jsonStr);
  } catch (e) {
    die(`Invalid JSON on stdin: ${e.message}`);
  }

  if (!json.content || !Array.isArray(json.content))
    die("JSON must have a 'content' array");

  const doc = buildDocument(json);
  const buffer = await Packer.toBuffer(doc);
  atomicWrite(outputPath, buffer);

  if (!noRefresh) await triggerRefresh(outputPath);
  console.log(JSON.stringify({ ok: true, file: outputPath, blocks: json.content.length }));
}

// ---------------------------------------------------------------------------
// getDocument — extract plain text from a DOCX
// Uses @superdoc-dev/cli `read` as primary, JSZip XML parsing as fallback.
// ---------------------------------------------------------------------------

async function extractText(filePath) {
  // Primary: use SuperDoc CLI (proper DOCX engine, handles complex formatting)
  try {
    const cliPath = join(__dirname, "node_modules", "@superdoc-dev", "cli", "dist", "index.js");
    const text = execSync(
      `"${process.execPath}" "${cliPath}" read "${filePath}"`,
      { encoding: "utf-8", timeout: 30000, stdio: ["pipe", "pipe", "pipe"],
        env: { ...process.env, ELECTRON_RUN_AS_NODE: "1" } }
    );
    if (text.trim()) return text;
  } catch {
    // SuperDoc CLI failed — fall through to JSZip
  }

  // Fallback: parse DOCX XML directly
  const zip = await loadDocx(filePath);
  const docXml = await getDocXml(zip);

  const tagRegex = /<w:t[^>]*>([\s\S]*?)<\/w:t>/g;
  const paraEndRegex = /<\/w:p>/g;
  let lastIndex = 0;
  let match;
  let result = "";

  while ((match = tagRegex.exec(docXml)) !== null) {
    const between = docXml.slice(lastIndex, match.index);
    const paraBreaks = between.match(paraEndRegex);
    if (paraBreaks && result.length > 0) {
      result += "\n".repeat(paraBreaks.length);
    }
    result += match[1];
    lastIndex = match.index + match[0].length;
  }

  // Last resort: platform-specific text extraction
  if (!result.trim()) {
    try {
      if (process.platform === "win32") {
        // Windows: use PowerShell to extract text from DOCX
        result = execSync(
          `powershell -NoProfile -Command "& { $w = New-Object -ComObject Word.Application; $w.Visible = $false; $d = $w.Documents.Open('${filePath.replace(/'/g, "''")}'); $d.Content.Text; $d.Close($false); $w.Quit() }"`,
          { encoding: "utf-8", timeout: 30000 }
        );
      } else {
        // macOS: use textutil
        result = execSync(`textutil -convert txt -stdout "${filePath}"`, {
          encoding: "utf-8",
        });
      }
    } catch {
      // Return empty — last-resort extraction unavailable
    }
  }

  return result;
}

// ---------------------------------------------------------------------------
// addComment — insert a Word comment anchored to specific text
// ---------------------------------------------------------------------------

async function addComment(filePath, findText, author, commentText, noRefresh) {
  const zip = await loadDocx(filePath);

  // --- comments.xml ---
  let commentsXml = await zip.file("word/comments.xml")?.async("string");
  let nextId = 1;

  if (!commentsXml) {
    commentsXml = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:comments xmlns:wpc="http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas"
  xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
  xmlns:o="urn:schemas-microsoft-com:office:office"
  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
  xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math"
  xmlns:v="urn:schemas-microsoft-com:vml"
  xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
  xmlns:w10="urn:schemas-microsoft-com:office:word"
  xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
  xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml">
</w:comments>`;

    // Ensure relationship exists
    let relsXml = await zip.file("word/_rels/document.xml.rels")?.async("string");
    if (relsXml && !relsXml.includes("comments.xml")) {
      const relId = `rIdComment${Date.now()}`;
      relsXml = relsXml.replace(
        "</Relationships>",
        `<Relationship Id="${relId}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/comments" Target="comments.xml"/>\n</Relationships>`
      );
      zip.file("word/_rels/document.xml.rels", relsXml);
    }

    // Ensure content type exists
    let contentTypes = await zip.file("[Content_Types].xml")?.async("string");
    if (contentTypes && !contentTypes.includes("comments.xml")) {
      contentTypes = contentTypes.replace(
        "</Types>",
        `<Override PartName="/word/comments.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.comments+xml"/>\n</Types>`
      );
      zip.file("[Content_Types].xml", contentTypes);
    }
  } else {
    // Find the highest existing comment ID
    for (const m of commentsXml.matchAll(/w:id="(\d+)"/g)) {
      const id = parseInt(m[1], 10);
      if (id >= nextId) nextId = id + 1;
    }
  }

  // --- document.xml — find text and determine a safe ID ---
  let docXml = await getDocXml(zip);

  // Scan document.xml for ALL w:id values (bookmarks, comments, etc.) to avoid collisions
  for (const m of docXml.matchAll(/w:id="(\d+)"/g)) {
    const id = parseInt(m[1], 10);
    if (id >= nextId) nextId = id + 1;
  }

  const commentId = nextId;
  const now = new Date().toISOString();

  // Generate a random paraId (8-char hex) for w14:paraId
  const paraId = Math.random().toString(16).slice(2, 10).toUpperCase().padStart(8, '0');
  // Generate a unique internalId for SuperDoc tracking
  const internalId = `imported-${crypto.randomUUID().slice(0, 8)}`;

  const commentEntry = `<w:comment w:id="${commentId}" w:author="${escXml(author)}" w:date="${now}" w:initials="DV" custom:internalId="${internalId}" custom:trackedChange="false" custom:trackedChangeText="null" custom:trackedChangeType="null" custom:trackedDeletedText="null" xmlns:custom="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:p w14:paraId="${paraId}"><w:r><w:rPr><w:rStyle w:val="CommentReference" /></w:rPr><w:annotationRef /></w:r><w:r><w:t>${escXml(commentText)}</w:t></w:r></w:p></w:comment>`;

  // Handle both closing tag and self-closing tag forms
  if (commentsXml.includes("</w:comments>")) {
    commentsXml = commentsXml.replace(
      "</w:comments>",
      `${commentEntry}\n</w:comments>`
    );
  } else {
    // Self-closing: <w:comments ... /> → <w:comments ...>entry</w:comments>
    commentsXml = commentsXml.replace(/\s*\/>$/, `>${commentEntry}\n</w:comments>`);
  }
  zip.file("word/comments.xml", commentsXml);

  // --- document.xml — wrap target text with comment range markers ---
  const escaped = escXml(findText);
  const textIdx = docXml.indexOf(escaped);
  if (textIdx === -1) {
    die(`Text not found in document: "${findText.slice(0, 80)}"`);
  }

  // Comment markers must be placed OUTSIDE <w:r> run elements, not inside <w:t>.
  // Find the enclosing <w:r> that contains this text.
  const before = docXml.slice(0, textIdx);
  const runStartA = before.lastIndexOf("<w:r>");
  const runStartB = before.lastIndexOf("<w:r ");
  const runStart = Math.max(runStartA, runStartB);

  const afterText = textIdx + escaped.length;
  const runEndTag = docXml.indexOf("</w:r>", afterText);
  const runEndComplete = runEndTag + "</w:r>".length;

  // Extract the <w:rPr>...</w:rPr> from the text's run so the commentReference
  // run carries the same formatting — SuperDoc requires this to display the comment.
  const runXml = docXml.slice(runStart, runEndComplete);
  const rPrMatch = runXml.match(/<w:rPr>[\s\S]*?<\/w:rPr>/);
  const rPr = rPrMatch ? rPrMatch[0] : "<w:rPr />";

  const rangeStart = `<w:commentRangeStart w:id="${commentId}" />`;
  const rangeEnd = `<w:commentRangeEnd w:id="${commentId}" />`;
  const ref = `<w:r>${rPr}<w:commentReference w:id="${commentId}" /></w:r>`;

  docXml =
    docXml.slice(0, runStart) +
    rangeStart +
    docXml.slice(runStart, runEndComplete) +
    rangeEnd +
    ref +
    docXml.slice(runEndComplete);

  zip.file("word/document.xml", docXml);
  await saveDocx(zip, filePath);
  if (!noRefresh) await triggerRefresh(filePath);
  console.log(JSON.stringify({ ok: true, commentId, find: findText, author }));
}

// ---------------------------------------------------------------------------
// addHighlight — apply a colored highlight to text
// ---------------------------------------------------------------------------

async function addHighlight(filePath, findText, color, noRefresh) {
  const zip = await loadDocx(filePath);
  let docXml = await getDocXml(zip);

  // Map hex color to Word highlight color name
  const colorMap = {
    "#FFE0E0": "red",
    "#ffe0e0": "red",
    "#FFF3CD": "yellow",
    "#fff3cd": "yellow",
    "#E2E3E5": "lightGray",
    "#e2e3e5": "lightGray",
    "#FFFF00": "yellow",
  };
  const wColor = colorMap[color] || "yellow";

  const escaped = escXml(findText);
  const textIdx = docXml.indexOf(escaped);
  if (textIdx === -1) {
    die(`Text not found in document: "${findText.slice(0, 80)}"`);
  }

  const before = docXml.slice(0, textIdx);
  const highlightTag = `<w:highlight w:val="${wColor}"/>`;

  // Try to find the nearest <w:rPr> before this text and inject highlight
  const rPrIdx = before.lastIndexOf("<w:rPr");
  if (rPrIdx !== -1) {
    const rPrEnd = docXml.indexOf("</w:rPr>", rPrIdx);
    if (rPrEnd !== -1 && !docXml.slice(rPrIdx, rPrEnd).includes("<w:highlight")) {
      docXml =
        docXml.slice(0, rPrEnd) + highlightTag + docXml.slice(rPrEnd);
    }
  } else {
    // No rPr exists — inject one before the <w:t> tag
    const wrIdx = before.lastIndexOf("<w:r>");
    if (wrIdx !== -1) {
      const rPrBlock = `<w:rPr>${highlightTag}</w:rPr>`;
      docXml =
        docXml.slice(0, wrIdx + 5) + rPrBlock + docXml.slice(wrIdx + 5);
    }
  }

  zip.file("word/document.xml", docXml);
  await saveDocx(zip, filePath);
  if (!noRefresh) await triggerRefresh(filePath);
  console.log(JSON.stringify({ ok: true, find: findText, color }));
}

// ---------------------------------------------------------------------------
// suggestEdit — insert tracked change (w:del + w:ins) revision markup
// ---------------------------------------------------------------------------

async function suggestEdit(filePath, findText, replaceText, author, noRefresh) {
  const zip = await loadDocx(filePath);
  let docXml = await getDocXml(zip);

  const now = new Date().toISOString();
  const revId = Date.now() % 2147483647; // keep within 32-bit int for Word

  const escaped = escXml(findText);
  const textIdx = docXml.indexOf(escaped);
  if (textIdx === -1) {
    die(`Text not found in document: "${findText.slice(0, 80)}"`);
  }

  // Extract formatting from the run containing the matched text
  const rPr = extractRPr(docXml, textIdx);

  const delRun = `<w:del w:id="${revId}" w:author="${escXml(author)}" w:date="${now}"><w:r>${rPr}<w:delText xml:space="preserve">${escaped}</w:delText></w:r></w:del>`;
  const insRun = `<w:ins w:id="${revId + 1}" w:author="${escXml(author)}" w:date="${now}"><w:r>${rPr}<w:t xml:space="preserve">${escXml(replaceText)}</w:t></w:r></w:ins>`;

  // Replace the matched text with del+ins tracked change markup.
  // We need to split the existing <w:t> run around the match.
  docXml =
    docXml.slice(0, textIdx) +
    `</w:t></w:r>${delRun}${insRun}<w:r><w:t xml:space="preserve">` +
    docXml.slice(textIdx + escaped.length);

  zip.file("word/document.xml", docXml);
  await saveDocx(zip, filePath);
  if (!noRefresh) await triggerRefresh(filePath);
  console.log(
    JSON.stringify({ ok: true, find: findText, replace: replaceText, author })
  );
}

// ---------------------------------------------------------------------------
// addLink — insert a clickable URL in parentheses after the target text
// ---------------------------------------------------------------------------

async function addLink(filePath, findText, url, noRefresh) {
  const zip = await loadDocx(filePath);
  let docXml = await getDocXml(zip);

  const escaped = escXml(findText);
  const textIdx = docXml.indexOf(escaped);
  if (textIdx === -1) {
    die(`Text not found in document: "${findText.slice(0, 80)}"`);
  }

  // Add a relationship for the hyperlink URL
  let relsXml = await zip.file("word/_rels/document.xml.rels")?.async("string");
  const relId = `rIdLink${Date.now()}`;
  if (relsXml) {
    relsXml = relsXml.replace(
      "</Relationships>",
      `<Relationship Id="${relId}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink" Target="${escXml(url)}" TargetMode="External"/>\n</Relationships>`
    );
    zip.file("word/_rels/document.xml.rels", relsXml);
  }

  // Find the end of the <w:r> run that contains this text
  const afterText = textIdx + escaped.length;
  const runEndTag = docXml.indexOf("</w:r>", afterText);
  const runEndComplete = runEndTag + "</w:r>".length;

  // Extract surrounding formatting, stripping link-specific props we'll override
  const baseRPr = extractRPr(docXml, textIdx, ["color", "u", "rStyle"]);
  const linkAdditions = `<w:rStyle w:val="Hyperlink"/><w:color w:val="0563C1"/><w:u w:val="single"/>`;
  const linkRPr = mergeRPr(baseRPr, linkAdditions) || `<w:rPr>${linkAdditions}</w:rPr>`;

  // Insert " (url)" as a clickable hyperlink run right after the existing run
  const linkRun = `<w:hyperlink r:id="${relId}" w:history="1"><w:r>${linkRPr}<w:t xml:space="preserve"> (${escXml(url)})</w:t></w:r></w:hyperlink>`;

  docXml =
    docXml.slice(0, runEndComplete) +
    linkRun +
    docXml.slice(runEndComplete);

  zip.file("word/document.xml", docXml);
  await saveDocx(zip, filePath);
  if (!noRefresh) await triggerRefresh(filePath);
  console.log(JSON.stringify({ ok: true, find: findText, href: url }));
}

// ---------------------------------------------------------------------------
// insertText — add text at the start or end of the document
// ---------------------------------------------------------------------------

async function insertText(filePath, position, text, noRefresh) {
  const zip = await loadDocx(filePath);
  let docXml = await getDocXml(zip);

  // Extract formatting from the nearest paragraph in the document
  let rPr = "";
  if (position === "start") {
    // Get rPr from the first <w:r> in the body
    const bodyMatch = docXml.match(/<w:body[^>]*>/);
    if (bodyMatch) {
      const bodyStart = bodyMatch.index + bodyMatch[0].length;
      rPr = extractRPr(docXml, bodyStart + 1);
    }
  } else {
    // Get rPr from the last <w:r> before </w:body>
    const bodyEnd = docXml.indexOf("</w:body>");
    if (bodyEnd !== -1) {
      rPr = extractRPr(docXml, bodyEnd);
    }
  }

  // Build paragraph XML from the input text (split on double newlines)
  const paragraphs = text.split(/\n{2,}/);
  let newContent = "";
  for (const para of paragraphs) {
    const lines = para.split("\n");
    let runs = "";
    for (const line of lines) {
      runs += `<w:r>${rPr}<w:t xml:space="preserve">${escXml(line)}</w:t></w:r>`;
    }
    newContent += `<w:p>${runs}</w:p>`;
  }

  if (position === "start") {
    const bodyMatch = docXml.match(/<w:body[^>]*>/);
    if (bodyMatch) {
      const idx = bodyMatch.index + bodyMatch[0].length;
      docXml = docXml.slice(0, idx) + newContent + docXml.slice(idx);
    }
  } else {
    // Default: end — insert before </w:body>
    docXml = docXml.replace("</w:body>", `${newContent}</w:body>`);
  }

  zip.file("word/document.xml", docXml);
  await saveDocx(zip, filePath);
  if (!noRefresh) await triggerRefresh(filePath);
  console.log(JSON.stringify({ ok: true, position, textLength: text.length }));
}

// ---------------------------------------------------------------------------
// Command dispatch
// ---------------------------------------------------------------------------

const args = minimist(process.argv.slice(2));
const command = args._[0];

if (!command) {
  console.error(`Usage: superdoc-bridge.js <command> [options]

Commands:
  getDocument      --file <path> [--format text|json]
  addComment       --file <path> --find "<text>" [--author "<name>"] --text "<annotation>"
  addHighlight     --file <path> --find "<text>" [--color "#FFE0E0"]
  suggestEdit      --file <path> --find "<old>" --replace "<new>" [--author "<name>"]
  insertText       --file <path> --at end|start --text "<content>"
  addLink          --file <path> --find "<text>" --url "<href>"
  createDocument   --file <path>   (reads JSON content schema from stdin)
  refresh          --file <path>

Global options:
  --no-refresh   Suppress the 200ms auto-refresh after mutation commands`);
  process.exit(1);
}

async function main() {
  const noRefresh = !!args["no-refresh"];

  // createDocument: output file doesn't exist yet, so skip resolveFile
  if (command === "createDocument") {
    if (!args.file) die("--file is required");
    const outputPath = resolve(args.file);
    await createDocument(outputPath, noRefresh);
    return;
  }

  const filePath = args.file ? resolveFile(args.file) : null;

  switch (command) {
    case "getDocument": {
      if (!filePath) die("--file is required");
      const text = await extractText(filePath);
      if ((args.format || "text") === "json") {
        console.log(JSON.stringify({ text, charCount: text.length }));
      } else {
        process.stdout.write(text);
      }
      break;
    }
    case "addComment":
      if (!filePath) die("--file is required");
      await addComment(
        filePath,
        requireArg(args, "find"),
        args.author || "Document Verifier",
        requireArg(args, "text"),
        noRefresh
      );
      break;
    case "addHighlight":
      if (!filePath) die("--file is required");
      await addHighlight(
        filePath,
        requireArg(args, "find"),
        args.color || "#FFF3CD",
        noRefresh
      );
      break;
    case "suggestEdit":
      if (!filePath) die("--file is required");
      await suggestEdit(
        filePath,
        requireArg(args, "find"),
        requireArg(args, "replace"),
        args.author || "Document Verifier",
        noRefresh
      );
      break;
    case "insertText":
      if (!filePath) die("--file is required");
      await insertText(filePath, args.at || "end", requireArg(args, "text"), noRefresh);
      break;
    case "addLink":
      if (!filePath) die("--file is required");
      await addLink(
        filePath,
        requireArg(args, "find"),
        requireArg(args, "url"),
        noRefresh
      );
      break;
    case "refresh":
      if (!filePath) die("--file is required");
      await triggerRefresh(filePath);
      console.log(JSON.stringify({ ok: true, refreshed: filePath }));
      break;
    default:
      die(
        `Unknown command: ${command}. Valid: getDocument, addComment, addHighlight, suggestEdit, insertText, addLink, createDocument, refresh`
      );
  }
}

main().catch((err) => {
  console.error(`Error: ${err.message}`);
  process.exit(1);
});
