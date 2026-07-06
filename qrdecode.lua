local qrdecode = {}

-- Galois Field 256 Log/Antilog Tables (Primitive Polynomial: x^8 + x^4 + x^3 + x^2 + 1)
local alpha_int = {
	[0] = 1,
	  2,   4,   8,  16,  32,  64, 128,  29,  58, 116, 232, 205, 135,  19,  38,  76,
	152,  45,  90, 180, 117, 234, 201, 143,   3,   6,  12,  24,  48,  96, 192, 157,
	 39,  78, 156,  37,  74, 148,  53, 106, 212, 181, 119, 238, 193, 159,  35,  70,
	140,   5,  10,  20,  40,  80, 160,  93, 186, 105, 210, 185, 111, 222, 161,  95,
	190,  97, 194, 153,  47,  94, 188, 101, 202, 137,  15,  30,  60, 120, 240, 253,
	231, 211, 187, 107, 214, 177, 127, 254, 225, 223, 163,  91, 182, 113, 226, 217,
	175,  67, 134,  17,  34,  68, 136,  13,  26,  52, 104, 208, 189, 103, 206, 129,
	 31,  62, 124, 248, 237, 199, 147,  59, 118, 236, 197, 151,  51, 102, 204, 133,
	 23,  46,  92, 184, 109, 218, 169,  79, 158,  33,  66, 132,  21,  42,  84, 168,
	 77, 154,  41,  82, 164,  85, 170,  73, 146,  57, 114, 228, 213, 183, 115, 230,
	209, 191,  99, 198, 145,  63, 126, 252, 229, 215, 179, 123, 246, 241, 255, 227,
	219, 171,  75, 150,  49,  98, 196, 149,  55, 110, 220, 165,  87, 174,  65, 130,
	 25,  50, 100, 200, 141,   7,  14,  28,  56, 112, 224, 221, 167,  83, 166,  81,
	162,  89, 178, 121, 242, 249, 239, 195, 155,  43,  86, 172,  69, 138,   9,  18,
	 36,  72, 144,  61, 122, 244, 245, 247, 243, 251, 235, 203, 139,  11,  22,  44,
	 88, 176, 125, 250, 233, 207, 131,  27,  54, 108, 216, 173,  71, 142,   0,   0
}

local int_alpha = {
	[0] = 256, -- special value
	0,   1,  25,   2,  50,  26, 198,   3, 223,  51, 238,  27, 104, 199,  75,   4,
	100, 224,  14,  52, 141, 239, 129,  28, 193, 105, 248, 200,   8,  76, 113,   5,
	138, 101,  47, 225,  36,  15,  33,  53, 147, 142, 218, 240,  18, 130,  69,  29,
	181, 194, 125, 106,  39, 249, 185, 201, 154,   9, 120,  77, 228, 114, 166,   6,
	191, 139,  98, 102, 221,  48, 253, 226, 152,  37, 179,  16, 145,  34, 136,  54,
	208, 148, 206, 143, 150, 219, 189, 241, 210,  19,  92, 131,  56,  70,  64,  30,
	 66, 182, 163, 195,  72, 126, 110, 107,  58,  40,  84, 250, 133, 186,  61, 202,
	 94, 155, 159,  10,  21, 121,  43,  78, 212, 229, 172, 115, 243, 167,  87,   7,
	112, 192, 247, 140, 128,  99,  13, 103,  74, 222, 237,  49, 197, 254,  24, 227,
	165, 153, 119,  38, 184, 180, 124,  17,  68, 146, 217,  35,  32, 137,  46,  55,
	 63, 209,  91, 149, 188, 207, 205, 144, 135, 151, 178, 220, 252, 190,  97, 242,
	 86, 211, 171,  20,  42,  93, 158, 132,  60,  57,  83,  71, 109,  65, 162,  31,
	 45,  67, 216, 183, 123, 164, 118, 196,  23,  73, 236, 127,  12, 111, 246, 108,
	161,  59,  82,  41, 157,  85, 170, 251,  96, 134, 177, 187, 204,  62,  90, 203,
	 89,  95, 176, 156, 169, 160,  81,  11, 245,  22, 235, 122, 117,  44, 215,  79,
	174, 213, 233, 230, 231, 173, 232, 116, 214, 244, 234, 168,  80,  88, 175
}

