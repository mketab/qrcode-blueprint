local azcommon = require("__qrcode-blueprint__.scripts.azteccommon")

local aztecdecode = {}

-- Binary conversion helper
local function to_binary(val, bits)
	local s = ""
	for i = bits - 1, 0, -1 do
		local bit = bit32.band(bit32.rshift(val, i), 1)
		s = s .. tostring(bit)
	end
	return s
end

-- Check if bullseye rings match
local function check_finder_pattern_aztec(matrix, compact)
	local size = #matrix
	local center = math.floor(size / 2) + 1
	local ring_radius = compact and 5 or 7
	
	for x = -ring_radius + 1, ring_radius - 1 do
		for y = -ring_radius + 1, ring_radius - 1 do
			local max_r = math.max(math.abs(x), math.abs(y))
			local expected = ((max_r + 1) % 2 == 1) and 1 or 0
			if matrix[center + x][center + y] ~= expected then
				return false
			end
		end
	end
	return true
end

-- Detect rotation by checking orientation marks
local function get_orientation_rotation(matrix, compact)
	local size = #matrix
	local center = math.floor(size / 2) + 1
	local ring_radius = compact and 5 or 7
	
	for rot = 0, 3 do
		local rotated = {}
		for x = 1, size do
			rotated[x] = {}
			for y = 1, size do
				if rot == 0 then
					rotated[x][y] = matrix[x][y]
				elseif rot == 1 then -- 90 deg CW
					rotated[x][y] = matrix[y][size - x + 1]
				elseif rot == 2 then -- 180 deg
					rotated[x][y] = matrix[size - x + 1][size - y + 1]
				elseif rot == 3 then -- 270 deg CW
					rotated[x][y] = matrix[size - y + 1][x]
				end
			end
		end
		
		-- Check canonical orientation marks on rotated matrix
		local lt1 = rotated[center - ring_radius][center - ring_radius] == 1
		local lt2 = rotated[center - ring_radius + 1][center - ring_radius] == 1
		local lt3 = rotated[center - ring_radius][center - ring_radius + 1] == 1
		
		local rt1 = rotated[center + ring_radius][center - ring_radius] == 1
		local rt2 = rotated[center + ring_radius][center - ring_radius + 1] == 1
		
		local rb1 = rotated[center + ring_radius][center + ring_radius - 1] == 1
		
		local lb1 = rotated[center - ring_radius][center + ring_radius] == 0
		local lb2 = rotated[center - ring_radius + 1][center + ring_radius] == 0
		local lb3 = rotated[center - ring_radius][center + ring_radius - 1] == 0
		
		local rb_corner = rotated[center + ring_radius][center + ring_radius] == 0
		
		if lt1 and lt2 and lt3 and rt1 and rt2 and rb1 and lb1 and lb2 and lb3 and rb_corner then
			return rotated
		end
	end
	return nil
end

-- Read mode info bits from canonical matrix
local function read_mode_info_bits(matrix, compact)
	local size = #matrix
	local center = math.floor(size / 2) + 1
	local ring_radius = compact and 5 or 7
	local side_size = compact and 7 or 11
	local total_bits = compact and 28 or 40
	
	local mode_bits = {}
	local index = 0
	while #mode_bits < total_bits do
		if not compact then
			while (index % side_size) == 5 do
				index = index + 1
			end
		end
		
		local x, y
		local mod_idx = index % side_size
		if index >= 0 and index < side_size then
			x = index + 2 - ring_radius
			y = -ring_radius
		elseif index >= side_size and index < side_size * 2 then
			x = ring_radius
			y = mod_idx + 2 - ring_radius
		elseif index >= side_size * 2 and index < side_size * 3 then
			x = ring_radius - mod_idx - 2
			y = ring_radius
		elseif index >= side_size * 3 and index < side_size * 4 then
			x = -ring_radius
			y = ring_radius - mod_idx - 2
		end
		
		table.insert(mode_bits, matrix[center + x][center + y])
		index = index + 1
	end
	return table.concat(mode_bits)
end

