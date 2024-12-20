local M = {}

local log_dir = vim.fn.stdpath("data") .. "/java-runner/logs"
local log_file = log_dir .. "/java-runner.log"

if vim.fn.isdirectory(log_dir) == 0 then
	vim.fn.mkdir(log_dir, "p")
end

local function get_timestamp()
	return os.date("%Y-%m-%d %H:%M:%S")
end

local function format_log_entry(level, message, context)
	local timestamp = get_timestamp()
	local log_entry = string.format("[%s] [%s] %s", timestamp, level, message)
	if context then
		log_entry = log_entry .. " | Context: " .. vim.inspect(context)
	end
	return log_entry
end

function M.log(level, message, context)
	local log_entry = format_log_entry(level, message, context)
	local file = io.open(log_file, "a")
	if file then
		file:write(log_entry .. "\n")
		file:close()
	end
end

function M.debug(message, context)
	M.log("DEBUG", message, context)
end

function M.info(message, context)
	M.log("INFO", message, context)
	vim.notify(message, vim.log.levels.INFO)
end

function M.warn(message, context)
	M.log("WARN", message, context)
	vim.notify(message, vim.log.levels.WARN)
end

function M.error(message, context)
	M.log("ERROR", message, context)
	vim.notify(message, vim.log.levels.ERROR)
end

return M
