local M = {}
local utils = require("calcium.utils")

-- Token types
local TOKEN_TYPES = {
	NUMBER = 1,
	OPERATOR = 2,
	FUNCTION = 3,
	PAREN = 4,
	WORD = 5,
	SEPARATOR = 6,
	WHITESPACE = 7,
	OTHER = 8,
}

-- Math functions available in the sandbox (from calculator.lua mfl)
local MATH_FUNCTIONS = {
	-- Standard math library
	abs = true,
	acos = true,
	asin = true,
	atan = true,
	atan2 = true,
	ceil = true,
	cos = true,
	cosh = true,
	deg = true,
	exp = true,
	floor = true,
	fmod = true,
	frexp = true,
	huge = true,
	ldexp = true,
	log = true,
	log10 = true,
	max = true,
	min = true,
	modf = true,
	pi = true,
	pow = true,
	rad = true,
	random = true,
	randomseed = true,
	sin = true,
	sinh = true,
	sqrt = true,
	tan = true,
	tanh = true,
	-- Custom functions
	avg = true,
	clamp = true,
	fact = true,
	fib = true,
	gcd = true,
	lcm = true,
	median = true,
	range = true,
	round = true,
	sign = true,
	trunc = true,
}

-- Check if a word is a math function
local function is_math_function(name)
	return MATH_FUNCTIONS[name] ~= nil
end

-- Tokenize a line into tokens with position and type information
local function tokenize_line(line, known_variables)
	local tokens = {}
	local pos = 1

	while pos <= #line do
		local matched = false

		-- Try patterns in priority order
		-- Numbers (including scientific notation)
		do
			local match = line:sub(pos):match("^(%d+%.?%d*[eE][%+%-]?%d+)")
			if match then
				table.insert(tokens, {
					type = TOKEN_TYPES.NUMBER,
					value = match,
					start_col = pos,
					end_col = pos + #match - 1,
					is_variable = false,
				})
				pos = pos + #match
				matched = true
			end
		end

		if not matched then
			local match = line:sub(pos):match("^(%d+%.%d+)")
			if match then
				table.insert(tokens, {
					type = TOKEN_TYPES.NUMBER,
					value = match,
					start_col = pos,
					end_col = pos + #match - 1,
					is_variable = false,
				})
				pos = pos + #match
				matched = true
			end
		end

		if not matched then
			local match = line:sub(pos):match("^(%d+)")
			if match then
				table.insert(tokens, {
					type = TOKEN_TYPES.NUMBER,
					value = match,
					start_col = pos,
					end_col = pos + #match - 1,
					is_variable = false,
				})
				pos = pos + #match
				matched = true
			end
		end

		-- Multi-char operators (must come before single-char)
		if not matched then
			local match = line:sub(pos):match("^(==)")
			if match then
				table.insert(tokens, {
					type = TOKEN_TYPES.OPERATOR,
					value = match,
					start_col = pos,
					end_col = pos + #match - 1,
				})
				pos = pos + #match
				matched = true
			end
		end

		if not matched then
			local match = line:sub(pos):match("^(~=)")
			if match then
				table.insert(tokens, {
					type = TOKEN_TYPES.OPERATOR,
					value = match,
					start_col = pos,
					end_col = pos + #match - 1,
				})
				pos = pos + #match
				matched = true
			end
		end

		if not matched then
			local match = line:sub(pos):match("^(>=)")
			if match then
				table.insert(tokens, {
					type = TOKEN_TYPES.OPERATOR,
					value = match,
					start_col = pos,
					end_col = pos + #match - 1,
				})
				pos = pos + #match
				matched = true
			end
		end

		if not matched then
			local match = line:sub(pos):match("^(<=)")
			if match then
				table.insert(tokens, {
					type = TOKEN_TYPES.OPERATOR,
					value = match,
					start_col = pos,
					end_col = pos + #match - 1,
				})
				pos = pos + #match
				matched = true
			end
		end

		-- Single-char operators
		if not matched then
			local match = line:sub(pos):match("^([%+%-%*/%%%^])")
			if match then
				table.insert(tokens, {
					type = TOKEN_TYPES.OPERATOR,
					value = match,
					start_col = pos,
					end_col = pos + #match - 1,
				})
				pos = pos + #match
				matched = true
			end
		end

		if not matched then
			local match = line:sub(pos):match("^([<>])")
			if match then
				table.insert(tokens, {
					type = TOKEN_TYPES.OPERATOR,
					value = match,
					start_col = pos,
					end_col = pos + #match - 1,
				})
				pos = pos + #match
				matched = true
			end
		end

		-- Parentheses and brackets
		if not matched then
			local match = line:sub(pos):match("^([%(%)%[%]])")
			if match then
				table.insert(tokens, {
					type = TOKEN_TYPES.PAREN,
					value = match,
					start_col = pos,
					end_col = pos + #match - 1,
				})
				pos = pos + #match
				matched = true
			end
		end

		-- Separator (comma)
		if not matched then
			local match = line:sub(pos):match("^(,)")
			if match then
				table.insert(tokens, {
					type = TOKEN_TYPES.SEPARATOR,
					value = match,
					start_col = pos,
					end_col = pos + #match - 1,
				})
				pos = pos + #match
				matched = true
			end
		end

		-- Words (identifiers)
		if not matched then
			local match = line:sub(pos):match("^([%a_][%w_]*)")
			if match then
				local token_type = TOKEN_TYPES.WORD
				local is_var = false

				if is_math_function(match) then
					token_type = TOKEN_TYPES.FUNCTION
				elseif known_variables and known_variables[match] then
					is_var = true
				end

				table.insert(tokens, {
					type = token_type,
					value = match,
					start_col = pos,
					end_col = pos + #match - 1,
					is_variable = is_var,
				})
				pos = pos + #match
				matched = true
			end
		end

		-- Whitespace
		if not matched then
			local match = line:sub(pos):match("^(%s+)")
			if match then
				table.insert(tokens, {
					type = TOKEN_TYPES.WHITESPACE,
					value = match,
					start_col = pos,
					end_col = pos + #match - 1,
				})
				pos = pos + #match
				matched = true
			end
		end

		-- Other characters
		if not matched then
			local match = line:sub(pos):match("^(.)")
			if match then
				table.insert(tokens, {
					type = TOKEN_TYPES.OTHER,
					value = match,
					start_col = pos,
					end_col = pos + #match - 1,
				})
				pos = pos + #match
				matched = true
			end
		end
	end

	return tokens
