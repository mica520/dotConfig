local colorschemes = {
  {
    "bluz71/vim-nightfly-guicolors",
    priority = 1000,
    config = function()
      vim.cmd([[
        colorscheme nightfly

        " 透明模式设置
        highlight Normal guibg=NONE ctermbg=NONE
        highlight NormalNC guibg=NONE ctermbg=NONE
        highlight LineNr guibg=NONE ctermbg=NONE
        highlight SignColumn guibg=NONE ctermbg=NONE
        highlight FoldColumn guibg=NONE ctermbg=NONE
        
        " 修复当前选中行 - 使用更明显的颜色
        highlight CursorLine guibg=#2a3b4c ctermbg=235
        highlight CursorLineNr guifg=#FFB86C guibg=NONE
        
        highlight WinSeparator guifg=#3FC5FF guibg=NONE
        highlight NormalFloat guibg=NONE
        highlight FloatBorder guibg=NONE
        highlight NvimTreeNormal guibg=NONE
        highlight NvimTreeWinSeparator guibg=NONE

        " 诊断虚拟文本背景透明
        highlight DiagnosticVirtualTextError guibg=NONE
        highlight DiagnosticVirtualTextWarn guibg=NONE
        highlight DiagnosticVirtualTextInfo guibg=NONE
        highlight DiagnosticVirtualTextHint guibg=NONE
        highlight DiagnosticVirtualTextOk guibg=NONE

        " NvimTree 箭头颜色
        highlight NvimTreeFolderArrowClosed guifg=#3FC5FF
        highlight NvimTreeFolderArrowOpen guifg=#3FC5FF
      ]])
    end,
  },

  {
    "catppuccin/nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd([[
        colorscheme catppuccin-mocha

        " 透明模式设置
        highlight Normal guibg=NONE ctermbg=NONE
        highlight NormalNC guibg=NONE ctermbg=NONE
        highlight LineNr guibg=NONE ctermbg=NONE
        highlight SignColumn guibg=NONE ctermbg=NONE
        highlight FoldColumn guibg=NONE ctermbg=NONE
        highlight CursorLine guibg=NONE ctermbg=NONE

        " NvimTree 透明与箭头颜色
        highlight NvimTreeIndentMarker guifg=#A6E3A1
        highlight NvimTreeFolderArrowClosed guifg=#A6E3A1
        highlight NvimTreeFolderArrowOpen guifg=#A6E3A1
        highlight NvimTreeNormal guibg=NONE
        highlight NvimTreeWinSeparator guibg=NONE

        " 窗口分隔线透明
        highlight WinSeparator guifg=#A6E3A1 guibg=NONE

        " 诊断虚拟文本背景透明
        highlight DiagnosticVirtualTextError guibg=NONE
        highlight DiagnosticVirtualTextWarn guibg=NONE
        highlight DiagnosticVirtualTextInfo guibg=NONE
        highlight DiagnosticVirtualTextHint guibg=NONE
        highlight DiagnosticVirtualTextOk guibg=NONE

        " 浮动窗口透明
        highlight NormalFloat guibg=NONE
        highlight FloatBorder guibg=NONE
      ]])
    end,
  },

  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {},
    config = function()
      vim.cmd([[
        colorscheme tokyonight

        " 透明模式设置
        highlight Normal guibg=NONE ctermbg=NONE
        highlight NormalNC guibg=NONE ctermbg=NONE
        highlight LineNr guibg=NONE ctermbg=NONE
        highlight SignColumn guibg=NONE ctermbg=NONE
        highlight FoldColumn guibg=NONE ctermbg=NONE
        highlight CursorLine guibg=NONE ctermbg=NONE
        highlight BufferTabpageFill guibg=NONE

        " NvimTree 透明与箭头颜色
        highlight NvimTreeIndentMarker guifg=#2AC3DE
        highlight NvimTreeFolderArrowClosed guifg=#2AC3DE
        highlight NvimTreeFolderArrowOpen guifg=#2AC3DE
        highlight NvimTreeNormal guibg=NONE
        highlight NvimTreeWinSeparator guibg=NONE

        " 窗口分隔线透明
        highlight WinSeparator guifg=#2AC3DE guibg=NONE

        " 诊断虚拟文本背景透明
        highlight DiagnosticVirtualTextError guibg=NONE
        highlight DiagnosticVirtualTextWarn guibg=NONE
        highlight DiagnosticVirtualTextInfo guibg=NONE
        highlight DiagnosticVirtualTextHint guibg=NONE
        highlight DiagnosticVirtualTextOk guibg=NONE

        " 浮动窗口透明
        highlight NormalFloat guibg=NONE
        highlight FloatBorder guibg=NONE
      ]])
    end,
  },
}

local lualine_colorscheme = {
  -- nightfly
  {
    blue = "#65D1FF",
    green = "#3EFFDC",
    violet = "#FF61EF",
    yellow = "#FFDA7B",
    red = "#FF4A4A",
    fg = "#c3ccdc",
    inactive_bg = "#2c3043",
  },

  -- catppuccin-mocha
  {
    fg = "#CDD6F4",
    yellow = "#F9E2AF",
    green = "#A6E3A1",
    blue = "#89B4FA",
    red = "#F38BA8",
    pink = "#F5C2E7",
    orange = "#FF9E64",
  },

  -- tokyonight-night
  {
    fg = "#A9B1D6",
    yellow = "#FF9E64",
    green = "#9ECE6A",
    blue = "#2AC3DE",
    red = "#F7768E",
    pink = "#BB9AF7",
  },
}

-- 修改这里来选择不同的主题：1=nightfly, 2=catppuccin, 3=tokyonight
LUALINE_COLORSCHEME = lualine_colorscheme[2] -- 当前使用 nightfly 的 lualine 主题

return {
  colorschemes[2], -- 当前使用 nightfly 主题
}
