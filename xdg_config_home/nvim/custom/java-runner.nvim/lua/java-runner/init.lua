---@class JavaRunner
---@field config table Configuration module
local M = {}

local logger = require("java-runner.logger")

M.config = require("java-runner.config")

---Setup the plugin with custom options
---@param opts table? Optional configuration table
function M.setup(opts)
	logger.debug("Starting setup")

	opts = opts or {}

	local success, err = pcall(function()
		M.config.setup(opts)
	end)

	if success then
		logger.debug("Setup completed successfully")
	else
		logger.error("Setup failed", { error = err })
	end
end

return M
