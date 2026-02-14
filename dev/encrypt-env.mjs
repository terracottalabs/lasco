#!/usr/bin/env node
/**
 * Build-time encryption of PaddleOCR credentials.
 *
 * Usage: node dev/encrypt-env.mjs <env-path> <output-path>
 *
 * Reads PADDLEOCR_JOB_URL, PADDLEOCR_TOKEN, PADDLEOCR_MODEL from the .env
 * file, encrypts them with AES-256-GCM (PBKDF2-derived key), and writes the
 * ciphertext JSON to <output-path>.
 *
 * The passphrase is split across 3 constants and MUST match the values in
 * credentials.js at runtime.
 */

import { readFileSync, writeFileSync, mkdirSync } from 'fs';
import { dirname } from 'path';
import { randomBytes, pbkdf2Sync, createCipheriv } from 'crypto';

// ── Passphrase (split across 3 parts — keep in sync with credentials.js) ──
const P1 = '***REDACTED***';
const P2 = '***REDACTED***';
const P3 = '***REDACTED***';
const PASSPHRASE = P1 + P2 + P3;

// ── Parse CLI ──────────────────────────────────────────────────────────────
const [envPath, outputPath] = process.argv.slice(2);
if (!envPath || !outputPath) {
  console.error('Usage: node dev/encrypt-env.mjs <env-path> <output-path>');
  process.exit(1);
}

// ── Read .env ──────────────────────────────────────────────────────────────
function parseEnv(filePath) {
  const vars = {};
  const lines = readFileSync(filePath, 'utf-8').split('\n');
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const eqIdx = trimmed.indexOf('=');
    if (eqIdx === -1) continue;
    const key = trimmed.slice(0, eqIdx).trim();
    let val = trimmed.slice(eqIdx + 1).trim();
    // Strip surrounding quotes
    if ((val.startsWith('"') && val.endsWith('"')) ||
        (val.startsWith("'") && val.endsWith("'"))) {
      val = val.slice(1, -1);
    }
    vars[key] = val;
  }
  return vars;
}

const env = parseEnv(envPath);

const payload = {
  jobUrl: env.PADDLEOCR_JOB_URL || '',
  token: env.PADDLEOCR_TOKEN || '',
  model: env.PADDLEOCR_MODEL || '',
};

if (!payload.jobUrl || !payload.token || !payload.model) {
  console.error('WARNING: One or more PaddleOCR env vars are empty.');
  console.error('  PADDLEOCR_JOB_URL=' + (payload.jobUrl ? '(set)' : '(empty)'));
  console.error('  PADDLEOCR_TOKEN=' + (payload.token ? '(set)' : '(empty)'));
  console.error('  PADDLEOCR_MODEL=' + (payload.model ? '(set)' : '(empty)'));
}

// ── Encrypt ────────────────────────────────────────────────────────────────
const salt = randomBytes(32);
const iv = randomBytes(16);
const key = pbkdf2Sync(PASSPHRASE, salt, 100_000, 32, 'sha512');
const cipher = createCipheriv('aes-256-gcm', key, iv);

const plaintext = JSON.stringify(payload);
const encrypted = Buffer.concat([cipher.update(plaintext, 'utf-8'), cipher.final()]);
const authTag = cipher.getAuthTag();

const output = {
  v: 1,
  salt: salt.toString('hex'),
  iv: iv.toString('hex'),
  authTag: authTag.toString('hex'),
  data: encrypted.toString('hex'),
};

// ── Write ──────────────────────────────────────────────────────────────────
mkdirSync(dirname(outputPath), { recursive: true });
writeFileSync(outputPath, JSON.stringify(output), 'utf-8');
console.log(`Encrypted credentials written to ${outputPath}`);
