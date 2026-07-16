local azteccommon = {}

-- Table mapping (size, compact) -> parameters
-- For ease of lookup in Lua, we index by a string key like "size_compact" (e.g. "15_true")
-- where compact is "true" or "false"
azteccommon.table = {
	["15_true"] = {layers = 1, codewords = 17, cw_bits = 6, bits = 102, digits = 13, text = 12, bytes = 6, size = 15, compact = true},
	["19_false"] = {layers = 1, codewords = 21, cw_bits = 6, bits = 126, digits = 18, text = 15, bytes = 8, size = 19, compact = false},
	["19_true"] = {layers = 2, codewords = 40, cw_bits = 6, bits = 240, digits = 40, text = 33, bytes = 19, size = 19, compact = true},
	["23_false"] = {layers = 2, codewords = 48, cw_bits = 6, bits = 288, digits = 49, text = 40, bytes = 24, size = 23, compact = false},
	["23_true"] = {layers = 3, codewords = 51, cw_bits = 8, bits = 408, digits = 70, text = 57, bytes = 33, size = 23, compact = true},
	["27_false"] = {layers = 3, codewords = 60, cw_bits = 8, bits = 480, digits = 84, text = 68, bytes = 40, size = 27, compact = false},
	["27_true"] = {layers = 4, codewords = 76, cw_bits = 8, bits = 608, digits = 110, text = 89, bytes = 53, size = 27, compact = true},
	["31_false"] = {layers = 4, codewords = 88, cw_bits = 8, bits = 704, digits = 128, text = 104, bytes = 62, size = 31, compact = false},
	["37_false"] = {layers = 5, codewords = 120, cw_bits = 8, bits = 960, digits = 178, text = 144, bytes = 87, size = 37, compact = false},
	["41_false"] = {layers = 6, codewords = 156, cw_bits = 8, bits = 1248, digits = 232, text = 187, bytes = 114, size = 41, compact = false},
	["45_false"] = {layers = 7, codewords = 196, cw_bits = 8, bits = 1568, digits = 294, text = 236, bytes = 145, size = 45, compact = false},
	["49_false"] = {layers = 8, codewords = 240, cw_bits = 8, bits = 1920, digits = 362, text = 291, bytes = 179, size = 49, compact = false},
	["53_false"] = {layers = 9, codewords = 230, cw_bits = 10, bits = 2300, digits = 433, text = 348, bytes = 214, size = 53, compact = false},
	["57_false"] = {layers = 10, codewords = 272, cw_bits = 10, bits = 2720, digits = 516, text = 414, bytes = 256, size = 57, compact = false},
	["61_false"] = {layers = 11, codewords = 316, cw_bits = 10, bits = 3160, digits = 601, text = 482, bytes = 298, size = 61, compact = false},
	["67_false"] = {layers = 12, codewords = 364, cw_bits = 10, bits = 3640, digits = 691, text = 554, bytes = 343, size = 67, compact = false},
	["71_false"] = {layers = 13, codewords = 416, cw_bits = 10, bits = 4160, digits = 793, text = 636, bytes = 394, size = 71, compact = false},
	["75_false"] = {layers = 14, codewords = 470, cw_bits = 10, bits = 4700, digits = 896, text = 718, bytes = 446, size = 75, compact = false},
	["79_false"] = {layers = 15, codewords = 528, cw_bits = 10, bits = 5280, digits = 1008, text = 808, bytes = 502, size = 79, compact = false},
	["83_false"] = {layers = 16, codewords = 588, cw_bits = 10, bits = 5880, digits = 1123, text = 900, bytes = 559, size = 83, compact = false},
	["87_false"] = {layers = 17, codewords = 652, cw_bits = 10, bits = 6520, digits = 1246, text = 998, bytes = 621, size = 87, compact = false},
	["91_false"] = {layers = 18, codewords = 720, cw_bits = 10, bits = 7200, digits = 1378, text = 1104, bytes = 687, size = 91, compact = false},
	["95_false"] = {layers = 19, codewords = 790, cw_bits = 10, bits = 7900, digits = 1511, text = 1210, bytes = 753, size = 95, compact = false},
	["101_false"] = {layers = 20, codewords = 864, cw_bits = 10, bits = 8640, digits = 1653, text = 1324, bytes = 824, size = 101, compact = false},
	["105_false"] = {layers = 21, codewords = 940, cw_bits = 10, bits = 9400, digits = 1801, text = 1442, bytes = 898, size = 105, compact = false},
	["109_false"] = {layers = 22, codewords = 1020, cw_bits = 10, bits = 10200, digits = 1956, text = 1566, bytes = 976, size = 109, compact = false},
	["113_false"] = {layers = 23, codewords = 920, cw_bits = 12, bits = 11040, digits = 2116, text = 1694, bytes = 1056, size = 113, compact = false},
	["117_false"] = {layers = 24, codewords = 992, cw_bits = 12, bits = 11904, digits = 2281, text = 1826, bytes = 1138, size = 117, compact = false},
	["121_false"] = {layers = 25, codewords = 1066, cw_bits = 12, bits = 12792, digits = 2452, text = 1963, bytes = 1224, size = 121, compact = false},
	["125_false"] = {layers = 26, codewords = 1144, cw_bits = 12, bits = 13728, digits = 2632, text = 2107, bytes = 1314, size = 125, compact = false},
	["131_false"] = {layers = 27, codewords = 1224, cw_bits = 12, bits = 14688, digits = 2818, text = 2256, bytes = 1407, size = 131, compact = false},
	["135_false"] = {layers = 28, codewords = 1306, cw_bits = 12, bits = 15672, digits = 3007, text = 2407, bytes = 1501, size = 135, compact = false},
	["139_false"] = {layers = 29, codewords = 1392, cw_bits = 12, bits = 16704, digits = 3205, text = 2565, bytes = 1600, size = 139, compact = false},
	["143_false"] = {layers = 30, codewords = 1480, cw_bits = 12, bits = 17760, digits = 3409, text = 2728, bytes = 1702, size = 143, compact = false},
	["147_false"] = {layers = 31, codewords = 1570, cw_bits = 12, bits = 18840, digits = 3616, text = 2894, bytes = 1806, size = 147, compact = false},
	["151_false"] = {layers = 32, codewords = 1664, cw_bits = 12, bits = 19968, digits = 3832, text = 3067, bytes = 1914, size = 151, compact = false}
}

