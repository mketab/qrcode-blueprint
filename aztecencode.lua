local azcommon = require("__qrcode-blueprint__.azteccommon")

local aztecencode = {}

-- Binary conversion helper
local function to_binary(val, bits)
	local s = ""
	for i = bits - 1, 0, -1 do
		local bit = bit32.band(bit32.rshift(val, i), 1)
		s = s .. tostring(bit)
	end
	return s
end

-- Find optimal sequence with minimum number of bits
function aztecencode.find_optimal_sequence(data)
	local back_to = {
		upper = "upper", lower = "upper", mixed = "upper",
		punct = "upper", digit = "upper", binary = "upper"
	}
	local cur_len = {
		upper = 0, lower = azcommon.E, mixed = azcommon.E, punct = azcommon.E, digit = azcommon.E, binary = azcommon.E
	}
	local cur_seq = {
		upper = {}, lower = {}, mixed = {}, punct = {}, digit = {}, binary = {}
	}
	
	local prev_c = ""
	for _, c in ipairs(data) do
		for _, x in ipairs(azcommon.modes) do
			for _, y in ipairs(azcommon.modes) do
				if cur_len[x] + azcommon.latch_len[x][y] < cur_len[y] then
					cur_len[y] = cur_len[x] + azcommon.latch_len[x][y]
					if y == "binary" then
						if x == "punct" or x == "digit" then
							back_to[y] = "upper"
							local new_seq = {}
							for _, val in ipairs(cur_seq[x]) do table.insert(new_seq, val) end
							table.insert(new_seq, "U/L")
							table.insert(new_seq, "B/S")
							table.insert(new_seq, "size")
							cur_seq[y] = new_seq
						else
							back_to[y] = x
							local new_seq = {}
							for _, val in ipairs(cur_seq[x]) do table.insert(new_seq, val) end
							table.insert(new_seq, "B/S")
							table.insert(new_seq, "size")
							cur_seq[y] = new_seq
						end
					else
						if #cur_seq[x] > 0 then
							if (x == "punct" or x == "digit") and y ~= "upper" then
								local new_seq = {}
								for _, val in ipairs(cur_seq[x]) do table.insert(new_seq, val) end
								table.insert(new_seq, "resume")
								table.insert(new_seq, "U/L")
								table.insert(new_seq, string.upper(y:sub(1,1)) .. "/L")
								cur_seq[y] = new_seq
								back_to[y] = y
							elseif (x == "upper" or x == "lower") and y == "punct" then
								local new_seq = {}
								for _, val in ipairs(cur_seq[x]) do table.insert(new_seq, val) end
								table.insert(new_seq, "M/L")
								table.insert(new_seq, "P/L")
								cur_seq[y] = new_seq
								back_to[y] = y
							elseif x == "mixed" and y ~= "upper" then
								if y == "punct" then
									local new_seq = {}
									for _, val in ipairs(cur_seq[x]) do table.insert(new_seq, val) end
									table.insert(new_seq, "P/L")
									cur_seq[y] = new_seq
									back_to[y] = "punct"
								else
									local new_seq = {}
									for _, val in ipairs(cur_seq[x]) do table.insert(new_seq, val) end
									table.insert(new_seq, "U/L")
									table.insert(new_seq, "D/L")
									cur_seq[y] = new_seq
									back_to[y] = "digit"
								end
							else
								if x == "binary" then
									if y == back_to[x] then
										local new_seq = {}
										for _, val in ipairs(cur_seq[x]) do table.insert(new_seq, val) end
										table.insert(new_seq, "resume")
										cur_seq[y] = new_seq
									elseif y == "upper" then
										local new_seq = {}
										for _, val in ipairs(cur_seq[x]) do table.insert(new_seq, val) end
										table.insert(new_seq, "resume")
										if back_to[x] == "lower" then
											table.insert(new_seq, "M/L")
											table.insert(new_seq, "U/L")
										elseif back_to[x] == "mixed" then
											table.insert(new_seq, "U/L")
										end
										cur_seq[y] = new_seq
										back_to[y] = "upper"
									elseif y == "lower" then
										local new_seq = {}
										for _, val in ipairs(cur_seq[x]) do table.insert(new_seq, val) end
										table.insert(new_seq, "resume")
										table.insert(new_seq, "L/L")
										cur_seq[y] = new_seq
										back_to[y] = "lower"
									elseif y == "mixed" then
										local new_seq = {}
										for _, val in ipairs(cur_seq[x]) do table.insert(new_seq, val) end
										table.insert(new_seq, "resume")
										table.insert(new_seq, "M/L")
										cur_seq[y] = new_seq
										back_to[y] = "mixed"
									elseif y == "punct" then
										local new_seq = {}
										for _, val in ipairs(cur_seq[x]) do table.insert(new_seq, val) end
										table.insert(new_seq, "resume")
										if back_to[x] == "mixed" then
											table.insert(new_seq, "P/L")
										else
											table.insert(new_seq, "M/L")
											table.insert(new_seq, "P/L")
										end
										cur_seq[y] = new_seq
										back_to[y] = "punct"
									elseif y == "digit" then
										local new_seq = {}
										for _, val in ipairs(cur_seq[x]) do table.insert(new_seq, val) end
										table.insert(new_seq, "resume")
										if back_to[x] == "mixed" then
											table.insert(new_seq, "U/L")
											table.insert(new_seq, "D/L")
										else
											table.insert(new_seq, "D/L")
										end
										cur_seq[y] = new_seq
										back_to[y] = "digit"
									end
								else
									local new_seq = {}
									for _, val in ipairs(cur_seq[x]) do table.insert(new_seq, val) end
									table.insert(new_seq, "resume")
									table.insert(new_seq, string.upper(y:sub(1,1)) .. "/L")
									cur_seq[y] = new_seq
									back_to[y] = y
								end
							end
						else
							if x == "punct" or x == "digit" then
								local new_seq = {}
								for _, val in ipairs(cur_seq[x]) do table.insert(new_seq, val) end
								table.insert(new_seq, "U/L")
								table.insert(new_seq, string.upper(y:sub(1,1)) .. "/L")
								cur_seq[y] = new_seq
								back_to[y] = y
							elseif (x == "binary" or x == "upper" or x == "lower") and y == "punct" then
								local new_seq = {}
								for _, val in ipairs(cur_seq[x]) do table.insert(new_seq, val) end
								table.insert(new_seq, "M/L")
								table.insert(new_seq, "P/L")
								cur_seq[y] = new_seq
								back_to[y] = y
							else
								local new_seq = {}
								for _, val in ipairs(cur_seq[x]) do table.insert(new_seq, val) end
								table.insert(new_seq, string.upper(y:sub(1,1)) .. "/L")
								cur_seq[y] = new_seq
								back_to[y] = y
							end
						end
					end
				end
			end
		end
		
		local next_len = {
			upper = azcommon.E, lower = azcommon.E, mixed = azcommon.E, punct = azcommon.E, digit = azcommon.E, binary = azcommon.E
		}
		local next_seq = {
			upper = {}, lower = {}, mixed = {}, punct = {}, digit = {}, binary = {}
		}
		
		local possible_modes = {}
		local function has_val(t, val)
			for _, v in ipairs(t) do if v == val then return true end end
			return false
		end
		if has_val(azcommon.upper_chars, c) then table.insert(possible_modes, "upper") end
		if has_val(azcommon.lower_chars, c) then table.insert(possible_modes, "lower") end
		if has_val(azcommon.mixed_chars, c) then table.insert(possible_modes, "mixed") end
		if has_val(azcommon.punct_chars, c) then table.insert(possible_modes, "punct") end
		if has_val(azcommon.digit_chars, c) then table.insert(possible_modes, "digit") end
		table.insert(possible_modes, "binary")
		
		for _, x in ipairs(possible_modes) do
			if back_to[x] == "digit" and x == "lower" then
				local seq = cur_seq[x]
				table.insert(seq, "U/L")
				table.insert(seq, "L/L")
				cur_len[x] = cur_len[x] + azcommon.latch_len[back_to[x]][x]
				back_to[x] = "lower"
			end
			
			if cur_len[x] + azcommon.char_size[x] < next_len[x] then
				next_len[x] = cur_len[x] + azcommon.char_size[x]
				local seq = {}
				for _, val in ipairs(cur_seq[x]) do table.insert(seq, val) end
				table.insert(seq, c)
				next_seq[x] = seq
			end
			
			for _, y in ipairs(azcommon.modes) do
				if y ~= "binary" and y ~= x then
					if cur_len[y] + azcommon.shift_len[y][x] + azcommon.char_size[x] < next_len[y] then
						next_len[y] = cur_len[y] + azcommon.shift_len[y][x] + azcommon.char_size[x]
						local seq = {}
						for _, val in ipairs(cur_seq[y]) do table.insert(seq, val) end
						table.insert(seq, string.upper(x:sub(1,1)) .. "/S")
						table.insert(seq, c)
						next_seq[y] = seq
					end
				end
			end
		end
		
		if prev_c ~= "" and has_val(azcommon.punct_2_chars, prev_c .. c) then
			for _, x in ipairs(azcommon.modes) do
				local last_mode = ""
				for idx = #cur_seq[x], 1, -1 do
					local token = cur_seq[x][idx]
					if type(token) == "string" then
						local mode_candidate = token:gsub("/S", ""):gsub("/L", "")
						if azcommon.abbr_modes[mode_candidate] then
							last_mode = azcommon.abbr_modes[mode_candidate]
							break
						end
					end
				end
				
				if last_mode == "punct" then
					if #cur_seq[x] > 0 and has_val(azcommon.punct_2_chars, cur_seq[x][#cur_seq[x]] .. c) and x ~= "mixed" then
						if cur_len[x] < next_len[x] then
							next_len[x] = cur_len[x]
							local seq = {}
							for idx = 1, #cur_seq[x] - 1 do table.insert(seq, cur_seq[x][idx]) end
							table.insert(seq, cur_seq[x][#cur_seq[x]] .. c)
							next_seq[x] = seq
						end
					end
				end
			end
		end
		
		if #next_seq.binary - 2 == 32 then
			next_len.binary = next_len.binary + 11
		end
		
		for _, i in ipairs(azcommon.modes) do
			cur_len[i] = next_len[i]
			cur_seq[i] = next_seq[i]
		end
		prev_c = c
	end
	
	local min_val = azcommon.E
	local min_length = nil
	for _, i in ipairs(azcommon.modes) do
		if cur_len[i] < min_val then
			min_val = cur_len[i]
			min_length = i
		end
	end
	
	local result_seq = {}
	if min_length then
		for _, val in ipairs(cur_seq[min_length]) do
			table.insert(result_seq, val)
		end
	end
	
	local sizes = {}
	local result_seq_len = #result_seq
	local reset_pos = result_seq_len
	for idx = result_seq_len, 1, -1 do
		local token = result_seq[idx]
		if token == "size" then
			sizes[idx] = reset_pos - idx
			reset_pos = idx + 1
		elseif token == "resume" then
			reset_pos = idx - 1
		end
	end
	
	for size_pos, sz in pairs(sizes) do
		result_seq[size_pos] = sz
	end
	
	local filtered_seq = {}
	for _, val in ipairs(result_seq) do
		if val ~= "resume" then
			table.insert(filtered_seq, val)
		end
	end
	result_seq = filtered_seq
	
	local updated_result_seq = {}
	local is_binary_length = false
	for _, c_val in ipairs(result_seq) do
		if is_binary_length then
			if type(c_val) == "number" and c_val > 31 then
				table.insert(updated_result_seq, 0)
				table.insert(updated_result_seq, c_val - 31)
			else
				table.insert(updated_result_seq, c_val)
			end
			is_binary_length = false
		else
			table.insert(updated_result_seq, c_val)
		end
		
		if c_val == "B/S" then
			is_binary_length = true
		end
	end
	
	return updated_result_seq
end

local function optimal_sequence_to_bits(optimal_sequence)
	local out_bits = ""
	local mode = "upper"
	local prev_mode = "upper"
	local shift = false
	local binary = false
	local binary_seq_len = 0
	local binary_index = 0
	local sequence = {}
	for _, val in ipairs(optimal_sequence) do
		table.insert(sequence, val)
	end
	
	local function has_val(t, val)
		for idx, v in ipairs(t) do if v == val then return idx end end
		return nil
	end

	while #sequence > 0 do
		local ch = table.remove(sequence, 1)
		if binary then
			local val = string.byte(ch)
			out_bits = out_bits .. to_binary(val, azcommon.char_size[mode])
			binary_index = binary_index + 1
			if binary_index >= binary_seq_len then
				mode = prev_mode
				binary = false
			end
		else
			local index = has_val(azcommon.code_chars[mode], ch)
			if not index then
				error("Character/Token " .. tostring(ch) .. " not found in mode " .. mode)
			end
			index = index - 1
			out_bits = out_bits .. to_binary(index, azcommon.char_size[mode])
			
			if shift then
				mode = prev_mode
				shift = false
			end
			
			if type(ch) == "string" then
				if ch:sub(-2) == "/L" then
					mode = azcommon.abbr_modes[ch:gsub("/L", "")]
				elseif ch:sub(-2) == "/S" then
					mode = azcommon.abbr_modes[ch:gsub("/S", "")]
					shift = true
				end
			end
			
			if mode == "binary" then
				if #sequence == 0 then
					error("Expected binary sequence length")
				end
				local seq_len = table.remove(sequence, 1)
				if type(seq_len) ~= "number" then
					error("Binary sequence length must be a number")
				end
				out_bits = out_bits .. to_binary(seq_len, 5)
				binary_seq_len = seq_len
				if binary_seq_len == 0 then
					if #sequence == 0 then
						error("Expected extra binary sequence length")
					end
					local extra_len = table.remove(sequence, 1)
					if type(extra_len) ~= "number" then
						error("Binary sequence length must be a number")
					end
					out_bits = out_bits .. to_binary(extra_len, 11)
					binary_seq_len = extra_len + 31
				end
				binary = true
				binary_index = 0
			end
			
			if not shift then
				prev_mode = mode
			end
		end
	end
	return out_bits
end

local function get_data_codewords(bits, codeword_size)
	local codewords = {}
	local sub_bits = ""
	for idx = 1, #bits do
		local bit = bits:sub(idx, idx)
		sub_bits = sub_bits .. bit
		
		if #sub_bits == codeword_size - 1 then
			if not sub_bits:find("1") then
				sub_bits = sub_bits .. "1"
			elseif not sub_bits:find("0") then
				sub_bits = sub_bits .. "0"
			end
		end
		
		if #sub_bits >= codeword_size then
			table.insert(codewords, tonumber(sub_bits, 2))
			sub_bits = ""
		end
	end
	
	if #sub_bits > 0 then
		sub_bits = sub_bits .. string.rep("1", codeword_size - #sub_bits)
		if not sub_bits:find("0") then
			sub_bits = sub_bits:sub(1, -2) .. "0"
		end
		table.insert(codewords, tonumber(sub_bits, 2))
	end
	return codewords
end

local function find_suitable_matrix_size(data)
	local optimal_sequence = aztecencode.find_optimal_sequence(data)
	local out_bits = optimal_sequence_to_bits(optimal_sequence)
	
	local entries = {}
	for key, cfg in pairs(azcommon.table) do
		table.insert(entries, cfg)
	end
	table.sort(entries, function(a, b)
		if a.size == b.size then
			return a.compact and not b.compact
		end
		return a.size < b.size
	end)
	
	for _, cfg in ipairs(entries) do
		local ec_percent = 23
		local required_bits_count = math.ceil(#out_bits * 100.0 / (100 - ec_percent) + 3.0 * 100.0 / (100 - ec_percent))
		if required_bits_count < cfg.bits then
			return cfg.size, cfg.compact
		end
	end
	error("Data too big to fit in one Aztec code!")
end

local function get_mode_message(compact, size, layers_count, data_cw_count)
	local mode_word
	local init_codewords = {}
	local total_cw_count
	if compact then
		-- layers_count - 1 (2 bits), data_cw_count - 1 (6 bits)
		local l_bits = to_binary(layers_count - 1, 2)
		local d_bits = to_binary(data_cw_count - 1, 6)
		mode_word = l_bits .. d_bits
		for i = 1, 8, 4 do
			table.insert(init_codewords, tonumber(mode_word:sub(i, i + 3), 2))
		end
		total_cw_count = 7
	else
		-- layers_count - 1 (5 bits), data_cw_count - 1 (11 bits)
		local l_bits = to_binary(layers_count - 1, 5)
		local d_bits = to_binary(data_cw_count - 1, 11)
		mode_word = l_bits .. d_bits
		for i = 1, 16, 4 do
			table.insert(init_codewords, tonumber(mode_word:sub(i, i + 3), 2))
		end
		total_cw_count = 10
	end
	
	local codewords = {}
	for i = 1, total_cw_count do
		codewords[i] = init_codewords[i] or 0
	end
	
	azcommon.reed_solomon(codewords, #init_codewords, total_cw_count - #init_codewords, 16, azcommon.polynomials[4])
	return codewords
end

-- Generate Aztec matrix
function aztecencode.generate_matrix(text, requested_size, requested_compact)
	local data = {}
	for i = 1, #text do
		table.insert(data, text:sub(i, i))
	end
	
	local size, compact
	if requested_size and requested_compact ~= nil then
		size = requested_size
		compact = requested_compact
	else
		local ok, s, c = pcall(find_suitable_matrix_size, data)
		if not ok then
			return false, s
		end
		size = s
		compact = c
	end
	
	-- Initialize matrix
	local matrix = {}
	for x = 1, size do
		matrix[x] = {}
		for y = 1, size do
			matrix[x][y] = 0
		end
	end
	
	local center = math.floor(size / 2) + 1
	local ring_radius = compact and 5 or 7
	
	-- 1. Add bulls-eye finder pattern
	for x = -ring_radius, ring_radius - 1 do
		for y = -ring_radius, ring_radius - 1 do
			if (math.max(math.abs(x), math.abs(y)) + 1) % 2 == 1 then
				matrix[center + x][center + y] = 1
			end
		end
	end
	
	-- 2. Add orientation marks
	-- left-top
	matrix[center - ring_radius][center - ring_radius] = 1
	matrix[center - ring_radius][center - ring_radius + 1] = 1
	matrix[center - ring_radius + 1][center - ring_radius] = 1
	-- right-top
	matrix[center + ring_radius][center - ring_radius] = 1
	matrix[center + ring_radius][center - ring_radius + 1] = 1
	-- right-down
	matrix[center + ring_radius][center + ring_radius - 1] = 1
	
	-- 3. Add reference grid
	if not compact then
		local half_size = math.floor(size / 2)
		for x = -half_size, half_size do
			for y = -half_size, half_size do
				if not (x >= -ring_radius and x <= ring_radius and y >= -ring_radius and y <= ring_radius) then
					if x % 16 == 0 or y % 16 == 0 then
						local is_fg = ((x + y + 1) % 2 ~= 0)
						matrix[center + x][center + y] = is_fg and 1 or 0
					end
				end
			end
		end
	end
	
	-- 4. Add data layers
	local optimal_sequence = aztecencode.find_optimal_sequence(data)
	local out_bits = optimal_sequence_to_bits(optimal_sequence)
	
	local key = size .. "_" .. tostring(compact)
	local config = azcommon.table[key]
	if not config then
		return false, "Failed to find config for size " .. size
	end
	
	local layers_count = config.layers
	local cw_count = config.codewords
	local cw_bits = config.cw_bits
	local bits = config.bits
	
	local ec_percent = 23
	local required_bits_count = math.ceil(#out_bits * 100.0 / (100 - ec_percent) + 3.0 * 100.0 / (100 - ec_percent))
	local data_codewords = get_data_codewords(out_bits, cw_bits)
	if required_bits_count > bits then
		return false, "Data too big to fit in Aztec code with current size!"
	end
	
	local data_cw_count = #data_codewords
	local codewords = {}
	for i = 1, cw_count do
		codewords[i] = data_codewords[i] or 0
	end
	azcommon.reed_solomon(codewords, data_cw_count, cw_count - data_cw_count, 2 ^ cw_bits, azcommon.polynomials[cw_bits])
	
	-- Draw data layers into matrix
	local num = 2
	local side = "top"
	local layer_index = 0
	local pos_x = center - ring_radius
	local pos_y = center - ring_radius - 1
	
	-- Build full bitstream string, and reverse it as in Python code: full_bits[::-1]
	local full_bits_table = {}
	for _, cw in ipairs(codewords) do
		table.insert(full_bits_table, to_binary(cw, cw_bits))
	end
	local full_bits = table.concat(full_bits_table)
	full_bits = full_bits:reverse()
	
	for i = 1, #full_bits, 2 do
		num = num + 1
		local max_num = ring_radius * 2 + layer_index * 4 + (compact and 4 or 3)
		local bit1 = full_bits:sub(i, i)
		local bit2 = full_bits:sub(i + 1, i + 1)
		
		if layer_index >= layers_count then
			return false, "Maximum layer count for current size is exceeded!"
		end
		
		if side == "top" then
			local dy0 = (not compact and (center - pos_y) % 16 == 0) and 1 or 0
			local dy1 = (not compact and (center - pos_y + 1) % 16 == 0) and 2 or 1
			matrix[pos_x][pos_y - dy0] = (bit1 == "1") and 1 or 0
			matrix[pos_x][pos_y - dy1] = (bit2 == "1") and 1 or 0
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
			matrix[pos_x - dx0][pos_y] = (bit2 == "1") and 1 or 0
			matrix[pos_x - dx1][pos_y] = (bit1 == "1") and 1 or 0
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
			matrix[pos_x][pos_y - dy0] = (bit2 == "1") and 1 or 0
			matrix[pos_x][pos_y - dy1] = (bit1 == "1") and 1 or 0
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
			matrix[pos_x + dx1][pos_y] = (bit1 == "1") and 1 or 0
			matrix[pos_x + dx0][pos_y] = (bit2 == "1") and 1 or 0
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
	end
	
	-- 5. Add mode info
	local mode_data_values = get_mode_message(compact, size, layers_count, data_cw_count)
	local mode_data_bits_table = {}
	for _, v in ipairs(mode_data_values) do
		table.insert(mode_data_bits_table, to_binary(v, 4))
	end
	local mode_data_bits = table.concat(mode_data_bits_table)
	
	local side_size = compact and 7 or 11
	local bit_idx = 1
	local index = 0
	while bit_idx <= #mode_data_bits do
		if not compact then
			while (index % side_size) == 5 do
				index = index + 1
			end
		end
		local bit = mode_data_bits:sub(bit_idx, bit_idx)
		bit_idx = bit_idx + 1
		
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
		
		matrix[center + x][center + y] = (bit == "1") and 1 or 0
		index = index + 1
	end
	
	return true, matrix
end

return aztecencode
