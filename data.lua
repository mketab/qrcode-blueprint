data:extend({
  {
    type = "shortcut",
    name = "qr-code-shortcut",
    action = "lua",
    icon = "__qrcode-blueprint__/graphics/icons/qr-code-shortcut.png",
    icon_size = 64,
    small_icon = "__qrcode-blueprint__/graphics/icons/qr-code-shortcut.png",
    small_icon_size = 64,
  },
  {
    type = "custom-input",
    name = "qr-code-hotkey",
    key_sequence = "CONTROL + ALT + Q",
    consuming = "none"
  }
})