azteccommon.polynomials = {
	[4] = 19,
	[6] = 67,
	[8] = 301,
	[10] = 1033,
	[12] = 4201
}

azteccommon.code_chars = {
	upper = {
		"P/S", " ", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S",
		"T", "U", "V", "W", "X", "Y", "Z", "L/L", "M/L", "D/L", "B/S"
	},
	lower = {
		"P/S", " ", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s",
		"t", "u", "v", "w", "x", "y", "z", "U/S", "M/L", "D/L", "B/S"
	},
	mixed = {
		"P/S", " ", "\x01", "\x02", "\x03", "\x04", "\x05", "\x06", "\x07", "\x08", "\t", "\n", "\x0b", "\x0c", "\r",
		"\x1b", "\x1c", "\x1d", "\x1e", "\x1f", "@", "\\", "^", "_", "`", "|", "~", "\x7f", "L/L", "U/L", "P/L", "B/S"
	},
	punct = {
		"FLG(n)", "\r", "\r\n", ". ", ", ", ": ", "!", '"', "#", "$", "%", "&", "'", "(", ")", "*", "+", ",", "-", ".",
		"/", ":", ";", "<", "=", ">", "?", "[", "]", "{", "}", "U/L"
	},
	digit = {
		"P/S", " ", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ",", ".", "U/L", "U/S"
	}
}

-- Create quick lookup tables
local function slice_table(t, start_idx, end_idx)
	local res = {}
	for i = start_idx, #t + end_idx do
		res[i - start_idx + 1] = t[i]
	end
	return res
end

