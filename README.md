# qrcode-blueprint

_Mod Portal Link_: https://mods.factorio.com/mod/qrcode-blueprint

A Factorio mod to create and scan QR code blueprints. 

Useful for sharing links, coordination info, or other data directly on the map.

## How to use

### Generating QR codes
1. Click the QR code shortcut button in your shortcut bar, or press `Ctrl + Alt + Q`.
2. Type your text.
3. Choose your foreground and background items (must be the same size).
4. (Optional) Choose a pixel scale (e.g. 2x2).
5. Click Generate and place the blueprint.
6. Scan via map view using a real-world phone scanner. *Some* QR code scanners can scan the tiles themselves, but the map view is much clearer.

### Scanning in-game
1. Click Scan Map in the GUI to get the QR Code Decoder selection tool.
2. Drag the selection box over any physical QR code (remote view is not supported atm).
3. The decoded text will display in a popup.

## Attribution

* `qrencode.lua` - Pure Lua QR encoder from https://github.com/speedata/luaqrcode
