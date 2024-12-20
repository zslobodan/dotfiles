---@class Signs
local M = {}

local utils = require("java-runner.utils")
local config = require("java-runner.config")

---Update all signs in the current buffer
---Updates main method and test method signs
function M.update_signs()
	if not utils.is_java_file() then
		return
	end

	vim.fn.sign_unplace("JavaRunnerNS")

	local main_line = utils.find_main_method()
	if main_line then
		M.place_run_sign(main_line, "main")
	end

	local test_methods = utils.find_test_methods()
	for _, test in ipairs(test_methods) do
		M.place_run_sign(test.line, "test")
	end
end

---Place a run or test sign at the specified line number
---@param line_num number Line number where to place the sign
---@param sign_type "main"|"test" Type of sign to place
function M.place_run_sign(line_num, sign_type)
	vim.fn.sign_define("JavaRunSign", {
		text = config.options.icons.run,
		texthl = "JavaRunSign",
	})

	vim.fn.sign_define("JavaTestSign", {
		text = config.options.icons.test,
		texthl = "JavaTestSign",
	})

	local sign_id = vim.fn.bufnr("%") * 1000 + line_num
	local sign_name = sign_type == "main" and "JavaRunSign" or "JavaTestSign"
	vim.fn.sign_place(sign_id, "JavaRunnerNS", sign_name, vim.fn.bufnr("%"), {
		lnum = line_num,
		priority = 10,
	})
end

return M
