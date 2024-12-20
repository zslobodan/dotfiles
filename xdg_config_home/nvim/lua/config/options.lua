vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.g.bigfile_size = 1024 * 1024 * 1.5

vim.g.statuscolumn = {
  folds_open = false,
  folds_githl = true,
}

local opt = vim.opt

-- opt.guicursor = ""
opt.shortmess:append("sI")
opt.number = true
opt.relativenumber = true
opt.numberwidth = 2
opt.cursorline = true
opt.showmatch = true
opt.matchtime = 3
opt.backspace = "indent,eol,start"
opt.pumblend = 10
opt.pumheight = 10
opt.winminwidth = 5
opt.foldlevel = 99
opt.fillchars = {
  foldopen = "",
  foldclose = "",
  fold = " ",
  foldsep = " ",
  diff = "╱",
  eob = " ",
}
opt.conceallevel = 2
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true
opt.wrap = false
opt.autowrite = true
opt.undofile = true
opt.undolevels = 10000
opt.ignorecase = true
opt.smartcase = true
opt.signcolumn = "yes"
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.inccommand = "nosplit"
opt.splitbelow = true
opt.splitright = true
opt.splitkeep = "screen"
opt.completeopt = "menu,menuone,noselect"
opt.statuscolumn = [[%!v:lua.require'util.ui'.statuscolumn()]]
opt.timeoutlen = 400
opt.updatetime = 200
opt.confirm = true
opt.wildmode = "longest:full,full"
opt.virtualedit = "block"
opt.jumpoptions = "view"
opt.laststatus = 3
opt.linebreak = true
opt.mouse = "a"
opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }
opt.shiftround = true
opt.shortmess:append({ W = true, I = true, c = true, C = true })
opt.showmode = false
opt.spelllang = { "en" }
opt.spelloptions:append("noplainbuffer")
opt.termguicolors = true
opt.smoothscroll = true
opt.foldexpr = "v:lua.require'util.ui'.foldexpr()"
opt.foldmethod = "expr"
opt.foldtext = ""

vim.cmd([[let &t_Cs = "\e[4:3m"]])
vim.cmd([[let &t_Ce = "\e[4:0m"]])
