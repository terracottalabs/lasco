#!/usr/bin/env node
/**
 * Browser Viewer Proxy Server
 *
 * Serves an HTML viewer and proxies WebSocket connections to agent-browser's
 * stream server. This bypasses the origin check since server-to-server
 * connections don't have an origin header.
 *
 * Usage:
 *   scripts/lasco-node scripts/browser-viewer-server.js [--port 3456] [--stream-port 9223]
 *
 * Then open http://localhost:3456 in Cursor's Simple Browser
 */

import { createServer } from 'http';
import { WebSocketServer, WebSocket } from 'ws';
import { parse } from 'url';

const args = process.argv.slice(2);
const getArg = (name, defaultValue) => {
  const idx = args.indexOf(name);
  return idx !== -1 && args[idx + 1] ? args[idx + 1] : defaultValue;
};

const HTTP_PORT = parseInt(getArg('--port', '3456'));
const STREAM_PORT = parseInt(getArg('--stream-port', '9223'));

// HTML content (embedded for simplicity)
const HTML = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Agent Browser Viewer</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: #1e1e1e;
      color: #fff;
      height: 100vh;
      display: flex;
      flex-direction: column;
      overflow: hidden;
    }
    .header {
      background: #2d2d2d;
      padding: 8px 16px;
      display: flex;
      align-items: center;
      gap: 12px;
      border-bottom: 1px solid #3d3d3d;
      flex-shrink: 0;
    }
    .status {
      display: flex;
      align-items: center;
      gap: 6px;
      font-size: 13px;
    }
    .status-dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: #ff5f56;
    }
    .status-dot.connected { background: #27c93f; }
    .status-dot.connecting { background: #ffbd2e; animation: pulse 1s infinite; }
    @keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.5; } }
    .viewport-info {
      margin-left: auto;
      font-size: 12px;
      color: #888;
    }
    .canvas-container {
      flex: 1;
      display: flex;
      align-items: center;
      justify-content: center;
      background: #0d0d0d;
      overflow: hidden;
      position: relative;
    }
    #viewport {
      max-width: 100%;
      max-height: 100%;
      cursor: crosshair;
    }
    .placeholder {
      text-align: center;
      color: #666;
    }
    .placeholder h2 { font-size: 18px; margin-bottom: 12px; }
    .placeholder p { font-size: 13px; margin-bottom: 8px; }
    .placeholder code {
      background: #2d2d2d;
      padding: 2px 6px;
      border-radius: 3px;
      font-family: 'SF Mono', Monaco, monospace;
      font-size: 12px;
    }
    .fps-counter {
      position: absolute;
      top: 8px;
      right: 8px;
      background: rgba(0,0,0,0.7);
      padding: 4px 8px;
      border-radius: 4px;
      font-size: 11px;
      font-family: monospace;
    }
    .error-banner {
      background: #5a1d1d;
      color: #ff6b6b;
      padding: 8px 16px;
      font-size: 13px;
      display: none;
    }
    .error-banner.visible { display: block; }
  </style>