-- Read data bits from canonical matrix
local function read_data_bits(matrix, compact, layers_count, cw_bits, cw_count)
	local size = #matrix
	local center = math.floor(size / 2) + 1
	local ring_radius = compact and 5 or 7
	
	local num = 2
	local side = "top"
	local layer_index = 0
	local pos_x = center - ring_radius
	local pos_y = center - ring_radius - 1
	
	local bits_list = {}
	local total_bits = cw_count * cw_bits
	
	for i = 1, total_bits, 2 do
		num = num + 1
		local max_num = ring_radius * 2 + layer_index * 4 + (compact and 4 or 3)
		local bit1, bit2
		
		if side == "top" then
			local dy0 = (not compact and (center - pos_y) % 16 == 0) and 1 or 0
			local dy1 = (not compact and (center - pos_y + 1) % 16 == 0) and 2 or 1
			bit1 = matrix[pos_x][pos_y - dy0]
			bit2 = matrix[pos_x][pos_y - dy1]
			pos_x = pos_x + 1
			if num > max_num then
				num = 2
				side = "right"
				pos_x = pos_x - 1
				pos_y = pos_y + 1
			end
			if not compact and (center - pos_x) % 16 == 0 then
				pos_x = pos_x + 1
			end
			if not compact and (center - pos_y) % 16 == 0 then
				pos_y = pos_y + 1
			end
			
		elseif side == "right" then
			local dx0 = (not compact and (center - pos_x) % 16 == 0) and 1 or 0
			local dx1 = (not compact and (center - pos_x + 1) % 16 == 0) and 2 or 1
			bit2 = matrix[pos_x - dx0][pos_y]
			bit1 = matrix[pos_x - dx1][pos_y]
			pos_y = pos_y + 1
			if num > max_num then
				num = 2
				side = "bottom"
				pos_x = pos_x - 2
				if not compact and (center - pos_x - 1) % 16 == 0 then
					pos_x = pos_x - 1
				end
				pos_y = pos_y - 1
			end
			if not compact and (center - pos_y) % 16 == 0 then
				pos_y = pos_y + 1
			end
			if not compact and (center - pos_x) % 16 == 0 then
				pos_x = pos_x - 1
			end
			
		elseif side == "bottom" then
			local dy0 = (not compact and (center - pos_y) % 16 == 0) and 1 or 0
			local dy1 = (not compact and (center - pos_y + 1) % 16 == 0) and 2 or 1
			bit2 = matrix[pos_x][pos_y - dy0]
			bit1 = matrix[pos_x][pos_y - dy1]
			pos_x = pos_x - 1
			if num > max_num then
				num = 2
				side = "left"
				pos_x = pos_x + 1
				pos_y = pos_y - 2
				if not compact and (center - pos_y - 1) % 16 == 0 then
					pos_y = pos_y - 1
				end
			end
			if not compact and (center - pos_x) % 16 == 0 then
				pos_x = pos_x - 1
			end
			if not compact and (center - pos_y) % 16 == 0 then
				pos_y = pos_y - 1
			end
			
		elseif side == "left" then
			local dx0 = (not compact and (center - pos_x) % 16 == 0) and 1 or 0
			local dx1 = (not compact and (center - pos_x - 1) % 16 == 0) and 2 or 1
			bit1 = matrix[pos_x + dx1][pos_y]
			bit2 = matrix[pos_x + dx0][pos_y]
			pos_y = pos_y - 1
			if num > max_num then
				num = 2
				side = "top"
				layer_index = layer_index + 1
			end
			if not compact and (center - pos_y) % 16 == 0 then
				pos_y = pos_y - 1
			end
		end
		
		table.insert(bits_list, tostring(bit1))
		table.insert(bits_list, tostring(bit2))
	end
	
	local full_bits = table.concat(bits_list)
	return full_bits:reverse()
end

-- Unstuff bit stream
local function unstuff_bits(codewords, codeword_size)
	local unstuffed_bits = {}
	for i = 1, #codewords do
		local cw = codewords[i]
		local bin_str = to_binary(cw, codeword_size)
		local first_part = bin_str:sub(1, codeword_size - 1)
		if not first_part:find("1") or not first_part:find("0") then
			-- Stuffed codeword! Keep only the first codeword_size - 1 bits
			for j = 1, codeword_size - 1 do
				table.insert(unstuffed_bits, first_part:sub(j, j))
			end
		else
			-- Regular codeword
			for j = 1, codeword_size do
				table.insert(unstuffed_bits, bin_str:sub(j, j))
			end
		end
	end
	return table.concat(unstuffed_bits)
