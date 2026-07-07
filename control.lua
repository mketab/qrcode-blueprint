local qrencode = require("__qrcode-blueprint__.qrencode")
local qrdecode = require("__qrcode-blueprint__.qrdecode")

local function is_valid_blueprint_item(item_name)
  if not item_name then return true end
  local proto = prototypes.item[item_name]
  if not proto or proto.hidden then return false end
  
  if proto.place_result then
    local ent_proto = proto.place_result
    if ent_proto.tile_width ~= ent_proto.tile_height then
      return false
    end
    if ent_proto.type == "mining-drill" or ent_proto.type == "offshore-pump" then
      return false
    end
    return ent_proto.has_flag("player-creation") and not ent_proto.has_flag("not-blueprintable")
  end
  
  if proto.place_as_tile_result then
    local tile_proto = proto.place_as_tile_result.result
    return tile_proto and not tile_proto.hidden
  end
  
  return false
end

local valid_blueprint_items = nil
local function get_valid_blueprint_items()
  if not valid_blueprint_items then
    valid_blueprint_items = {}
    for name, _ in pairs(prototypes.item) do
      if is_valid_blueprint_item(name) then
        table.insert(valid_blueprint_items, name)
      end
    end
  end
  return valid_blueprint_items
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

local function get_item_filters_for_size(w, h)
  if not w or not h then
    return {
      {filter = "name", name = get_valid_blueprint_items()}
    }
  end
  
  local list = {}
  for name, _ in pairs(prototypes.item) do
    if is_valid_blueprint_item(name) then
      local item_w, item_h = get_item_placed_size(name)
      if item_w == w and item_h == h then
        table.insert(list, name)
      end
    end
  end
  
  if #list == 0 then
    return {
      {filter = "name", name = {}}
    }
  end
  
  return {
    {filter = "name", name = list}
  }
end

local function get_player_settings(player_index)
  if not storage.player_settings then
    storage.player_settings = {}
  end
  if not storage.player_settings[player_index] then
    local default_fg = "stone-wall"
    storage.player_settings[player_index] = {
      foreground_item = default_fg,
      background_item = nil,
      scale = 1,
      text = ""
    }
  end
  return storage.player_settings[player_index]
end

local function save_player_settings(player, frame)
  local settings = get_player_settings(player.index)
  local content = frame.content_frame
  if not content then return end
  
  local table_elem = content.settings_table
  local text_box = content.qr_text_box
  
  if text_box then
    settings.text = text_box.text
  end
  if table_elem then
    if table_elem.qr_foreground_item then
      settings.foreground_item = table_elem.qr_foreground_item.elem_value
    end
    if table_elem.qr_background_item then
      settings.background_item = table_elem.qr_background_item.elem_value
    end
    if table_elem.qr_pixel_scale then
      settings.scale = table_elem.qr_pixel_scale.selected_index
    end
  end
end

local function get_current_tile_size(table_elem)
  if not table_elem then return 1 end
  local fg_w = 1
  if table_elem.qr_foreground_item and table_elem.qr_foreground_item.elem_value then
    fg_w = get_item_placed_size(table_elem.qr_foreground_item.elem_value) or 1
  end
  local bg_w = 1
  if table_elem.qr_background_item and table_elem.qr_background_item.elem_value then
    bg_w = get_item_placed_size(table_elem.qr_background_item.elem_value) or 1
  end
  return math.max(fg_w, bg_w)
end

