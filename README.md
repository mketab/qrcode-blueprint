# qrcode-blueprint

A Factorio mod to create QR codes blueprints. 

Useful for sharing links or other data directly on the map.

Tested to work with arbitrarily large inputs.

## How to use

1. Click the QR code shortcut button in your shortcut bar.
2. Type your text.
3. Click "Generate".
4. Place the blueprint.
5. Scan via the map view. *Some* QR code scanners can scan the tiles themselves, but the map view is much clearer

## Config

By default, it uses `stone-wall`. If you want to use something else, change `qr-pixel-entity` in the mod settings to the name of your choice.

## Attribution

* `qrencode.lua` - Pure Lua QR encoder from https://github.com/speedata/luaqrcode