end

-- Parse Aztec bitstream into final string
local function decode_aztec_bits(bits)
	local idx = 1
	local mode = "upper"
	local prev_mode = "upper"
	local shift = false
	local shift_mode = nil
	
	local result = {}
	
	local function read_bits(n)
		if idx + n - 1 > #bits then return nil end
		local val = tonumber(bits:sub(idx, idx + n - 1), 2)
		idx = idx + n
		return val
	end
	
	local function has_val(t, val)
		for _, v in ipairs(t) do if v == val then return true end end
		return false
	end
	
	while idx <= #bits do
		local current_mode = shift and shift_mode or mode
		local n_bits = current_mode == "digit" and 4 or 5
		
		local val = read_bits(n_bits)
		if not val then break end
		
		local char_table = azcommon.code_chars[current_mode]
		local token = char_table[val + 1]
		
		if not token then
			break
		end
		
		if token == "P/S" then
			shift = true
			shift_mode = "punct"
		elseif token == "U/S" then
			shift = true
			shift_mode = "upper"
		elseif token == "B/S" then
			local seq_len = read_bits(5)
			if not seq_len then break end
			if seq_len == 0 then
				local extra_len = read_bits(11)
				if not extra_len then break end
				seq_len = extra_len + 31
			end
			for b = 1, seq_len do
				local byte_val = read_bits(8)
				if not byte_val then break end
				table.insert(result, string.char(byte_val))
			end
			shift = false
		elseif token == "L/L" then
			mode = "lower"
			shift = false
		elseif token == "M/L" then
			mode = "mixed"
			shift = false
		elseif token == "D/L" then
			mode = "digit"
			shift = false
		elseif token == "U/L" then
			mode = "upper"
			shift = false
		elseif token == "P/L" then
			mode = "punct"
			shift = false
		elseif token == "FLG(n)" then
			local flg_type = read_bits(3)
			if not flg_type then break end
			shift = false
		else
			table.insert(result, token)
			if shift then
				shift = false
			end
		end
	end
	
	return table.concat(result)
end

-- Decode a canonical matrix
function aztecdecode.decode_matrix(matrix)
	local size = #matrix
	
	-- Determine compactness based on size
	local compact = nil
	if size == 15 then
		compact = true
	elseif size == 19 then
		-- Can be compact (2 layers) or full (1 layer). We check finder patterns to decide!
		if check_finder_pattern_aztec(matrix, true) then
			compact = true
		else
			compact = false
		end
	elseif size == 23 or size == 27 then
		if check_finder_pattern_aztec(matrix, true) then
			compact = true
		else
			compact = false
		end
	else
		compact = false
	end
	
	-- Verify finder pattern
	if not check_finder_pattern_aztec(matrix, compact) then
		return false, "Finder pattern not found"
	end
	
	-- 1. Read mode info
	local mode_bits = read_mode_info_bits(matrix, compact)
	local cws = {}
	for i = 1, #mode_bits, 4 do
		table.insert(cws, tonumber(mode_bits:sub(i, i + 3), 2))
	end
	
	local init_cw_count = compact and 2 or 4
	local total_cw_count = compact and 7 or 10
	
	local corrected_mode, success = azcommon.correct_errors(cws, total_cw_count - init_cw_count, 16, azcommon.polynomials[4])
	if not success then
		return false, "Reed-Solomon decoding of mode info failed"
	end
	
	local decoded_mode_bits_list = {}
	for i = 1, init_cw_count do
		table.insert(decoded_mode_bits_list, to_binary(corrected_mode[i], 4))
	end
	local decoded_mode_bits = table.concat(decoded_mode_bits_list)
	
	local layers_count, data_cw_count
	if compact then
		layers_count = tonumber(decoded_mode_bits:sub(1, 2), 2) + 1
		data_cw_count = tonumber(decoded_mode_bits:sub(3, 8), 2) + 1
	else
		layers_count = tonumber(decoded_mode_bits:sub(1, 5), 2) + 1
		data_cw_count = tonumber(decoded_mode_bits:sub(6, 16), 2) + 1
	end
	
	-- 2. Lookup configuration
	local key = size .. "_" .. tostring(compact)
	local config = azcommon.table[key]
	if not config then
		return false, "Invalid size/compact config key: " .. key
	end
	
	local cw_bits = config.cw_bits
	local cw_count = config.codewords
	
	-- 3. Read data bits
	local full_bits = read_data_bits(matrix, compact, layers_count, cw_bits, cw_count)
	
	-- 4. Convert to codewords
	local cw_list = {}
	for i = 1, #full_bits, cw_bits do
		local val = tonumber(full_bits:sub(i, i + cw_bits - 1), 2)
		if val then
			table.insert(cw_list, val)
		end
	end
	
	-- 5. Error correction
	local corrected_data, data_success = azcommon.correct_errors(cw_list, cw_count - data_cw_count, 2 ^ cw_bits, azcommon.polynomials[cw_bits])
	if not data_success then
		return false, "Reed-Solomon decoding of data failed"
	end
	
	-- Keep only the data codewords
	local data_cws = {}
	for i = 1, data_cw_count do
		table.insert(data_cws, corrected_data[i])
	end
	
	-- 6. Unstuff bits
	local unstuffed = unstuff_bits(data_cws, cw_bits)
	
	-- 7. Decode bitstream
	local ok, text = pcall(decode_aztec_bits, unstuffed)
	if not ok then
		return false, "Failed to parse Aztec data bits: " .. tostring(text)
	end
	
	return true, text
