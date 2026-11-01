# Excalidraw on Aigis

`excalidraw.laufin.xyz` serves the unmodified `frankhommers/mcp-excalidraw-live` container. The pinned published image contains version 2.0.0 (upstream revision `b46921de811d0121239371eb0fcdeff38e830cd1`), not the v3 grant model described by the current upstream README. In this image, use the canvas header's pin control to choose the browser tab edited by MCP; the first tab is auto-pinned after server startup.

## Access

The UI, WebSocket and Streamable HTTP MCP endpoint share the same origin. The MCP URL is `https://excalidraw.laufin.xyz/mcp`. Configure a client only after deploying this PR; this change does not modify Hermes configuration.

The application has no login. Caddy allows only `192.168.0.0/16` and the host's loopback addresses; the container port is bound to `127.0.0.1:3010` and is not opened in the firewall. Do not forward this route through a trusted LAN proxy to the public internet: the source-address restriction is not user authentication.

## Saving

There is **no server-side autosave or automatic restore**. The open canvas remains browser-local. No application patches or custom image builds are included.

The existing MCP `save_canvas` tool can explicitly save the open canvas using `filename_without_extension: "/data/my-diagram"` and `format: "excalidraw"` (also supports PNG/SVG). The file appears at `/var/lib/containers/excalidraw/my-diagram.excalidraw` on Aigis and survives container recreation. Only this directory is mounted, not the host home directory.

To reopen a saved diagram, use the existing `import_scene` tool with `filePath: "/data/my-diagram.excalidraw"`; choose `mode: "replace"` to replace, or `"merge"` to append. The upstream importer sends scene elements to the browser; importing external files is not a guarantee of restoring every embedded-image or app-state field. Browser export/open remains available for native `.excalidraw` files.

The existing Restic backup includes `/var/lib/containers`, so it covers these explicitly saved files, not unsaved browser state.
