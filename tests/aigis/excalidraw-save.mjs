import assert from 'node:assert/strict';
import fs from 'node:fs';

const appDir = process.env.EXCALIDRAW_APP_DIR || '/app';
const { default: WebSocket } = await import(`${appDir}/node_modules/ws/index.js`);
const base = process.env.EXCALIDRAW_TEST_URL || 'http://127.0.0.1:3000';
const dataDir = process.env.HOST_HOME_PATH || '/data';
const filename = `${dataDir}/aigis-vm-roundtrip`;
const scene = {
  type: 'excalidraw',
  version: 2,
  source: 'aigis-vm-protocol-fixture',
  elements: [{ id: 'roundtrip', type: 'rectangle', x: 10, y: 20, width: 100, height: 80 }],
  appState: { viewBackgroundColor: '#ffffff' },
  files: {},
};

if (process.env.EXCALIDRAW_TEST_VERIFY_ONLY === '1') {
  assert.deepEqual(JSON.parse(fs.readFileSync(`${filename}.excalidraw`, 'utf8')), scene);
  console.log('Explicitly saved Excalidraw file is intact');
  process.exit(0);
}

let session;
let requestId = 0;
async function rpc(method, params, notification = false) {
  const body = { jsonrpc: '2.0', method, params };
  if (!notification) body.id = ++requestId;
  const response = await fetch(`${base}/mcp`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json, text/event-stream',
      ...(session ? { 'Mcp-Session-Id': session } : {}),
    },
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(15000),
  });
  assert(response.ok, `${method}: HTTP ${response.status}`);
  session = response.headers.get('mcp-session-id') || session;
  if (notification) return;
  const text = await response.text();
  const messages = response.headers.get('content-type')?.includes('text/event-stream')
    ? text.split('\n').filter(line => line.startsWith('data:')).map(line => JSON.parse(line.slice(5)))
    : [JSON.parse(text)];
  const result = messages.find(message => message.id === body.id);
  assert(result && !result.error, JSON.stringify(messages));
  return result.result;
}

let imported;
let cleared = false;
const socket = new WebSocket(base.replace(/^http/, 'ws'));
socket.on('message', raw => {
  const message = JSON.parse(raw.toString());
  if (!message.requestId) return;
  let data = {};
  if (message.type === 'save_canvas_request') data = { excalidraw: JSON.stringify(scene) };
  else if (message.type === 'mcp_clear_canvas') cleared = true;
  else if (message.type === 'mcp_batch_create') imported = message.elements;
  else throw new Error(`Unexpected canvas operation: ${message.type}`);
  socket.send(JSON.stringify({
    type: 'mcp_operation_response', requestId: message.requestId, success: true, data,
  }));
});

try {
  await new Promise((resolve, reject) => {
    const timeout = setTimeout(() => reject(new Error('Canvas pin timed out')), 10000);
    socket.on('error', reject);
    socket.on('open', () => socket.send(JSON.stringify({ type: 'client_pin', pinned: true })));
    socket.on('message', raw => {
      const message = JSON.parse(raw.toString());
      if (message.type === 'pin_status' && message.isPinned) {
        clearTimeout(timeout);
        resolve();
      }
    });
  });
  await rpc('initialize', {
    protocolVersion: '2025-03-26', capabilities: {}, clientInfo: { name: 'aigis-vm', version: '1' },
  });
  await rpc('notifications/initialized', {}, true);
  const { tools } = await rpc('tools/list', {});
  for (const name of ['create_element', 'save_canvas', 'import_scene']) {
    assert(tools.some(tool => tool.name === name), `Missing MCP tool: ${name}`);
  }
  const saved = await rpc('tools/call', {
    name: 'save_canvas', arguments: { filename_without_extension: filename, format: 'excalidraw' },
  });
  assert(!saved.isError, JSON.stringify(saved));
  assert.deepEqual(JSON.parse(fs.readFileSync(`${filename}.excalidraw`, 'utf8')), scene);
  const restored = await rpc('tools/call', {
    name: 'import_scene', arguments: { filePath: `${filename}.excalidraw`, mode: 'replace' },
  });
  assert(!restored.isError, JSON.stringify(restored));
  assert(cleared, 'Replace import did not clear the canvas');
  assert.deepEqual(imported, scene.elements);
  const denied = await rpc('tools/call', {
    name: 'save_canvas', arguments: { filename_without_extension: '/etc/forbidden', format: 'excalidraw' },
  });
  assert(denied.isError, 'save_canvas accepted an unmapped absolute path');
  console.log('MCP save/import roundtrip passed against a WebSocket canvas protocol fixture');
} finally {
  socket.close();
}