end

-- Bounding box extraction and scan
function aztecdecode.decode(grid, possible_fg_values)
	local unique_vals = {}
	if possible_fg_values then
		for _, v in ipairs(possible_fg_values) do
			unique_vals[v] = true
		end
	else
		for _, col in pairs(grid) do
			for _, val in pairs(col) do
				if val and val ~= "" then
					unique_vals[val] = true
				end
			end
		end
	end
	
	for fg_val, _ in pairs(unique_vals) do
		local x_min, x_max, y_min, y_max = 999999, -999999, 999999, -999999
		local found_any = false
		for x, col in pairs(grid) do
			for y, val in pairs(col) do
				if val == fg_val then
					if x < x_min then x_min = x end
					if x > x_max then x_max = x end
					if y < y_min then y_min = y end
					if y > y_max then y_max = y end
					found_any = true
				end
			end
		end
		
		if found_any then
			local w = x_max - x_min + 1
			local h = y_max - y_min + 1
			local max_len = math.max(w, h)
			
			-- Try various pixel scales S
			for S = 1, 40 do
				local N = math.floor(max_len / S + 0.5)
				-- Aztec sizes must be odd and present in the table
				if N >= 15 and N <= 151 and N % 2 == 1 then
					local key_compact = N .. "_true"
					local key_full = N .. "_false"
					if azcommon.table[key_compact] or azcommon.table[key_full] then
						local tab = {}
						for i = 1, N do
							tab[i] = {}
							local cx = x_min + math.floor((i - 0.5) * S)
							for j = 1, N do
								local cy = y_min + math.floor((j - 0.5) * S)
								local val = grid[cx] and grid[cx][cy]
								tab[i][j] = (val == fg_val) and 1 or 0
							end
						end
						
						-- Check both compact and full finder patterns
						local compact_candidate = false
						if check_finder_pattern_aztec(tab, true) then
							compact_candidate = true
						elseif check_finder_pattern_aztec(tab, false) then
							compact_candidate = false
						else
							compact_candidate = nil
						end
						
						if compact_candidate ~= nil then
							-- Correct rotation
							local aligned = get_orientation_rotation(tab, compact_candidate)
							if aligned then
								local ok, text = aztecdecode.decode_matrix(aligned)
								if ok then
									return true, text
								end
							end
						end
					end
				end
			end
		end
	end
	
	return false, "No valid Aztec code central finder bullseye patterns detected in selection"
end

return aztecdecode