-- Alignment patterns
local alignment_pattern = {
	{},{6,18},{6,22},{6,26},{6,30},{6,34}, -- 1-6
	{6,22,38},{6,24,42},{6,26,46},{6,28,50},{6,30,54},{6,32,58},{6,34,62}, -- 7-13
	{6,26,46,66},{6,26,48,70},{6,26,50,74},{6,30,54,78},{6,30,56,82},{6,30,58,86},{6,34,62,90}, -- 14-20
	{6,28,50,72,94},{6,26,50,74,98},{6,30,54,78,102},{6,28,54,80,106},{6,32,58,84,110},{6,30,58,86,114},{6,34,62,90,118}, -- 21-27
	{6,26,50,74,98 ,122},{6,30,54,78,102,126},{6,26,52,78,104,130},{6,30,56,82,108,134},{6,34,60,86,112,138},{6,30,58,86,114,142},{6,34,62,90,118,146}, -- 28-34
	{6,30,54,78,102,126,150}, {6,24,50,76,102,128,154},{6,28,54,80,106,132,158},{6,32,58,84,110,136,162},{6,26,54,82,110,138,166},{6,30,58,86,114,142,170} -- 35 - 40
}

-- Block layouts: ecblocks[version][ec_level] = list of block count and size
local ecblocks = {
	{{  1,{ 26, 19, 2}                 },   {  1,{26,16, 4}},                  {  1,{26,13, 6}},                  {  1, {26, 9, 8}               }},
	{{  1,{ 44, 34, 4}                 },   {  1,{44,28, 8}},                  {  1,{44,22,11}},                  {  1, {44,16,14}               }},
	{{  1,{ 70, 55, 7}                 },   {  1,{70,44,13}},                  {  2,{35,17, 9}},                  {  2, {35,13,11}               }},
	{{  1,{100, 80,10}                 },   {  2,{50,32, 9}},                  {  2,{50,24,13}},                  {  4, {25, 9, 8}               }},
	{{  1,{134,108,13}                 },   {  2,{67,43,12}},                  {  2,{33,15, 9},  2,{34,16, 9}},   {  2, {33,11,11},  2,{34,12,11}}},
	{{  2,{ 86, 68, 9}                 },   {  4,{43,27, 8}},                  {  4,{43,19,12}},                  {  4, {43,15,14}               }},
	{{  2,{ 98, 78,10}                 },   {  4,{49,31, 9}},                  {  2,{32,14, 9},  4,{33,15, 9}},   {  4, {39,13,13},  1,{40,14,13}}},
	{{  2,{121, 97,12}                 },   {  2,{60,38,11},  2,{61,39,11}},   {  4,{40,18,11},  2,{41,19,11}},   {  4, {40,14,13},  2,{41,15,13}}},
	{{  2,{146,116,15}                 },   {  3,{58,36,11},  2,{59,37,11}},   {  4,{36,16,10},  4,{37,17,10}},   {  4, {36,12,12},  4,{37,13,12}}},
	{{  2,{ 86, 68, 9},  2,{ 87, 69, 9}},   {  4,{69,43,13},  1,{70,44,13}},   {  6,{43,19,12},  2,{44,20,12}},   {  6, {43,15,14},  2,{44,16,14}}},
	{{  4,{101, 81,10}                 },   {  1,{80,50,15},  4,{81,51,15}},   {  4,{50,22,14},  4,{51,23,14}},   {  3, {36,12,12},  8,{37,13,12}}},
	{{  2,{116, 92,12},  2,{117, 93,12}},   {  6,{58,36,11},  2,{59,37,11}},   {  4,{46,20,13},  6,{47,21,13}},   {  7, {42,14,14},  4,{43,15,14}}},
	{{  4,{133,107,13}                 },   {  8,{59,37,11},  1,{60,38,11}},   {  8,{44,20,12},  4,{45,21,12}},   { 12, {33,11,11},  4,{34,12,11}}},
	{{  3,{145,115,15},  1,{146,116,15}},   {  4,{64,40,12},  5,{65,41,12}},   { 11,{36,16,10},  5,{37,17,10}},   { 11, {36,12,12},  5,{37,13,12}}},
	{{  5,{109, 87,11},  1,{110, 88,11}},   {  5,{65,41,12},  5,{66,42,12}},   {  5,{54,24,15},  7,{55,25,15}},   { 11, {36,12,12},  7,{37,13,12}}},
	{{  5,{122, 98,12},  1,{123, 99,12}},   {  7,{73,45,14},  3,{74,46,14}},   { 15,{43,19,12},  2,{44,20,12}},   {  3, {45,15,15}, 13,{46,16,15}}},
	{{  1,{135,107,14},  5,{136,108,14}},   { 10,{74,46,14},  1,{75,47,14}},   {  1,{50,22,14}, 15,{51,23,14}},   {  2, {42,14,14}, 17,{43,15,14}}},
	{{  5,{150,120,15},  1,{151,121,15}},   {  9,{69,43,13},  4,{70,44,13}},   { 17,{50,22,14},  1,{51,23,14}},   {  2, {42,14,14}, 19,{43,15,14}}},
	{{  3,{141,113,14},  4,{142,114,14}},   {  3,{70,44,13}, 11,{71,45,13}},   { 17,{47,21,13},  4,{48,22,13}},   {  9, {39,13,13}, 16,{40,14,13}}},
	{{  3,{135,107,14},  5,{136,108,14}},   {  3,{67,41,13}, 13,{68,42,13}},   { 15,{54,24,15},  5,{55,25,15}},   { 15, {43,15,14}, 10,{44,16,14}}},
	{{  4,{144,116,14},  4,{145,117,14}},   { 17,{68,42,13}},                  { 17,{50,22,14},  6,{51,23,14}},   { 19, {46,16,15},  6,{47,17,15}}},
	{{  2,{139,111,14},  7,{140,112,14}},   { 17,{74,46,14}},                  {  7,{54,24,15}, 16,{55,25,15}},   { 34, {37,13,12}               }},
	{{  4,{151,121,15},  5,{152,122,15}},   {  4,{75,47,14}, 14,{76,48,14}},   { 11,{54,24,15}, 14,{55,25,15}},   { 16, {45,15,15}, 14,{46,16,15}}},
	{{  6,{147,117,15},  4,{148,118,15}},   {  6,{73,45,14}, 14,{74,46,14}},   { 11,{54,24,15}, 16,{55,25,15}},   { 30, {46,16,15},  2,{47,17,15}}},
	{{  8,{132,106,13},  4,{133,107,13}},   {  8,{75,47,14}, 13,{76,48,14}},   {  7,{54,24,15}, 22,{55,25,15}},   { 22, {45,15,15}, 13,{46,16,15}}},
	{{ 10,{142,114,14},  2,{143,115,14}},   { 19,{74,46,14},  4,{75,47,14}},   { 28,{50,22,14},  6,{51,23,14}},   { 33, {46,16,15},  4,{47,17,15}}},
	{{  8,{152,122,15},  4,{153,123,15}},   { 22,{73,45,14},  3,{74,46,14}},   {  8,{53,23,15}, 26,{54,24,15}},   { 12, {45,15,15}, 28,{46,16,15}}},
	{{  3,{147,117,15}, 10,{148,118,15}},   {  3,{73,45,14}, 23,{74,46,14}},   {  4,{54,24,15}, 31,{55,25,15}},   { 11, {45,15,15}, 31,{46,16,15}}},
	{{  7,{146,116,15},  7,{147,117,15}},   { 21,{73,45,14},  7,{74,46,14}},   {  1,{53,23,15}, 37,{54,24,15}},   { 19, {45,15,15}, 26,{46,16,15}}},
	{{  5,{145,115,15}, 10,{146,116,15}},   { 19,{75,47,14}, 10,{76,48,14}},   { 15,{54,24,15}, 25,{55,25,15}},   { 23, {45,15,15}, 25,{46,16,15}}},
	{{ 13,{145,115,15},  3,{146,116,15}},   {  2,{74,46,14}, 29,{75,47,14}},   { 42,{54,24,15},  1,{55,25,15}},   { 23, {45,15,15}, 28,{46,16,15}}},
	{{ 17,{145,115,15}            	 },   { 10,{74,46,14}, 23,{75,47,14}},   { 10,{54,24,15}, 35,{55,25,15}},   { 19, {45,15,15}, 35,{46,16,15}}},
	{{ 17,{145,115,15},  1,{146,116,15}},   { 14,{74,46,14}, 21,{75,47,14}},   { 29,{54,24,15}, 19,{55,25,15}},   { 11, {45,15,15}, 46,{46,16,15}}},
	{{ 13,{145,115,15},  6,{146,116,15}},   { 14,{74,46,14}, 23,{75,47,14}},   { 44,{54,24,15},  7,{55,25,15}},   { 59, {46,16,15},  1,{47,17,15}}},
	{{ 12,{151,121,15},  7,{152,122,15}},   { 12,{75,47,14}, 26,{76,48,14}},   { 39,{54,24,15}, 14,{55,25,15}},   { 22, {45,15,15}, 41,{46,16,15}}},
	{{  6,{151,121,15}, 14,{152,122,15}},   {  6,{75,47,14}, 34,{76,48,14}},   { 46,{54,24,15}, 10,{55,25,15}},   {  2, {45,15,15}, 64,{46,16,15}}},
	{{ 17,{152,122,15},  4,{153,123,15}},   { 29,{74,46,14}, 14,{75,47,14}},   { 49,{54,24,15}, 10,{55,25,15}},   { 24, {45,15,15}, 46,{46,16,15}}},
	{{  4,{152,122,15}, 18,{153,123,15}},   { 13,{74,46,14}, 32,{75,47,14}},   { 48,{54,24,15}, 14,{55,25,15}},   { 42, {45,15,15}, 32,{46,16,15}}},
	{{ 20,{147,117,15},  4,{148,118,15}},   { 40,{75,47,14},  7,{76,48,14}},   { 43,{54,24,15}, 22,{55,25,15}},   { 10, {45,15,15}, 67,{46,16,15}}},
	{{ 19,{148,118,15},  6,{149,119,15}},   { 18,{75,47,14}, 31,{76,48,14}},   { 34,{54,24,15}, 34,{55,25,15}},   { 20, {45,15,15}, 61,{46,16,15}}}
}

