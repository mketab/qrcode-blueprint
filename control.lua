local qrencode = require("__qrcode-blueprint__.qrencode")

local function is_valid_blueprint_item(item_name)
  if not item_name then return true end
  local proto = prototypes.item[item_name]
  if not proto then return false end
  
  if proto.place_result then
    local ent_proto = proto.place_result
    return ent_proto.has_flag("player-creation") and not ent_proto.has_flag("not-blueprintable")
  end
  
  if proto.place_as_tile_result then
    local tile_proto = proto.place_as_tile_result.result
    return tile_proto and not tile_proto.hidden
  end
  
  return false
end

local function get_item_placed_size(item_name)
  if not item_name then return nil, nil end
  local proto = prototypes.item[item_name]
  if not proto then return nil, nil end
  
  if proto.place_result then
    local ent_proto = proto.place_result
    return ent_proto.tile_width or 1, ent_proto.tile_height or 1
  end
  
  if proto.place_as_tile_result then
    return 1, 1
  end
  
  return nil, nil
end


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
    caption = {"qr-gui.window-title"},
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
    caption = {"qr-gui.enter-text"}
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
  
  local settings_table = content_frame.add{
    type = "table",
    name = "settings_table",
    column_count = 2
  }
  settings_table.style.top_margin = 4
  settings_table.style.bottom_margin = 12
  settings_table.style.vertical_spacing = 8
  settings_table.style.horizontal_spacing = 12
  
  local item_filters = {
    {filter = "place-result"},
    {filter = "place-as-tile", mode = "or"}
  }
  
  settings_table.add{
    type = "label",
    caption = {"qr-gui.foreground-item"}
  }
  local btn_fg = settings_table.add{
    type = "choose-elem-button",
    name = "qr_foreground_item",
    elem_type = "item",
    elem_filters = item_filters
  }
  
  local default_fg = "stone-wall"
  if settings and settings.global and settings.global["qr-pixel-entity"] then
    local setting_val = settings.global["qr-pixel-entity"].value
    if prototypes.item[setting_val] and is_valid_blueprint_item(setting_val) then
      default_fg = setting_val
    end
  end
  btn_fg.elem_value = default_fg
  
  settings_table.add{
    type = "label",
    caption = {"qr-gui.background-item"}
  }
  local btn_bg = settings_table.add{
    type = "choose-elem-button",
    name = "qr_background_item",
    elem_type = "item",
    elem_filters = item_filters
  }
  btn_bg.elem_value = nil
  
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
    caption = {"qr-gui.generate"},
    style = "confirm_button"
  }
  
  player.opened = frame
end

local function toggle_qr_gui(player)
  local frame = player.gui.screen.qr_code_frame
  if frame then
    frame.destroy()
  else
    open_qr_gui(player)
  end
end

local function generate_qr_blueprint(player, text, fg_item, bg_item)
  local scale = 1
  
  if not (fg_item or bg_item) then
    player.print({"qr-gui.error-no-selection"})
    return
  end
  
  if fg_item and not is_valid_blueprint_item(fg_item) then
    player.print({"qr-gui.error-invalid-item", fg_item})
    return
  end
  if bg_item and not is_valid_blueprint_item(bg_item) then
    player.print({"qr-gui.error-invalid-item", bg_item})
    return
  end
  
  if fg_item and bg_item then
    local fg_w, fg_h = get_item_placed_size(fg_item)
    local bg_w, bg_h = get_item_placed_size(bg_item)
    if fg_w ~= bg_w or fg_h ~= bg_h then
      player.print({"qr-gui.error-size-mismatch", string.format("%dx%d", fg_w, fg_h), string.format("%dx%d", bg_w, bg_h)})
      return
    end
  end
  
  local ok, tab = qrencode.qrcode(text)
  if not ok then
    player.print({"qr-gui.error-generating", tostring(tab)})
    return
  end
  
  player.clear_cursor()
  local cursor_stack = player.cursor_stack
  if not (cursor_stack and cursor_stack.valid) then
    player.print({"qr-gui.error-cursor"})
    return
  end
  
  if not cursor_stack.set_stack({name = "blueprint", count = 1}) then
    player.print({"qr-gui.error-blueprint"})
    return
  end
  
  local entities = {}
  local tiles = {}
  local N = #tab
  local half_N = math.floor(N / 2)
  local entity_idx = 1
  
  local fg_type, fg_name
  if fg_item then
    local proto = prototypes.item[fg_item]
    if proto.place_result then
      fg_type, fg_name = "entity", proto.place_result.name
    elseif proto.place_as_tile_result then
      fg_type, fg_name = "tile", proto.place_as_tile_result.result.name
    end
  end
  
  local bg_type, bg_name
  if bg_item then
    local proto = prototypes.item[bg_item]
    if proto.place_result then
      bg_type, bg_name = "entity", proto.place_result.name
    elseif proto.place_as_tile_result then
      bg_type, bg_name = "tile", proto.place_as_tile_result.result.name
    end
  end
  
  local fg_width, fg_height = 1, 1
  if fg_item then
    local w, h = get_item_placed_size(fg_item)
    fg_width, fg_height = w or 1, h or 1
  end
  
  local bg_width, bg_height = 1, 1
  if bg_item then
    local w, h = get_item_placed_size(bg_item)
    bg_width, bg_height = w or 1, h or 1
  end
  
  for x = 1, N do
    local px_base = (x - 1 - half_N) * scale
    for y = 1, N do
      local py_base = (y - 1 - half_N) * scale
      local is_fg = tab[x][y] > 0
      
      if is_fg then
        if fg_type == "tile" then
          for dx = 0, scale - 1 do
            for dy = 0, scale - 1 do
              table.insert(tiles, {
                name = fg_name,
                position = {x = px_base + dx, y = py_base + dy}
              })
            end
          end
        elseif fg_type == "entity" then
          for dx = 0, scale - 1, fg_width do
            for dy = 0, scale - 1, fg_height do
              table.insert(entities, {
                entity_number = entity_idx,
                name = fg_name,
                position = {
                  x = px_base + dx + (fg_width / 2),
                  y = py_base + dy + (fg_height / 2)
                }
              })
              entity_idx = entity_idx + 1
            end
          end
        end
      else
        if bg_type == "tile" then
          for dx = 0, scale - 1 do
            for dy = 0, scale - 1 do
              table.insert(tiles, {
                name = bg_name,
                position = {x = px_base + dx, y = py_base + dy}
              })
            end
          end
        elseif bg_type == "entity" then
          for dx = 0, scale - 1, bg_width do
            for dy = 0, scale - 1, bg_height do
              table.insert(entities, {
                entity_number = entity_idx,
                name = bg_name,
                position = {
                  x = px_base + dx + (bg_width / 2),
                  y = py_base + dy + (bg_height / 2)
                }
              })
              entity_idx = entity_idx + 1
            end
          end
        end
      end
    end
  end
  
  if #entities > 0 then
    cursor_stack.set_blueprint_entities(entities)
  end
  if #tiles > 0 then
    cursor_stack.set_blueprint_tiles(tiles)
  end
  
  cursor_stack.label = "QR: " .. string.sub(text, 1, 30)
  player.print({"qr-gui.success"})
