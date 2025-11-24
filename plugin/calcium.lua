if vim.g.loaded_calcium then
	return
end
vim.g.loaded_calcium = 1

vim.api.nvim_create_user_command("Calcium", function(opts)
	local mode = "append"
	local visual = false

	if opts.args and opts.args ~= "" then
		local args = vim.split(opts.args, "%s+")
		if args[1] == "append" or args[1] == "a" then
			mode = "append"
		elseif args[1] == "replace" or args[1] == "r" then
			mode = "replace"
		end
	end

	if opts.range > 0 then
		visual = true
	end

	require("calcium").calculate(mode, visual)
end, {
	nargs = "?",
	range = true,
	desc = "Calculate",
})
