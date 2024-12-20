return {
	{
		"maxmx03/solarized.nvim",
		lazy = false,
		priority = 1000,
		---@type solarized.config
		opts = {
			transparent = {
				enabled = true,
			},
		},
		config = function(_, opts)
			vim.o.termguicolors = true
			vim.o.background = "dark"
			require("solarized").setup(opts)
			vim.cmd.colorscheme("solarized")
		end,
	},
	{
		"sainnhe/gruvbox-material",
		lazy = false,
		priority = 1000,
		enabled = false,
		config = function()
			vim.g.gruvbox_material_better_performance = 1
			vim.g.gruvbox_material_background = "hard"
			vim.g.gruvbox_material_foreground = "original"
			vim.g.gruvbox_material_float_style = "dim"
			-- vim.g.gruvbox_material_diagnostic_text_highlight = 1
			vim.cmd.colorscheme("gruvbox-material")
		end,
	},
}
