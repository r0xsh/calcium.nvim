local M = {}

function M.extract_variables(buffer_lines)
	local variables = {}

	local pattern = "^%s*([%w_]+)%s*=%s*(.+)$"

	for _, line in ipairs(buffer_lines) do
		local var_name, var_expr = line:match(pattern)
		if var_name and var_expr then
			-- Remove trailing comments
			var_expr = var_expr:gsub("%s*%-%-.*$", ""):gsub("%s*#.*$", "")
			var_expr = var_expr:gsub("^%s+", ""):gsub("%s+$", "")

			local success, value = M.evaluate_expression(var_expr, variables)
			if success then
				variables[var_name] = value
			end
		end
	end

	return variables
end

function M.evaluate_expression(expr, variables)
	-- Replace scientific notation
	expr = expr:gsub("(%d+%.?%d*)e([%-%+]?%d+)", function(num, exp)
		return string.format("(%s * 10^%s)", num, exp)
	end)

	-- Replace variables with their values
	if variables then
		for var_name, var_value in pairs(variables) do
			-- Use word boundaries to avoid partial replacements
			expr = expr:gsub("([^%w_]?)(" .. var_name .. ")([^%w_]?)", function(before, _, after)
				return before .. tostring(var_value) .. after
			end)
			-- Handle variable at start/end of expression
			expr = expr:gsub("^" .. var_name .. "([^%w_])", tostring(var_value) .. "%1")
			expr = expr:gsub("([^%w_])" .. var_name .. "$", "%1" .. tostring(var_value))
			if expr == var_name then
				expr = tostring(var_value)
			end
		end
	end

	-- Replace common mathematical operations
	expr = expr:gsub("%^", "^")

	local safe_env = {
		math = math,
		abs = math.abs,
		acos = math.acos,
		asin = math.asin,
		atan = math.atan,
		atan2 = math.atan2,
		ceil = math.ceil,
		cos = math.cos,
		cosh = math.cosh,
		deg = math.deg,
		exp = math.exp,
		floor = math.floor,
		fmod = math.fmod,
		log = math.log,
		log10 = math.log10,
		max = math.max,
		min = math.min,
		modf = math.modf,
		pi = math.pi,
		pow = math.pow,
		rad = math.rad,
		random = math.random,
		sin = math.sin,
		sinh = math.sinh,
		sqrt = math.sqrt,
		tan = math.tan,
		tanh = math.tanh,
	}

	-- Try to evaluate the expression
	local func, err = load("return " .. expr, "expr", "t", safe_env)

	if not func then
		return false, "Syntax error: " .. tostring(err)
	end

	local success, result = pcall(func)

	if not success then
		return false, "Evaluation error: " .. tostring(result)
	end

	if type(result) ~= "number" then
		return false, "Result is not a number"
	end

	return true, result
end

function M.evaluate(expr, buffer_lines)
	local variables = M.extract_variables(buffer_lines)

	return M.evaluate_expression(expr, variables)
end

function M.format_result(result)
	-- Check if it's a very small or very large number
	if math.abs(result) < 0.001 and result ~= 0 then
		return string.format("%.6e", result)
	elseif math.abs(result) > 1000000 then
		return string.format("%.6e", result)
	else
		if result == math.floor(result) then
			return string.format("%d", result)
		else
			local formatted = string.format("%.10f", result)
			formatted = formatted:gsub("0+$", ""):gsub("%.$", "")
			return formatted
		end
	end
end

return M
