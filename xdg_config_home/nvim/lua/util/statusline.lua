local M = {}

local modes = {
  ["n"] = "NORMAL",
  ["i"] = "INSERT",
  ["v"] = "VISUAL",
  ["V"] = "V-LINE",
  ["\22"] = "V-BLOCK",
  ["c"] = "COMMAND",
  ["t"] = "TERMINAL",
}

local function get_mode()
  local mode_code = vim.api.nvim_get_mode().mode
  return string.format("[%s]", modes[mode_code] or mode_code)
end

local function get_root_dir()
  local function has_git_dir(path)
    local git_dir = vim.fn.finddir(".git", path .. ";")
    return git_dir ~= ""
  end

  local current_file = vim.fn.expand("%:p")
  if current_file == "" then
    return vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
  end

  local file_dir = vim.fn.fnamemodify(current_file, ":h")

  if has_git_dir(file_dir) then
    local git_root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("\n", "")
    if git_root ~= "" then
      return vim.fn.fnamemodify(git_root, ":t")
    end
  end

  return vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
end

local function get_git_branch()
  local branch = vim.fn.system("git branch --show-current 2>/dev/null | tr -d '\n'")
  if vim.v.shell_error == 0 and branch ~= "" then
    return "[" .. branch .. "]"
  end
  return ""
end

local function get_pretty_path()
  local path = vim.fn.expand("%:p")
  local cwd = vim.fn.getcwd()

  if path == "" then
    return ""
  end

  if path:find(cwd, 1, true) == 1 then
    path = path:sub(#cwd + 2)
  end

  local parts = vim.fn.split(path, "/")
  if #parts > 3 then
    return parts[1] .. "/.../" .. table.concat({ parts[#parts - 1], parts[#parts] }, "/")
  end

  return path
end

local cache = {
  root_dir = nil,
  git_branch = nil,
  last_update = 0,
}

function M.get_statusline()
  local current_time = vim.loop.now()
  if current_time - cache.last_update > 5000 then
    cache.root_dir = get_root_dir()
    cache.git_branch = get_git_branch()
    cache.last_update = current_time
  end

  local sections = {
    " ",
    get_mode(),
    " ",
    cache.root_dir or get_root_dir(),
    " ",
    cache.git_branch or get_git_branch(),
    " ",
    get_pretty_path(),

    "%=",

    "%l:%c",
    " ",
  }

  return table.concat(sections, "")
end

function M.setup()
  vim.o.laststatus = 3

  vim.opt.statusline = "%!v:lua.require'util.statusline'.get_statusline()"
end

return M
