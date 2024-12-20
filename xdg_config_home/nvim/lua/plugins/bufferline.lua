return {
  "akinsho/bufferline.nvim",
  event = "VeryLazy",
  keys = {
    { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>" },
    { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>" },
    { "<leader>bo", "<Cmd>BufferLineCloseOthers<CR>" },
    { "<leader>br", "<Cmd>BufferLineCloseRight<CR>" },
    { "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>" },
    { "<S-h>", "<cmd>BufferLineCyclePrev<cr>" },
    { "<S-l>", "<cmd>BufferLineCycleNext<cr>" },
  },
  opts = {
    options = {
      close_command = function(n)
        require("util.ui").bufremove(n)
      end,
      right_mouse_command = function(n)
        require("util.ui").bufremove(n)
      end,
      diagnostics = "nvim_lsp",
      always_show_bufferline = false,
      diagnostics_indicator = function(_, _, diag)
        local icons = {
          Error = "E ",
          Warn = "W ",
          Hint = "H ",
          Info = "I ",
        }
        local ret = (diag.error and icons.Error .. diag.error .. " " or "")
          .. (diag.warning and icons.Warn .. diag.warning or "")
        return vim.trim(ret)
      end,
      offsets = {
        {
          filetype = "neo-tree",
          text = "Neo-tree",
          highlight = "Directory",
          text_align = "left",
        },
      },
      get_element_icon = function(opts)
        local ft = ""
        return ft[opts.filetype]
      end,
    },
  },
  config = function(_, opts)
    require("bufferline").setup(opts)
    vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete" }, {
      callback = function()
        vim.schedule(function()
          ---@diagnostic disable-next-line: undefined-global
          pcall(nvim_bufferline)
        end)
      end,
    })
  end,
}