end

script.on_event(defines.events.on_lua_shortcut, function(event)
  if event.prototype_name == "qr-code-shortcut" then
    local player = game.players[event.player_index]
    if player then
      toggle_qr_gui(player)
    end
  end
end)

script.on_event("qr-code-hotkey", function(event)
  local player = game.players[event.player_index]
  if player then
    toggle_qr_gui(player)
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
      local settings_table = frame.content_frame.settings_table
      if text_box and text_box.text ~= "" then
        local fg_item = settings_table and settings_table.qr_foreground_item and settings_table.qr_foreground_item.elem_value
        local bg_item = settings_table and settings_table.qr_background_item and settings_table.qr_background_item.elem_value
        generate_qr_blueprint(player, text_box.text, fg_item, bg_item)
        frame.destroy()
      else
        player.print({"qr-gui.error-no-text"})
      end
    end
  end
end)

script.on_event(defines.events.on_gui_closed, function(event)
  if event.element and event.element.valid and event.element.name == "qr_code_frame" then
    event.element.destroy()
  end
end)

script.on_event(defines.events.on_gui_elem_changed, function(event)
  local element = event.element
  if not (element and element.valid) then return end
  
  local player = game.players[event.player_index]
  if not player then return end
  
  if element.name == "qr_foreground_item" then
    local val = element.elem_value
    if val then
      if not is_valid_blueprint_item(val) then
        player.print({"qr-gui.error-invalid-item", val})
        element.elem_value = nil
        return
      end
      
      local table_elem = element.parent
      local bg_btn = table_elem and table_elem.qr_background_item
      local bg_val = bg_btn and bg_btn.elem_value
      if bg_val then
        local fg_w, fg_h = get_item_placed_size(val)
        local bg_w, bg_h = get_item_placed_size(bg_val)
        if fg_w ~= bg_w or fg_h ~= bg_h then
          player.print({"qr-gui.error-size-mismatch", string.format("%dx%d", fg_w, fg_h), string.format("%dx%d", bg_w, bg_h)})
          element.elem_value = nil
        end
      end
    end
  elseif element.name == "qr_background_item" then
    local val = element.elem_value
    if val then
      if not is_valid_blueprint_item(val) then
        player.print({"qr-gui.error-invalid-item", val})
        element.elem_value = nil
        return
      end
      
      local table_elem = element.parent
      local fg_btn = table_elem and table_elem.qr_foreground_item
      local fg_val = fg_btn and fg_btn.elem_value
      if fg_val then
        local fg_w, fg_h = get_item_placed_size(fg_val)
        local bg_w, bg_h = get_item_placed_size(val)
        if fg_w ~= bg_w or fg_h ~= bg_h then
          player.print({"qr-gui.error-size-mismatch", string.format("%dx%d", bg_w, bg_h), string.format("%dx%d", fg_w, fg_h)})
          element.elem_value = nil
        end
      end
    end
  end
end)