local function update_pixel_scale_dropdown(table_elem, initial_scale)
  local dropdown = table_elem.qr_pixel_scale
  if not (dropdown and dropdown.valid) then return end
  
  local tile_size = get_current_tile_size(table_elem)
  
  -- Calculate items to show based on tile size
  local items = {}
  local max_scale = 1
  if tile_size == 1 then
    max_scale = 5
  elseif tile_size == 2 then
    max_scale = 2
  elseif tile_size == 3 then
    max_scale = 2
  elseif tile_size == 4 then
    max_scale = 1
  else
    max_scale = 1
  end
  
  for s = 1, max_scale do
    table.insert(items, string.format("%dx%d", s, s))
  end
  
  dropdown.items = items
  
  local target_index = initial_scale or dropdown.selected_index or 1
  if target_index > max_scale then
    target_index = max_scale
  end
  if target_index < 1 then
    target_index = 1
  end
  dropdown.selected_index = target_index
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
  
  local settings = get_player_settings(player.index)
  


  if settings.foreground_item and not is_valid_blueprint_item(settings.foreground_item) then
    settings.foreground_item = nil
  end
  if settings.background_item and not is_valid_blueprint_item(settings.background_item) then
    settings.background_item = nil
  end
  if settings.foreground_item and settings.background_item then
    local fg_w, fg_h = get_item_placed_size(settings.foreground_item)
    local bg_w, bg_h = get_item_placed_size(settings.background_item)
    if fg_w ~= bg_w or fg_h ~= bg_h then
      settings.background_item = nil
    end
  end
  
  text_box.text = settings.text
  
  local settings_table = content_frame.add{
    type = "table",
    name = "settings_table",
    column_count = 2
  }
  settings_table.style.top_margin = 4
  settings_table.style.bottom_margin = 12
  settings_table.style.vertical_spacing = 8
  settings_table.style.horizontal_spacing = 12
  
  local fg_w, fg_h = get_item_placed_size(settings.foreground_item)
  local bg_w, bg_h = get_item_placed_size(settings.background_item)
  
  local fg_filters = get_item_filters_for_size(bg_w, bg_h)
  local bg_filters = get_item_filters_for_size(fg_w, fg_h)
  

  settings_table.add{
    type = "label",
    caption = {"qr-gui.foreground-item"}
  }
  local btn_fg = settings_table.add{
    type = "choose-elem-button",
    name = "qr_foreground_item",
    elem_type = "item",
    elem_filters = fg_filters
  }
  btn_fg.elem_value = settings.foreground_item
  

  settings_table.add{
    type = "label",
    caption = {"qr-gui.background-item"}
  }
  local btn_bg = settings_table.add{
    type = "choose-elem-button",
    name = "qr_background_item",
    elem_type = "item",
    elem_filters = bg_filters
  }
  btn_bg.elem_value = settings.background_item
  

  settings_table.add{
    type = "label",
    caption = {"qr-gui.pixel-scale"}
  }
  settings_table.add{
    type = "drop-down",
    name = "qr_pixel_scale",
    items = {"1x1", "2x2", "3x3", "4x4", "5x5"},
    selected_index = 1
  }
  update_pixel_scale_dropdown(settings_table, settings.scale or 1)
  
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
    name = "qr_decode_button",
    caption = {"qr-gui.decode-map"},
    style = "back_button"
  }
  
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
    save_player_settings(player, frame)
    frame.destroy()
  else
    open_qr_gui(player)
  end
end

local function generate_qr_blueprint(player, settings)
  local text = settings.text
  local fg_item = settings.foreground_item
  local bg_item = settings.background_item
  local scale = settings.scale or 1
  
  if not (fg_item or bg_item) then
    player.print({"qr-gui.error-no-selection"})
    return false
  end
  
  if bg_item and not fg_item then
    player.print({"qr-gui.error-only-background"})
    return false
  end
  
  if fg_item and not is_valid_blueprint_item(fg_item) then
    player.print({"qr-gui.error-invalid-item", fg_item})
    return false
  end
  if bg_item and not is_valid_blueprint_item(bg_item) then
    player.print({"qr-gui.error-invalid-item", bg_item})
    return false
  end
  
  if fg_item and bg_item then
    local fg_w, fg_h = get_item_placed_size(fg_item)
    local bg_w, bg_h = get_item_placed_size(bg_item)
    if fg_w ~= bg_w or fg_h ~= bg_h then
      player.print({"qr-gui.error-size-mismatch", string.format("%dx%d", fg_w, fg_h), string.format("%dx%d", bg_w, bg_h)})
      return false
    end
  end
  
  local ok, tab = qrencode.qrcode(text)
  if not ok then
    player.print({"qr-gui.error-generating", tostring(tab)})
    return false
  end
  
  player.clear_cursor()
  local cursor_stack = player.cursor_stack
  if not (cursor_stack and cursor_stack.valid) then
    player.print({"qr-gui.error-cursor"})
    return false
  end
  
  if not cursor_stack.set_stack({name = "blueprint", count = 1}) then
    player.print({"qr-gui.error-blueprint"})
    return false
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
  
  local cell_size = scale * math.max(fg_width, bg_width)
  for x = 1, N do
    local px_base = (x - 1 - half_N) * cell_size
    for y = 1, N do
      local py_base = (y - 1 - half_N) * cell_size
      local is_fg = tab[x][y] > 0
      
      if is_fg then
        if fg_type == "tile" then
          for i = 0, scale - 1 do
            local dx = i * fg_width
            for j = 0, scale - 1 do
              local dy = j * fg_height
              table.insert(tiles, {
                name = fg_name,
                position = {x = px_base + dx, y = py_base + dy}
              })
            end
          end
        elseif fg_type == "entity" then
          for i = 0, scale - 1 do
            local dx = i * fg_width
            for j = 0, scale - 1 do
              local dy = j * fg_height
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
          for i = 0, scale - 1 do
            local dx = i * bg_width
            for j = 0, scale - 1 do
              local dy = j * bg_height
              table.insert(tiles, {
                name = bg_name,
                position = {x = px_base + dx, y = py_base + dy}
              })
            end
          end
        elseif bg_type == "entity" then
          for i = 0, scale - 1 do
            local dx = i * bg_width
            for j = 0, scale - 1 do
              local dy = j * bg_height
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
  return true
