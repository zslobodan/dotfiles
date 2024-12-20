---@class Config
---@field options table Default plugin options
local M = {}

local logger = require("java-runner.logger")

M.options = {
	icons = {
		run = "",
		test = "",
	},
	terminal = {
		size = 10,
	},
	keymaps = {
		run = "<leader>jr",
		test = "<leader>jt",
		test_all = "<leader>je",
	},
}

---Setup configuration with provided options
---@param opts table? Optional configuration table
function M.setup(opts)
	opts = opts or {}

	if opts.terminal and opts.terminal.size then
		if type(opts.terminal.size) == "string" then
			local num = tonumber(opts.terminal.size)
			if num then
				opts.terminal.size = num
			else
				opts.terminal.size = nil
			end
		elseif type(opts.terminal.size) ~= "number" then
			opts.terminal.size = nil
		end
	end

	-- Setup default highlight groups if they don't exist
	local default_groups = {
		JavaRunSign = { link = "Statement" },
		JavaTestSign = { link = "Special" },
	}

	-- Create default highlight groups
	for group, settings in pairs(default_groups) do
		vim.api.nvim_set_hl(0, group, { default = true, link = settings.link })
	end

	-- Apply user options
	M.options = vim.tbl_deep_extend("force", M.options, opts)

	-- If user provided custom colors, override the highlight groups
	if opts.colors then
		if opts.colors.run then
			vim.api.nvim_set_hl(0, "JavaRunSign", {
				default = false,
				fg = opts.colors.run,
			})
		end
		if opts.colors.test then
			vim.api.nvim_set_hl(0, "JavaTestSign", {
				default = false,
				fg = opts.colors.test,
			})
		end
	end

	local group = vim.api.nvim_create_augroup("JavaRunner", { clear = true })
	vim.api.nvim_create_autocmd({ "BufEnter", "BufWrite" }, {
		group = group,
		pattern = "*.java",
		callback = require("java-runner.signs").update_signs,
	})

	vim.api.nvim_create_autocmd("TermClose", {
		group = group,
		callback = function()
			vim.schedule(function()
				require("java-runner.utils").restore_code_focus()
			end)
		end,
	})

	local utils = require("java-runner.utils")
	local runner = require("java-runner.runner")

	vim.keymap.set("n", M.options.keymaps.run, function()
		if not utils.is_java_file() then
			logger.warn("Not a Java file")
			return
		end
		local main_line = utils.find_main_method()
		if not main_line then
			logger.warn("No main method found in this file")
			return
		end
		runner.run_java_file()
	end, { desc = "Run Java main method (file)" })

	vim.keymap.set("n", M.options.keymaps.test, function()
		if not utils.is_java_file() or not utils.is_test_file() then
			logger.warn("Not a Java test file")
			return
		end
		runner.run_java_tests(nil, false)
	end, { desc = "Run test under cursor" })

	vim.keymap.set("n", M.options.keymaps.test_all, function()
		if not utils.is_java_file() or not utils.is_test_file() then
			logger.warn("Not a Java test file")
			return
		end
		runner.run_java_tests(nil, true)
	end, { desc = "Run all tests in file" })
end

return M