</head>
<body>
  <div class="header">
    <div class="status">
      <div class="status-dot connecting" id="statusDot"></div>
      <span id="statusText">Connecting...</span>
    </div>
    <span class="viewport-info" id="viewportInfo"></span>
  </div>
  <div class="error-banner" id="errorBanner"></div>
  <div class="canvas-container">
    <div class="placeholder" id="placeholder">
      <h2>Waiting for browser...</h2>
      <p>Make sure agent-browser is running with streaming:</p>
      <p><code>AGENT_BROWSER_STREAM_PORT=${STREAM_PORT} agent-browser open example.com</code></p>
    </div>
    <canvas id="viewport" style="display: none;"></canvas>
    <div class="fps-counter" id="fpsCounter" style="display: none;">0 FPS</div>
  </div>
  <script>
    const statusDot = document.getElementById('statusDot');
    const statusText = document.getElementById('statusText');
    const viewportInfo = document.getElementById('viewportInfo');
    const errorBanner = document.getElementById('errorBanner');
    const placeholder = document.getElementById('placeholder');
    const canvas = document.getElementById('viewport');
    const fpsCounter = document.getElementById('fpsCounter');
    const ctx = canvas.getContext('2d');

    let ws = null;
    let frameCount = 0;
    let lastFpsTime = Date.now();

    setInterval(() => {
      const now = Date.now();
      const fps = Math.round(frameCount / ((now - lastFpsTime) / 1000));
      fpsCounter.textContent = fps + ' FPS';
      frameCount = 0;
      lastFpsTime = now;
    }, 1000);

    function connect() {
      const protocol = location.protocol === 'https:' ? 'wss:' : 'ws:';
      ws = new WebSocket(protocol + '//' + location.host + '/ws');

      ws.onopen = () => {
        statusDot.className = 'status-dot connected';
        statusText.textContent = 'Connected';
        placeholder.style.display = 'none';
        canvas.style.display = 'block';
        fpsCounter.style.display = 'block';
      };

      ws.onmessage = (event) => {
        let msg;
        try {
          msg = JSON.parse(event.data);
        } catch (e) {
          console.error('[Viewer] Invalid JSON:', e.message);
          return;
        }
        if (msg.type === 'frame') {
          const img = new Image();
          img.onload = () => {
            if (canvas.width !== img.width || canvas.height !== img.height) {
              canvas.width = img.width;
              canvas.height = img.height;
              viewportInfo.textContent = img.width + '×' + img.height;
            }
            ctx.drawImage(img, 0, 0);
            frameCount++;
          };
          img.src = 'data:image/jpeg;base64,' + msg.data;
        } else if (msg.type === 'status' && msg.viewportWidth) {
          viewportInfo.textContent = msg.viewportWidth + '×' + msg.viewportHeight;
        } else if (msg.type === 'error') {
          errorBanner.textContent = msg.message;
          errorBanner.classList.add('visible');
        } else if (msg.type === 'upstream_disconnected') {
          statusDot.className = 'status-dot connecting';
          statusText.textContent = 'Waiting for browser...';
          placeholder.style.display = 'block';
          canvas.style.display = 'none';
        }
      };

      ws.onclose = () => {
        statusDot.className = 'status-dot';
        statusText.textContent = 'Disconnected';
        setTimeout(connect, 2000);
      };

      ws.onerror = () => {
        ws.close();
      };
    }

    function getCoords(e) {
      const rect = canvas.getBoundingClientRect();
      return {
        x: Math.round((e.clientX - rect.left) * canvas.width / rect.width),
        y: Math.round((e.clientY - rect.top) * canvas.height / rect.height)
      };
    }

    function getMods(e) {
      return (e.altKey ? 1 : 0) | (e.ctrlKey ? 2 : 0) | (e.metaKey ? 4 : 0) | (e.shiftKey ? 8 : 0);
    }

    canvas.onmousedown = (e) => {
      if (!ws || ws.readyState !== 1) return;
      const c = getCoords(e);
      ws.send(JSON.stringify({ type: 'input_mouse', eventType: 'mousePressed', x: c.x, y: c.y, button: ['left','middle','right'][e.button], clickCount: 1, modifiers: getMods(e) }));
    };

    canvas.onmouseup = (e) => {
      if (!ws || ws.readyState !== 1) return;
      const c = getCoords(e);
      ws.send(JSON.stringify({ type: 'input_mouse', eventType: 'mouseReleased', x: c.x, y: c.y, button: ['left','middle','right'][e.button], clickCount: 1, modifiers: getMods(e) }));
    };

    canvas.onmousemove = (e) => {
      if (!ws || ws.readyState !== 1) return;
      const c = getCoords(e);
      ws.send(JSON.stringify({ type: 'input_mouse', eventType: 'mouseMoved', x: c.x, y: c.y, modifiers: getMods(e) }));
    };

    canvas.onwheel = (e) => {
      if (!ws || ws.readyState !== 1) return;
      e.preventDefault();
      const c = getCoords(e);
      ws.send(JSON.stringify({ type: 'input_mouse', eventType: 'mouseWheel', x: c.x, y: c.y, deltaX: e.deltaX, deltaY: e.deltaY, modifiers: getMods(e) }));
    };

    canvas.oncontextmenu = (e) => e.preventDefault();

    document.onkeydown = (e) => {
      if (!ws || ws.readyState !== 1) return;
      e.preventDefault();
      ws.send(JSON.stringify({ type: 'input_keyboard', eventType: 'keyDown', key: e.key, code: e.code, text: e.key.length === 1 ? e.key : '', modifiers: getMods(e) }));
    };

    document.onkeyup = (e) => {
      if (!ws || ws.readyState !== 1) return;
      e.preventDefault();
      ws.send(JSON.stringify({ type: 'input_keyboard', eventType: 'keyUp', key: e.key, code: e.code, modifiers: getMods(e) }));
    };

    connect();
  </script>