end

script.on_init(function()
  storage.player_settings = {}
end)

script.on_configuration_changed(function()
  storage.player_settings = storage.player_settings or {}
end)

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
    local frame = player.gui.screen.qr_code_frame
    if frame then
      save_player_settings(player, frame)
      frame.destroy()
    end
  elseif element.name == "qr_decode_button" then
    local player = game.players[event.player_index]
    local frame = player.gui.screen.qr_code_frame
    if frame then
      save_player_settings(player, frame)
      frame.destroy()
    end
    -- Give player the selection tool
    player.clear_cursor()
    local cursor_stack = player.cursor_stack
    if cursor_stack and cursor_stack.valid then
      cursor_stack.set_stack({name = "qr-decoder-tool", count = 1})
    end
  elseif element.name == "qr_generate_button" then
    local player = game.players[event.player_index]
    local frame = player.gui.screen.qr_code_frame
    if frame then
      local text_box = frame.content_frame.qr_text_box
      if text_box and text_box.text ~= "" then
        save_player_settings(player, frame)
        local settings = get_player_settings(player.index)
        local success = generate_qr_blueprint(player, settings)
        frame.destroy()
        if not success then
          open_qr_gui(player)
        end
      else
        player.print({"qr-gui.error-no-text"})
      end
    end
  elseif element.name == "qr_decoded_close_button" then
    local player = game.players[event.player_index]
    local frame = player.gui.screen.qr_decoded_frame
    if frame then
      frame.destroy()
    end
  end
end)

script.on_event(defines.events.on_gui_closed, function(event)
  if event.element and event.element.valid then
    if event.element.name == "qr_code_frame" then
      local player = game.players[event.player_index]
      if player then
        save_player_settings(player, event.element)
      end
      event.element.destroy()
    elseif event.element.name == "qr_decoded_frame" then
      event.element.destroy()
    end
  end
end)

script.on_event(defines.events.on_gui_elem_changed, function(event)
  local element = event.element
  if not (element and element.valid) then return end
  
  local player = game.players[event.player_index]
  if not player then return end
  
  if element.name == "qr_foreground_item" then
    local val = element.elem_value
    local table_elem = element.parent
    local bg_btn = table_elem and table_elem.qr_background_item
    
    if val then
      if not is_valid_blueprint_item(val) then
        player.print({"qr-gui.error-invalid-item", val})
        element.elem_value = nil
        if bg_btn and bg_btn.valid then
          bg_btn.elem_filters = get_item_filters_for_size(nil, nil)
        end
        update_pixel_scale_dropdown(table_elem)
        return
      end
      
      local fg_w, fg_h = get_item_placed_size(val)
      if bg_btn and bg_btn.valid then
        bg_btn.elem_filters = get_item_filters_for_size(fg_w, fg_h)
        
        local bg_val = bg_btn.elem_value
        if bg_val then
          local bg_w, bg_h = get_item_placed_size(bg_val)
          if fg_w ~= bg_w or fg_h ~= bg_h then
            player.print({"qr-gui.error-size-mismatch", string.format("%dx%d", fg_w, fg_h), string.format("%dx%d", bg_w, bg_h)})
            element.elem_value = nil
            bg_btn.elem_filters = get_item_filters_for_size(nil, nil)
          end
        end
      end
    else
      if bg_btn and bg_btn.valid then
        bg_btn.elem_filters = get_item_filters_for_size(nil, nil)
      end
    end
    update_pixel_scale_dropdown(table_elem)
    
  elseif element.name == "qr_background_item" then
    local val = element.elem_value
    local table_elem = element.parent
    local fg_btn = table_elem and table_elem.qr_foreground_item
    
    if val then
      if not is_valid_blueprint_item(val) then
        player.print({"qr-gui.error-invalid-item", val})
        element.elem_value = nil
        if fg_btn and fg_btn.valid then
          fg_btn.elem_filters = get_item_filters_for_size(nil, nil)
        end
        update_pixel_scale_dropdown(table_elem)
        return
      end
      
      local bg_w, bg_h = get_item_placed_size(val)
      if fg_btn and fg_btn.valid then
        fg_btn.elem_filters = get_item_filters_for_size(bg_w, bg_h)
        
        local fg_val = fg_btn.elem_value
        if fg_val then
          local fg_w, fg_h = get_item_placed_size(fg_val)
          if fg_w ~= bg_w or fg_h ~= bg_h then
            player.print({"qr-gui.error-size-mismatch", string.format("%dx%d", bg_w, bg_h), string.format("%dx%d", fg_w, fg_h)})
            element.elem_value = nil
            fg_btn.elem_filters = get_item_filters_for_size(nil, nil)
          end
        end
      end
    else
      if fg_btn and fg_btn.valid then
        fg_btn.elem_filters = get_item_filters_for_size(nil, nil)
      end
    end
    update_pixel_scale_dropdown(table_elem)
  end
end)

