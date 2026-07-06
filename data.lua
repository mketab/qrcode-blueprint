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
  },
  {
    type = "selection-tool",
    name = "qr-decoder-tool",
    icon = "__qrcode-blueprint__/graphics/icons/qr-code-shortcut.png",
    icon_size = 64,
    flags = {"only-in-cursor", "not-stackable"},
    stack_size = 1,
    select = {
      mode = {"any-entity", "any-tile"},
      cursor_box_type = "entity",
      border_color = {r = 0, g = 1, b = 0, a = 1}
    },
    alt_select = {
      mode = {"any-entity", "any-tile"},
      cursor_box_type = "not-allowed",
      border_color = {r = 1, g = 0, b = 0, a = 1}
    }
  }
})