local typeinfo = {
	{ [-1]= "111111111111111", [0] = "111011111000100", "111001011110011", "111110110101010", "111100010011101", "110011000101111", "110001100011000", "110110001000001", "110100101110110" },
	{ [-1]= "111111111111111", [0] = "101010000010010", "101000100100101", "101111001111100", "101101101001011", "100010111111001", "100000011001110", "100111110010111", "100101010100000" },
	{ [-1]= "111111111111111", [0] = "011010101011111", "011000001101000", "011111100110001", "011101000000110", "010010010110100", "010000110000011", "010111011011010", "010101111101101" },
	{ [-1]= "111111111111111", [0] = "001011010001001", "001001110111110", "001110011100111", "001100111010000", "000011101100010", "000001001010101", "000110100001100", "000100000111011" }
}

-- Mask functions
local maskFunc = {
	[0] = function(x,y) return (y+x)%2==0 end,
	[1] = function(x,y) return y%2==0 end,
	[2] = function(x,y) return x%3==0 end,
	[3] = function(x,y) return (y+x)%3==0 end,
	[4] = function(x,y) return (y%4-1.5)*(x%6-2.5)>0 end,
	[5] = function(x,y) return (y*x)%2+(y*x)%3==0 end,
	[6] = function(x,y) return ((y*x)%3+y*x)%2==0 end,
	[7] = function(x,y) return ((y*x)%3+y+x)%2==0 end,
}

