return {
  "brianhuster/live-preview.nvim",
  dependencies = {
    -- 从以下 picker 中选择一个（用于文件选择等功能）
    "nvim-telescope/telescope.nvim", -- 如果你已经安装了 telescope
    -- "ibhagwan/fzf-lua",
    -- "echasnovski/mini.pick",
    -- "folke/snacks.nvim",
  },
  config = function()
    require("live-preview").setup({
      -- 这里可以放你的自定义配置
    })
  end,
}