</body>
</html>`;

// Proxy connections to track
const clients = new Set();
let upstreamConnected = false;

// Create HTTP server
const server = createServer((req, res) => {
  const { pathname } = parse(req.url);

  if (pathname === '/' || pathname === '/index.html') {
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end(HTML);
  } else {
    res.writeHead(404);
    res.end('Not found');
  }
});

// Create WebSocket server for browser clients
const wss = new WebSocketServer({ server, path: '/ws' });

// Connect to upstream agent-browser stream
let upstream = null;
let reconnectTimer = null;

function connectUpstream() {
  if (upstream && upstream.readyState === WebSocket.OPEN) return;

  upstream = new WebSocket(`ws://localhost:${STREAM_PORT}`);

  upstream.on('open', () => {
    console.log(`[Proxy] Connected to agent-browser on port ${STREAM_PORT}`);
    upstreamConnected = true;
  });

  upstream.on('message', (data) => {
    // Broadcast to all connected browser clients
    const message = data.toString();
    for (const client of clients) {
      if (client.readyState === WebSocket.OPEN) {
        client.send(message);
      }
    }
  });

  upstream.on('close', () => {
    console.log('[Proxy] Disconnected from agent-browser, retrying in 2s...');
    upstreamConnected = false;
    // Notify clients
    for (const client of clients) {
      if (client.readyState === WebSocket.OPEN) {
        client.send(JSON.stringify({ type: 'upstream_disconnected' }));
      }
    }
    // Reconnect after delay
    reconnectTimer = setTimeout(connectUpstream, 2000);
  });

  upstream.on('error', (err) => {
    if (err.code === 'ECONNREFUSED') {
      console.error('[Proxy] ⚠️  Port 9223 not available - ensure agent-browser was started with AGENT_BROWSER_STREAM_PORT=9223');
      console.error('[Proxy] 💡 Try: agent-browser close && AGENT_BROWSER_STREAM_PORT=9223 agent-browser open <url>');
    } else {
      console.error('[Proxy] Upstream error:', err.message);
    }
  });
}

// Handle browser client connections
wss.on('connection', (ws) => {
  console.log('[Proxy] Browser client connected');
  clients.add(ws);

  // Ensure upstream is connected
  connectUpstream();

  // Forward messages from browser to upstream
  ws.on('message', (data) => {
    if (upstream && upstream.readyState === WebSocket.OPEN) {
      upstream.send(data);
    }
  });

  ws.on('close', () => {
    console.log('[Proxy] Browser client disconnected');
    clients.delete(ws);
  });
});

// Start server
server.listen(HTTP_PORT, () => {
  console.log(`
┌─────────────────────────────────────────────────────────────┐
│  Agent Browser Viewer Proxy                                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Viewer URL:     http://localhost:${HTTP_PORT.toString().padEnd(25)}│
│  Stream port:    ${STREAM_PORT.toString().padEnd(40)}│
│                                                             │
│  Open the viewer URL in Cursor's Simple Browser pane        │
│  (Cmd+Shift+P → "Simple Browser: Show")                     │
│                                                             │
│  Make sure agent-browser is running with:                   │
│  AGENT_BROWSER_STREAM_PORT=${STREAM_PORT} agent-browser open <url>       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
`);

  // Start trying to connect to upstream
  connectUpstream();
});

// Cleanup on exit
process.on('SIGINT', () => {
  console.log('\nShutting down...');
  if (reconnectTimer) clearTimeout(reconnectTimer);
  if (upstream) upstream.close();
  for (const client of clients) client.close();
  wss.close();
  server.close();
  process.exit(0);
});