-- GF(256) Math
local function gf_add(x, y)
	return bit32.bxor(x, y)
end

local function gf_mul(x, y)
	if x == 0 or y == 0 then return 0 end
	return alpha_int[(int_alpha[x] + int_alpha[y]) % 255]
end

local function gf_div(x, y)
	if y == 0 then error("GF(256) division by zero") end
	if x == 0 then return 0 end
	return alpha_int[(int_alpha[x] - int_alpha[y] + 255) % 255]
end

local function eval_poly(poly, x)
	local val = 0
	for i = 1, #poly do
		val = gf_add(gf_mul(val, x), poly[i])
	end
	return val
end

local function eval_poly_lowest_first(poly, x)
	local val = 0
	local xp = 1
	for i = 1, #poly do
		val = gf_add(val, gf_mul(poly[i] or 0, xp))
		xp = gf_mul(xp, x)
	end
	return val
end

-- Reed-Solomon Error Correction Decoder
local function calc_syndromes(msg, n_ec)
	local syndromes = {}
	local has_errors = false
	for i = 0, n_ec - 1 do
		local eval = eval_poly(msg, alpha_int[i])
		table.insert(syndromes, eval)
		if eval ~= 0 then
			has_errors = true
		end
	end
	return syndromes, has_errors
end

local function find_error_locator(syndromes)
	local C = {1}
	local B = {1}
	local L = 0
	local m = 1
	local b = 1
	for r = 1, #syndromes do
		local d = syndromes[r]
		for i = 1, L do
			if C[i + 1] and syndromes[r - i] then
				d = gf_add(d, gf_mul(C[i + 1], syndromes[r - i]))
			end
		end
		if d == 0 then
			m = m + 1
		else
			local T = {}
			for i = 1, #C do T[i] = C[i] end
			local scale = gf_div(d, b)
			for i = 1, #B do
				local idx = i + m
				C[idx] = gf_add(C[idx] or 0, gf_mul(scale, B[i]))
			end
			if 2 * L <= r - 1 then
				L = r - L
				B = T
				b = d
				m = 1
			else
				m = m + 1
			end
		end
	end
	return C