end

-- Calculate confidence score for a list of expression tokens
local function calculate_confidence(expr_tokens, known_variables)
	local score = 0
	local has_operator = false
	local has_function = false
	local prose_word_count = 0

	for _, token in ipairs(expr_tokens) do
		if token.type == TOKEN_TYPES.OPERATOR then
			score = score + 3
			has_operator = true
		elseif token.type == TOKEN_TYPES.FUNCTION then
			score = score + 5
			has_function = true
		elseif token.type == TOKEN_TYPES.NUMBER then
			score = score + 1
		elseif token.type == TOKEN_TYPES.WORD then
			if token.is_variable then
				score = score + 2
			else
				prose_word_count = prose_word_count + 1
				score = score - 2
			end
		end
	end

	-- Require at least operator or function for good confidence
	if not (has_operator or has_function) then
		score = score - 5
	end

	-- Penalize multiple unknown words (prose)
	if prose_word_count > 1 then
		score = score - prose_word_count * 3
	end

	return score
end

-- Scan forward from a starting token to find expression boundaries
local function scan_forward_for_expression(tokens, start_idx, known_variables, line)
	local expr_tokens = {}
	local paren_depth = 0
	local idx = start_idx
	local max_scan = 100  -- Prevent scanning too far
	local prev_token = nil

	while idx <= #tokens and idx - start_idx < max_scan do
		local token = tokens[idx]

		-- Track parenthesis depth
		if token.type == TOKEN_TYPES.PAREN then
			if token.value == "(" or token.value == "[" then
				paren_depth = paren_depth + 1
			else
				paren_depth = paren_depth - 1
				if paren_depth < 0 then
					break  -- Unmatched closing paren
				end
			end
		end

		-- Stop at definitional boundaries (outside parentheses)
		if paren_depth == 0 then
			-- Detect comment marker: two consecutive '-' operators
			if token.type == TOKEN_TYPES.OPERATOR and token.value == "-" and prev_token and
				prev_token.type == TOKEN_TYPES.OPERATOR and prev_token.value == "-" then
				-- Remove the last '-' from expr_tokens since we're at a comment start
				if #expr_tokens > 0 then
					table.remove(expr_tokens)
				end
				break
			end

			if token.type == TOKEN_TYPES.OPERATOR then
				-- Stop at assignment operator (single =)
				if token.value == "=" then
					if #expr_tokens > 0 then
						break  -- Don't include assignment operator
					end
				end
			elseif token.type == TOKEN_TYPES.OTHER then
				-- Stop at certain punctuation marks
				if token.value:match("[%$:#\"'%[%]]") then
					break
				end
			elseif token.type == TOKEN_TYPES.WORD and not token.is_variable and not is_math_function(token.value) then
				-- Stop at unknown words (prose) outside parentheses
				if #expr_tokens > 0 then
					break  -- Don't include this word
				end
			end
		end

		-- Collect non-whitespace tokens
		if token.type ~= TOKEN_TYPES.WHITESPACE then
			table.insert(expr_tokens, token)
		end

		prev_token = token
		idx = idx + 1
	end

	-- Build expression string from original line
	if #expr_tokens == 0 then
		return nil
	end

	local start_col = expr_tokens[1].start_col
	local end_col = expr_tokens[#expr_tokens].end_col
	local expr_str = line:sub(start_col, end_col)

	return {
		tokens = expr_tokens,
		text = expr_str,
		start_col = start_col,
		end_col = end_col,
		confidence = calculate_confidence(expr_tokens, known_variables),
	}
end

-- Find all potential expressions in a token list
local function find_expression_boundaries(tokens, known_variables, line)
	local expressions = {}
	local covered_ranges = {}  -- Track which columns are already part of an expression

	-- Helper: check if token at index i is immediately followed by '=' (with possible whitespace)
	local function is_before_assignment(idx)
		local next_idx = idx + 1
		while next_idx <= #tokens and tokens[next_idx].type == TOKEN_TYPES.WHITESPACE do
			next_idx = next_idx + 1
		end
		return next_idx <= #tokens and tokens[next_idx].type == TOKEN_TYPES.OPERATOR and tokens[next_idx].value == "="
	end

	for i = 1, #tokens do
		local token = tokens[i]

		-- Only start scanning from tokens that are not already covered by an expression
		local is_covered = false
		for _, range in ipairs(covered_ranges) do
			if token.start_col >= range.start_col and token.start_col <= range.end_col then
				is_covered = true
				break
			end
		end

		-- Skip starting scans from WORD tokens immediately before '=' (variable assignments)
		-- This prevents treating 'y' in 'y = x * pi' as the start of an expression
		if token.type == TOKEN_TYPES.WORD and is_before_assignment(i) then
			-- Skip this word - it's a variable assignment target
		elseif not is_covered and (token.type == TOKEN_TYPES.NUMBER or token.type == TOKEN_TYPES.FUNCTION or token.is_variable) then
			-- Start scanning from math-related tokens that aren't part of existing expressions
			local expr = scan_forward_for_expression(tokens, i, known_variables, line)
			if expr then
				-- Check if this overlaps significantly with existing expressions
				local is_duplicate = false
				for _, existing in ipairs(expressions) do
					if existing.start_col == expr.start_col and existing.end_col == expr.end_col then
						is_duplicate = true
						break
					end
				end

				if not is_duplicate then
					table.insert(expressions, expr)
					table.insert(covered_ranges, {start_col = expr.start_col, end_col = expr.end_col})
				end
			end
		end
	end

	return expressions
end

-- Select the expression closest to cursor position
local function select_closest_expression(expressions, cursor_col)
	if #expressions == 0 then
		return nil
	end

	local best = nil
	local min_distance = math.huge

	for _, expr in ipairs(expressions) do
		local distance

		if cursor_col >= expr.start_col and cursor_col <= expr.end_col then
			-- Cursor is inside expression - perfect match
			distance = 0
		else
			-- Distance to nearest boundary
			distance = math.min(math.abs(cursor_col - expr.start_col), math.abs(cursor_col - expr.end_col))
		end

		-- Prefer closer match, or higher confidence as tie-breaker
		if distance < min_distance or (distance == min_distance and (not best or expr.confidence > best.confidence)) then
			min_distance = distance
			best = expr
		elseif distance == min_distance and expr.confidence == best.confidence and expr.start_col < best.start_col then
			-- Second tie-breaker: prefer leftmost
			best = expr
		end
	end

	return best
end

-- Validate that extracted text looks like an expression
local function validate_expression(expr_text, known_variables)
	-- Check for empty
	if expr_text:match("^%s*$") then
		return false
	end

	-- Check balanced parentheses
	local open = 0
	for c in expr_text:gmatch("[%(%)]") do
		if c == "(" then
			open = open + 1
		else
			open = open - 1
			if open < 0 then
				return false
			end
		end
	end
	if open ~= 0 then
		return false
	end

	-- Basic validation: must contain at least a number, variable, or function
	-- (not just operators or punctuation)
	if not expr_text:match("%d") and  -- Contains a number
		not expr_text:match("[%a_][%w_]*%s*%(") and  -- Contains a function call
		not expr_text:match("[%a_][%w_]*") then  -- Contains a variable/word
		return false
	end

	return true
end

-- Main public API
function M.extract_expression_at_cursor(line, cursor_col, buffer_lines)
	-- Validate inputs
	if not line or line == "" then
		return nil
	end

	if cursor_col < 1 or cursor_col > #line then
		return nil
	end

	-- Wrap in pcall for safety
	local success, result = pcall(function()
		local calculator = require("calcium.calculator")
		local known_variables = calculator.extract_variables(buffer_lines)

		-- Tokenize the line
		local tokens = tokenize_line(line, known_variables)

		-- Find expression boundaries
		local expressions = find_expression_boundaries(tokens, known_variables, line)

		if #expressions == 0 then
			return nil
		end

		-- Select expression closest to cursor
		local best = select_closest_expression(expressions, cursor_col)

		if not best or best.confidence < 5 then
			return nil
		end

		-- Validate expression can be evaluated
		if not validate_expression(best.text, known_variables) then
			return nil
		end

		return {
			text = best.text,
			start_col = best.start_col,
			end_col = best.end_col,
			confidence = best.confidence,
		}
	end)

	if not success then
		-- Error occurred, fail gracefully
		return nil
	end

	return result
end

return M