azteccommon.upper_chars = slice_table(azteccommon.code_chars.upper, 2, -4)
azteccommon.lower_chars = slice_table(azteccommon.code_chars.lower, 2, -4)
azteccommon.mixed_chars = slice_table(azteccommon.code_chars.mixed, 2, -4)
azteccommon.punct_chars = slice_table(azteccommon.code_chars.punct, 2, -1)
azteccommon.digit_chars = slice_table(azteccommon.code_chars.digit, 2, -2)

azteccommon.punct_2_chars = {}
for _, v in ipairs(azteccommon.punct_chars) do
	if #v == 2 then
		table.insert(azteccommon.punct_2_chars, v)
	end
end

azteccommon.E = 99999

azteccommon.latch_len = {
	upper = { upper = 0, lower = 5, mixed = 5, punct = 10, digit = 5, binary = 10 },
	lower = { upper = 10, lower = 0, mixed = 5, punct = 10, digit = 5, binary = 10 },
	mixed = { upper = 5, lower = 5, mixed = 0, punct = 5, digit = 10, binary = 10 },
	punct = { upper = 5, lower = 10, mixed = 10, punct = 0, digit = 10, binary = 15 },
	digit = { upper = 4, lower = 9, mixed = 9, punct = 14, digit = 0, binary = 14 },
	binary = { upper = 0, lower = 0, mixed = 0, punct = 0, digit = 0, binary = 0 }
}

azteccommon.shift_len = {
	upper = { upper = azteccommon.E, lower = azteccommon.E, mixed = azteccommon.E, punct = 5, digit = azteccommon.E, binary = azteccommon.E },
	lower = { upper = 5, lower = azteccommon.E, mixed = azteccommon.E, punct = 5, digit = azteccommon.E, binary = azteccommon.E },
	mixed = { upper = azteccommon.E, lower = azteccommon.E, mixed = azteccommon.E, punct = 5, digit = azteccommon.E, binary = azteccommon.E },
	punct = { upper = azteccommon.E, lower = azteccommon.E, mixed = azteccommon.E, punct = azteccommon.E, digit = azteccommon.E, binary = azteccommon.E },
	digit = { upper = 4, lower = azteccommon.E, mixed = azteccommon.E, punct = 4, digit = azteccommon.E, binary = azteccommon.E },
	binary = { upper = azteccommon.E, lower = azteccommon.E, mixed = azteccommon.E, punct = azteccommon.E, digit = azteccommon.E, binary = azteccommon.E }
}

azteccommon.char_size = {
	upper = 5, lower = 5, mixed = 5, punct = 5, digit = 4, binary = 8
}

azteccommon.modes = { "upper", "lower", "mixed", "punct", "digit", "binary" }

azteccommon.abbr_modes = {
	U = "upper", L = "lower", M = "mixed", P = "punct", D = "digit", B = "binary"
}

-- Galois Field 2^m arithmetic helper
function azteccommon.get_gf(gf, pp)
	local log = {}
	local alog = {}
	log[0] = 1 - gf
	alog[0] = 1
	for i = 1, gf - 1 do
		local val = alog[i - 1] * 2
		if val >= gf then
			val = bit32.bxor(val, pp)
		end
		alog[i] = val
		log[val] = i
	end

	local function gf_add(a, b)
		return bit32.bxor(a, b)
	end

	local function gf_mul(a, b)
		if a == 0 or b == 0 then return 0 end
		return alog[(log[a] + log[b]) % (gf - 1)]
	end

	local function gf_div(a, b)
		if b == 0 then error("Division by zero in GF") end
		if a == 0 then return 0 end
		return alog[(log[a] - log[b] + (gf - 1)) % (gf - 1)]
	end

	return {
		gf = gf,
		pp = pp,
		log = log,
		alog = alog,
		add = gf_add,
		mul = gf_mul,
		div = gf_div
	}
end