end

local function chien_search(C, n)
	local error_locs = {}
	for i = 0, n - 1 do
		local inv_x = alpha_int[(255 - i) % 255]
		local val = eval_poly_lowest_first(C, inv_x)
		if val == 0 then
			table.insert(error_locs, i)
		end
	end
	return error_locs
end

local function find_error_evaluator(syndromes, C, n_ec)
	local Omega = {}
	for i = 1, n_ec do
		local val = 0
		for j = 1, i do
			local s = syndromes[i - j + 1] or 0
			local c = C[j] or 0
			val = gf_add(val, gf_mul(s, c))
		end
		Omega[i] = val
	end
	return Omega
end

local function poly_deriv_lowest_first(poly)
	local deriv = {}
	for i = 2, #poly, 2 do
		deriv[i - 1] = poly[i]
	end
	return deriv
end

local function correct_errors(msg, n_ec)
	local syndromes, has_errors = calc_syndromes(msg, n_ec)
	if not has_errors then return msg, true end
	
	local C = find_error_locator(syndromes)
	local err_locs = chien_search(C, #msg)
	
	if #err_locs == 0 or #err_locs > n_ec / 2 then
		return msg, false -- Too many errors to correct
	end
	
	local Omega = find_error_evaluator(syndromes, C, n_ec)
	local deriv = poly_deriv_lowest_first(C)
	
	for _, loc in ipairs(err_locs) do
		local inv_X = alpha_int[(255 - loc) % 255]
		local Omega_val = eval_poly_lowest_first(Omega, inv_X)
		local deriv_val = eval_poly_lowest_first(deriv, inv_X)
		if deriv_val == 0 then return msg, false end
		
		local X = alpha_int[loc]
		local err_val = gf_mul(gf_div(Omega_val, deriv_val), X)
		local msg_idx = #msg - loc
		if msg_idx >= 1 and msg_idx <= #msg then
			msg[msg_idx] = gf_add(msg[msg_idx], err_val)
		end
	end
	
	return msg, true
end

-- QR Matrix Geometry Utilities
local function is_function_module(version, col, row, size)
	-- Finder patterns + separators (8x8 regions at corners)
	if col <= 8 and row <= 8 then return true end
	if col >= size - 7 and row <= 8 then return true end
	if col <= 8 and row >= size - 7 then return true end

	-- Timing patterns
	if col == 7 or row == 7 then return true end

	-- Dark module
	if col == 9 and row == 4 * version + 10 then return true end

	-- Alignment patterns
	if version >= 2 then
		local ap = alignment_pattern[version]
		for x = 1, #ap do
			for y = 1, #ap do
				if not (x == 1 and y == 1 or x == #ap and y == 1 or x == 1 and y == #ap) then
					local ap_col = ap[x] + 1
					local ap_row = ap[y] + 1
					if col >= ap_col - 2 and col <= ap_col + 2 and
					   row >= ap_row - 2 and row <= ap_row + 2 then
						return true
					end
				end
			end
		end
	end

	-- Version information
	if version >= 7 then
		if col >= size - 10 and col <= size - 8 and row >= 1 and row <= 6 then return true end
		if col >= 1 and col <= 6 and row >= size - 10 and row <= size - 8 then return true end
	end

	-- Format information
	if col == 9 and row <= 9 then return true end
	if row == 9 and col <= 9 then return true end
	if col == 9 and row >= size - 7 then return true end
	if row == 9 and col >= size - 7 then return true end

	return false
end

local function decode_format_info(format_str)
	local best_match = nil
	local min_dist = 999
	for ec = 1, 4 do
		for mask = 0, 7 do
			local ref_str = typeinfo[ec][mask]
			local dist = 0
			for i = 1, 15 do
				if format_str:sub(i, i) ~= ref_str:sub(i, i) then
					dist = dist + 1
				end
			end
			if dist < min_dist then
				min_dist = dist
				best_match = {ec_level = ec, mask = mask}
			end
		end
	end
	return best_match, min_dist
end

-- Zigzag Scanner and Unmasker
local function read_bitstream(matrix, version, mask_pattern)
	local size = #matrix
	local bits = {}
	local col = size
	local moving_up = true
	
	while col > 0 do
		if col == 7 then col = col - 1 end
		
		local row_start = moving_up and size or 1
		local row_end = moving_up and 1 or size
		local step = moving_up and -1 or 1
		
		for row = row_start, row_end, step do
			for c = 0, 1 do
				local curr_col = col - c
				if curr_col > 0 then
					if not is_function_module(version, curr_col, row, size) then
						local bit_val = matrix[curr_col][row]
						local invert = maskFunc[mask_pattern](curr_col - 1, row - 1)
						if invert then
							bit_val = (bit_val == 0) and 1 or 0
						end
						table.insert(bits, bit_val)
					end
				end
			end
		end
		col = col - 2
		moving_up = not moving_up
	end
	return bits
end

local function bits_to_bytes(bits)
	local bytes = {}
	for i = 1, #bits, 8 do
		local b = 0
		for j = 0, 7 do
			local bit = bits[i + j] or 0
			b = b + bit * 2^(7 - j)
		end
		table.insert(bytes, b)
	end
	return bytes
end

local function deinterleave(codewords, version, ec_level)
	local blocks = ecblocks[version][ec_level]
	local block_structs = {}
	for i = 1, #blocks / 2 do
		local count = blocks[2*i - 1]
		local total_len = blocks[2*i][1]
		local data_len = blocks[2*i][2]
		local ec_len = total_len - data_len
		for _ = 1, count do
			table.insert(block_structs, {
				total_len = total_len,
				data_len = data_len,
				ec_len = ec_len,
				data = {},
				ec = {},
				codewords = {}
			})
		end
	end
	
	local ptr = 1
	local max_data_len = 0
	for _, blk in ipairs(block_structs) do
		max_data_len = math.max(max_data_len, blk.data_len)
	end
	for p = 1, max_data_len do
		for _, blk in ipairs(block_structs) do
			if p <= blk.data_len then
				blk.data[p] = codewords[ptr] or 0
				ptr = ptr + 1
			end
		end
	end
	
	local max_ec_len = 0
	for _, blk in ipairs(block_structs) do
		max_ec_len = math.max(max_ec_len, blk.ec_len)
	end
	for p = 1, max_ec_len do
		for _, blk in ipairs(block_structs) do
			if p <= blk.ec_len then
				blk.ec[p] = codewords[ptr] or 0
				ptr = ptr + 1
			end
		end
	end
	
	for _, blk in ipairs(block_structs) do
		for i = 1, blk.data_len do
			table.insert(blk.codewords, blk.data[i])
		end
		for i = 1, blk.ec_len do
			table.insert(blk.codewords, blk.ec[i])
		end
	end
	
	return block_structs
end

-- Bitstream Readers and Mode Decoders
local function get_char_count_bits(version, mode)
	if version >= 1 and version <= 9 then
		if mode == 1 then return 10
		elseif mode == 2 then return 9
		elseif mode == 4 then return 8
		end
	elseif version >= 10 and version <= 26 then
		if mode == 1 then return 12
		elseif mode == 2 then return 11
		elseif mode == 4 then return 16
		end
	elseif version >= 27 and version <= 40 then
		if mode == 1 then return 14
		elseif mode == 2 then return 13
		elseif mode == 4 then return 16
		end
	end
	return 8
end

local ALPHANUM_CHARS = {}
local alphanum_str = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:"
for i = 1, #alphanum_str do
	ALPHANUM_CHARS[i - 1] = alphanum_str:sub(i, i)
end

local function decode_bits(data_bits, version)
	local bit_ptr = 1
	local function read_bits(n)
		if bit_ptr + n - 1 > #data_bits then return nil end
		local val = 0
		for i = 0, n - 1 do
			val = val + data_bits[bit_ptr + i] * 2^(n - 1 - i)
		end
		bit_ptr = bit_ptr + n
		return val
	end

	local result = ""
	while true do
		local mode = read_bits(4)
		if not mode or mode == 0 then break end -- End of message or no more bits

		local char_count_bits = get_char_count_bits(version, mode)
		local count = read_bits(char_count_bits)
		if not count then break end

		if mode == 4 then -- Byte Mode
			local bytes = {}
			for _ = 1, count do
				local val = read_bits(8)
				if not val then break end
				table.insert(bytes, string.char(val))
			end
			result = result .. table.concat(bytes)
		elseif mode == 2 then -- Alphanumeric Mode
			local i = 1
			while i <= count - 1 do
				local val = read_bits(11)
				if not val then break end
				local char1_val = math.floor(val / 45)
				local char2_val = val % 45
				result = result .. (ALPHANUM_CHARS[char1_val] or "") .. (ALPHANUM_CHARS[char2_val] or "")
				i = i + 2
			end
			if i == count then
				local val = read_bits(6)
				if val then
					result = result .. (ALPHANUM_CHARS[val] or "")
				end
			end
		elseif mode == 1 then -- Numeric Mode
			local i = 1
			while i <= count - 2 do
				local val = read_bits(10)
				if not val then break end
				result = result .. string.format("%03d", val)
				i = i + 3
			end
			if count - i == 1 then
				local val = read_bits(7)
				if val then
					result = result .. string.format("%02d", val)
				end
			elseif count - i == 0 then
				local val = read_bits(4)
				if val then
					result = result .. string.format("%01d", val)
				end
			end
		else
			-- Unsupported mode, try to continue or break
			break
		end
	end
	return result
end

-- Checker for Finder Patterns
local function check_finder_pattern(tab, ox, oy)
	local N = #tab
	if ox < 1 or ox + 6 > N or oy < 1 or oy + 6 > N then return false end
	
	-- Outer border (must be 1)
	for dx = 0, 6 do
		if tab[ox + dx][oy] == 0 or tab[ox + dx][oy + 6] == 0 or
		   tab[ox][oy + dx] == 0 or tab[ox + 6][oy + dx] == 0 then
			return false
		end
	end
	
	-- Inner ring (must be 0)
	for dx = 1, 5 do
		if tab[ox + dx][oy + 1] == 1 or tab[ox + dx][oy + 5] == 1 or
		   tab[ox + 1][oy + dx] == 1 or tab[ox + 5][oy + dx] == 1 then
			return false
		end
	end
	
	-- Center (must be 1)
	for dy = 2, 4 do
		for dx = 2, 4 do
			if tab[ox + dx][oy + dy] == 0 then
				return false
			end
		end
	end
	
	return true
end

-- Extract format info from a canonical matrix
local function extract_format_info(tab)
	local N = #tab
	
	-- Read path 1 (top-left)
	local p1 = {}
	-- f0..f5
	for r = 1, 6 do table.insert(p1, tab[9][r]) end
	-- f6
	table.insert(p1, tab[9][8])
	-- f7
	table.insert(p1, tab[9][9])
	-- f8
	table.insert(p1, tab[8][9])
	-- f9
	table.insert(p1, tab[6][9])
	-- f10..f14
	for c = 5, 1, -1 do table.insert(p1, tab[c][9]) end
	
	-- Format is stored f14..f0 in path, so we reverse it to construct format_str
	local f_str = ""
	for i = 15, 1, -1 do
		f_str = f_str .. tostring(p1[i])
	end
	
	local match, dist = decode_format_info(f_str)
	if match and dist <= 3 then
		return match.ec_level, match.mask
	end
	
	-- Fallback to path 2 (top-right / bottom-left)
	local p2 = {}
	-- f0..f7 from bottom-left column 9
	for r = N, N - 7, -1 do table.insert(p2, tab[9][r]) end
	-- f8..f14 from top-right row 9
	for c = N - 7, N do table.insert(p2, tab[c][9]) end
	
	local f_str2 = ""
	for i = 15, 1, -1 do
		f_str2 = f_str2 .. tostring(p2[i])
	end
	
	local match2, dist2 = decode_format_info(f_str2)
	if match2 and dist2 <= 3 then
		return match2.ec_level, match2.mask
	end
	
	-- Return best guess between both paths
	if not match then return 1, 0 end
	if not match2 then return match.ec_level, match.mask end
	return dist <= dist2 and match.ec_level or match2.ec_level, dist <= dist2 and match.mask or match2.mask
end

-- Decodes a matrix where 1 = foreground, 0 = background
function qrdecode.decode_matrix(tab)
	local N = #tab
	local version = (N - 17) / 4
	if version < 1 or version > 40 or version % 1 ~= 0 then
		return false, "Invalid grid size for a QR code"
	end
	
	local ec_level, mask = extract_format_info(tab)
	local raw_bits = read_bitstream(tab, version, mask)
	local raw_codewords = bits_to_bytes(raw_bits)
	
	-- Look up expected block count and total sizes
	local blocks = ecblocks[version][ec_level]
	local expected_codewords = 0
	for i = 1, #blocks / 2 do
		expected_codewords = expected_codewords + blocks[2*i - 1] * blocks[2*i][1]
	end
	
	-- Deinterleave codewords into blocks
	local block_structs = deinterleave(raw_codewords, version, ec_level)
	local clean_data_bits = {}
	
	for _, blk in ipairs(block_structs) do
		local corrected, success = correct_errors(blk.codewords, blk.ec_len)
		if not success then
			return false, "Reed-Solomon error correction failed"
		end
		-- Collect clean data bits from corrected codewords
		for i = 1, blk.data_len do
			local byte_val = corrected[i] or 0
			for bit_pos = 7, 0, -1 do
				local bit_val = bit32.band(bit32.rshift(byte_val, bit_pos), 1)
				table.insert(clean_data_bits, bit_val)
			end
		end
	end
	
	local ok, decoded_text = pcall(decode_bits, clean_data_bits, version)
	if not ok then
		return false, "Failed to parse data bits: " .. tostring(decoded_text)
	end
	return true, decoded_text
end

-- Main entry point. Exposes grid scanning and auto-detection.
-- possible_fg_values is a list of grid values that represent foreground (everything else is background)
function qrdecode.decode(grid, possible_fg_values)
	local unique_vals = {}
	if possible_fg_values then
		for _, v in ipairs(possible_fg_values) do
			unique_vals[v] = true
		end
	else
		-- Find unique non-nil/non-empty values in grid
		for _, col in pairs(grid) do
			for _, val in pairs(col) do
				if val and val ~= "" then
					unique_vals[val] = true
				end
			end
		end
	end
	
	-- Try each value as the foreground candidate
	for fg_val, _ in pairs(unique_vals) do
		-- Find bounding box of fg_val
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
			
			-- Try scales 1..8
			for S = 1, 8 do
				local N = math.floor(max_len / S + 0.5)
				if N >= 21 and N <= 177 and (N - 17) % 4 == 0 then
					-- Construct matrix for S and N
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
					
					-- Check finder patterns at corners
					local has_tl = check_finder_pattern(tab, 1, 1)
					local has_tr = check_finder_pattern(tab, N - 6, 1)
					local has_bl = check_finder_pattern(tab, 1, N - 6)
					local has_br = check_finder_pattern(tab, N - 6, N - 6)
					
					local active_count = (has_tl and 1 or 0) + (has_tr and 1 or 0) + (has_bl and 1 or 0) + (has_br and 1 or 0)
					if active_count == 3 then
						-- Found valid QR code matrix! Determine rotation and align to TL, TR, BL
						local aligned_tab = {}
						for i = 1, N do aligned_tab[i] = {} end
						
						if has_tl and has_tr and has_bl then
							-- 0 degrees (canonical)
							aligned_tab = tab
						elseif has_tr and has_br and has_tl then
							-- 90 degrees clockwise (TR, BR, TL) -> needs 90 deg CCW rotation to align
							for i = 1, N do
								for j = 1, N do
									aligned_tab[i][j] = tab[N - j + 1][i]
								end
							end
						elseif has_br and has_bl and has_tr then
							-- 180 degrees (BR, BL, TR) -> needs 180 deg rotation
							for i = 1, N do
								for j = 1, N do
									aligned_tab[i][j] = tab[N - i + 1][N - j + 1]
								end
							end
						elseif has_bl and has_tl and has_br then
							-- 270 degrees clockwise (BL, TL, BR) -> needs 90 deg CW rotation to align
							for i = 1, N do
								for j = 1, N do
									aligned_tab[i][j] = tab[j][N - i + 1]
								end
							end
						end
						
						-- Run decoder
						local ok, text = qrdecode.decode_matrix(aligned_tab)
						if ok then
							return true, text
						end
					end
				end
			end
		end
	end
	
	return false, "No valid QR code finder patterns detected in selection"
end

return qrdecode
