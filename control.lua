local qrencode = require("__qrcode-blueprint__.qrencode")

local function open_qr_gui(player)
  if player.gui.screen.qr_code_frame then
    player.gui.screen.qr_code_frame.destroy()
  end
  
  local frame = player.gui.screen.add{
    type = "frame",
    name = "qr_code_frame",
    direction = "vertical"
  }
  frame.auto_center = true
  
  local titlebar = frame.add{
    type = "flow",
    direction = "horizontal",
    name = "titlebar"
  }
  
  local label = titlebar.add{
    type = "label",
    caption = "QR Code Blueprint Generator",
    style = "frame_title"
  }
  label.ignored_by_interaction = true
  
  local filler = titlebar.add{
    type = "empty-widget",
    style = "draggable_space_header"
  }
  filler.style.horizontally_stretchable = true
  filler.style.vertically_stretchable = true
  filler.style.height = 24
  filler.drag_target = frame
  
  titlebar.add{
    type = "sprite-button",
    name = "qr_close_button",
    style = "frame_action_button",
    sprite = "utility/close",
    hovered_sprite = "utility/close_black",
    clicked_sprite = "utility/close_black"
  }
  
  local content_frame = frame.add{
    type = "frame",
    name = "content_frame",
    direction = "vertical",
    style = "inside_deep_frame"
  }
  content_frame.style.padding = 12
  
  content_frame.add{
    type = "label",
    caption = "Enter text to encode as walls in a blueprint:"
  }
  
  local text_box = content_frame.add{
    type = "text-box",
    name = "qr_text_box",
    text = ""
  }
  text_box.style.width = 350
  text_box.style.height = 100
  text_box.style.top_margin = 8
  text_box.style.bottom_margin = 8
  
  text_box.focus()
  
  local action_flow = content_frame.add{
    type = "flow",
    direction = "horizontal"
  }
  
  local action_filler = action_flow.add{
    type = "empty-widget"
  }
  action_filler.style.horizontally_stretchable = true
  
  action_flow.add{
    type = "button",
    name = "qr_generate_button",
    caption = "Generate QR Code",
    style = "confirm_button"
  }
  
  player.opened = frame
end

local function generate_qr_blueprint(player, text)
  local ok, tab = qrencode.qrcode(text)
  if not ok then
    player.print("Error generating QR code: " .. tostring(tab))
    return
  end
  
  player.clear_cursor()
  local cursor_stack = player.cursor_stack
  if not (cursor_stack and cursor_stack.valid) then
    player.print("Failed to access cursor stack.")
    return
  end
  
  if not cursor_stack.set_stack({name = "blueprint", count = 1}) then
    player.print("Failed to place blueprint in cursor.")
    return
  end
  
  local entity_name = "stone-wall"
  local prototypes_entity = (_G.prototypes and _G.prototypes.entity) or game.entity_prototypes
  if settings and settings.global and settings.global["qr-pixel-entity"] then
    local setting_val = settings.global["qr-pixel-entity"].value
    if prototypes_entity and prototypes_entity[setting_val] then
      entity_name = setting_val
    end
  end

  local tile_width = 1
  local tile_height = 1
  local proto = prototypes_entity and prototypes_entity[entity_name]
  if proto then
    tile_width = proto.tile_width or 1
    tile_height = proto.tile_height or 1
  end
  
  local entities = {}
  local N = #tab
  local half_N = math.floor(N / 2)
  local entity_idx = 1
  
  for x = 1, N do
    for y = 1, N do
      if tab[x][y] > 0 then
        local px = (x - half_N) * tile_width + (tile_width / 2)
        local py = (y - half_N) * tile_height + (tile_height / 2)
        
        table.insert(entities, {
          entity_number = entity_idx,
          name = entity_name,
          position = {x = px, y = py}
        })
        entity_idx = entity_idx + 1
      end
    end
  end
  
  cursor_stack.set_blueprint_entities(entities)
  cursor_stack.label = "QR: " .. string.sub(text, 1, 30)
  
  player.print("QR code blueprint created!")
end

script.on_event(defines.events.on_lua_shortcut, function(event)
  if event.prototype_name == "qr-code-shortcut" then
    local player = game.players[event.player_index]
    if player then
      open_qr_gui(player)
    end
  end
end)

script.on_event(defines.events.on_gui_click, function(event)
  local element = event.element
  if not (element and element.valid) then return end
  
  if element.name == "qr_close_button" then
    local player = game.players[event.player_index]
    if player.gui.screen.qr_code_frame then
      player.gui.screen.qr_code_frame.destroy()
    end
  elseif element.name == "qr_generate_button" then
    local player = game.players[event.player_index]
    local frame = player.gui.screen.qr_code_frame
    if frame then
      local text_box = frame.content_frame.qr_text_box
      if text_box and text_box.text ~= "" then
        generate_qr_blueprint(player, text_box.text)
        frame.destroy()
      else
        player.print("Please enter some text first.")
      end
    end
  end
end)

script.on_event(defines.events.on_gui_confirmed, function(event)
  local element = event.element
  if not (element and element.valid) then return end
  
  if element.name == "qr_text_box" then
    local player = game.players[event.player_index]
    local text = element.text
    if text ~= "" then
      generate_qr_blueprint(player, text)
      local frame = player.gui.screen.qr_code_frame
      if frame then
        frame.destroy()
      end
    else
      player.print("Please enter some text first.")
    end
  end
end)

script.on_event(defines.events.on_gui_closed, function(event)
  if event.element and event.element.valid and event.element.name == "qr_code_frame" then
    event.element.destroy()
  end
end)