-- Reed-Solomon Encoder
function azteccommon.reed_solomon(wd, nd, nc, gf_order, pp)
	local gf = azteccommon.get_gf(gf_order, pp)
	
	-- generate polynomial coefficients
	local c = {}
	c[0] = 1
	for i = 1, nc do
		c[i] = 0
	end
	for i = 1, nc do
		c[i] = c[i - 1]
		for j = i - 1, 1, -1 do
			c[j] = bit32.bxor(c[j - 1], gf.mul(c[j], gf.alog[i]))
		end
		c[0] = gf.mul(c[0], gf.alog[i])
	end
	
	-- generate codewords
	for i = nd, nd + nc - 1 do
		wd[i + 1] = 0
	end
	for i = 0, nd - 1 do
		local k = bit32.bxor(wd[nd + 1], wd[i + 1])
		for j = 0, nc - 1 do
			wd[nd + j + 1] = gf.mul(k, c[nc - j - 1])
			if j < nc - 1 then
				wd[nd + j + 1] = bit32.bxor(wd[nd + j + 1], wd[nd + j + 2])
			end
		end
	end
end

-- Polynomial evaluation utilities
local function eval_poly(gf, poly, x)
	local val = 0
	for i = 1, #poly do
		val = gf.add(gf.mul(val, x), poly[i])
	end
	return val
end

local function eval_poly_lowest_first(gf, poly, x)
	local val = 0
	local xp = 1
	for i = 1, #poly do
		val = gf.add(val, gf.mul(poly[i] or 0, xp))
		xp = gf.mul(xp, x)
	end
	return val
end

-- Reed-Solomon Decoder/Error Corrector
function azteccommon.correct_errors(msg, n_ec, gf_order, pp)
	local gf = azteccommon.get_gf(gf_order, pp)
	
	-- calculate syndromes
	local syndromes = {}
	local has_errors = false
	for i = 1, n_ec do
		local eval = eval_poly(gf, msg, gf.alog[i])
		table.insert(syndromes, eval)
		if eval ~= 0 then
			has_errors = true
		end
	end
	
	if not has_errors then return msg, true end
	
	-- Find error locator polynomial using Berlekamp-Massey
	local C = {1}
	local B = {1}
	local L = 0
	local m = 1
	local b = 1
	for r = 1, #syndromes do
		local d = syndromes[r]
		for i = 1, L do
			if C[i + 1] and syndromes[r - i] then
				d = gf.add(d, gf.mul(C[i + 1], syndromes[r - i]))
			end
		end
		if d == 0 then
			m = m + 1
		else
			local T = {}
			for i = 1, #C do T[i] = C[i] end
			local scale = gf.div(d, b)
			for i = 1, #B do
				local idx = i + m
				C[idx] = gf.add(C[idx] or 0, gf.mul(scale, B[i]))
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
	
	-- Chien search
	local err_locs = {}
	local n = #msg
	for i = 0, n - 1 do
		local inv_x = gf.alog[(gf.gf - 1 - i) % (gf.gf - 1)]
		local val = eval_poly_lowest_first(gf, C, inv_x)
		if val == 0 then
			table.insert(err_locs, i)
		end
	end
	
	if #err_locs == 0 or #err_locs > n_ec / 2 then
		return msg, false -- Too many errors
	end
	
	-- Forney's algorithm
	local Omega = {}
	for i = 1, n_ec do
		local val = 0
		for j = 1, i do
			local s = syndromes[i - j + 1] or 0
			local c = C[j] or 0
			val = gf.add(val, gf.mul(s, c))
		end
		Omega[i] = val
	end
	
	-- Derivative of C(x)
	local deriv = {}
	for i = 2, #C, 2 do
		deriv[i - 1] = C[i]
	end
	
	-- Correct the errors
	for _, loc in ipairs(err_locs) do
		local inv_X = gf.alog[(gf.gf - 1 - loc) % (gf.gf - 1)]
		local Omega_val = eval_poly_lowest_first(gf, Omega, inv_X)
		local deriv_val = eval_poly_lowest_first(gf, deriv, inv_X)
		if deriv_val == 0 then return msg, false end
		
		-- Aztec's roots are alpha^1..alpha^nc, so start = 1
		-- In Forney's formula, the error value is Omega(X^-1) / C'(X^-1)
		local err_val = gf.div(Omega_val, deriv_val)
		local msg_idx = #msg - loc
		if msg_idx >= 1 and msg_idx <= #msg then
			msg[msg_idx] = gf.add(msg[msg_idx], err_val)
		end
	end
	
	return msg, true
end

return azteccommon