local function open_decoded_gui(player, text)
  if player.gui.screen.qr_decoded_frame then
    player.gui.screen.qr_decoded_frame.destroy()
  end
  
  local frame = player.gui.screen.add{
    type = "frame",
    name = "qr_decoded_frame",
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
    caption = {"qr-gui.decoded-title"},
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
    name = "qr_decoded_close_button",
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
  
  local text_box = content_frame.add{
    type = "text-box",
    name = "qr_decoded_text_box",
    text = text
  }
  text_box.style.width = 350
  text_box.style.height = 150
  text_box.style.top_margin = 4
  text_box.style.bottom_margin = 12
  text_box.read_only = true
  
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
    name = "qr_decoded_close_button",
    caption = {"qr-gui.close"},
    style = "confirm_button"
  }
  
  player.opened = frame
end

script.on_event(defines.events.on_player_selected_area, function(event)
  if event.item == "qr-decoder-tool" then
    local player = game.players[event.player_index]
    if not player then return end
    
    local surface = player.surface
    local area = event.area
    
    -- Get integer coordinates of selection
    local x_min = math.floor(area.left_top.x)
    local x_max = math.floor(area.right_bottom.x)
    local y_min = math.floor(area.left_top.y)
    local y_max = math.floor(area.right_bottom.y)
    
    -- Scan the area tile by tile
    local grid = {}
    for x = x_min, x_max do
      grid[x] = {}
      for y = y_min, y_max do
        grid[x][y] = "" -- default background/empty
      end
    end
    
    -- Process entities in selection
    for _, ent in ipairs(event.entities) do
      if ent.valid then
        if ent.prototype.has_flag("player-creation") and not ent.prototype.has_flag("not-blueprintable") then
          local w = ent.prototype.tile_width or 1
          local h = ent.prototype.tile_height or 1
          local x_start = math.floor(ent.position.x - w / 2)
          local y_start = math.floor(ent.position.y - h / 2)
          for dx = 0, w - 1 do
            local x = x_start + dx
            if grid[x] then
              for dy = 0, h - 1 do
                local y = y_start + dy
                if grid[x][y] then
                  grid[x][y] = ent.name
                end
              end
            end
          end
        end
      end
    end
    
    -- Process tiles in selection
    for x = x_min, x_max do
      for y = y_min, y_max do
        if grid[x][y] == "" then
          local tile = surface.get_tile(x, y)
          if tile and tile.valid then
            local name = tile.name
            if name:find("concrete") or name:find("path") or name:find("brick") or name:find("asphalt") or name:find("floor") or name:find("tile") then
              grid[x][y] = name
            end
          end
        end
      end
    end
    
    -- Call the decoder
    local ok, result = qrdecode.decode(grid)
    
    -- Clear the custom selection tool from the cursor
    player.clear_cursor()
    
    if ok then
      open_decoded_gui(player, result)
    else
      player.print({"qr-gui.error-no-qrcode-found"})
      open_qr_gui(player)
    end
  end
end)
