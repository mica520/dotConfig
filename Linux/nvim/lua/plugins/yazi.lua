return {
  "mikavilpas/yazi.nvim",
  version = "*",
  event = "VeryLazy",
  dependencies = {
    { "nvim-lua/plenary.nvim", lazy = true },
    "adelarsq/image_preview.nvim", -- 这里可以保持依赖
  },
  keys = {
    { "<leader>e", mode = { "n", "v" }, "<cmd>Yazi<cr>", desc = "Open yazi at the current file" },
    { "<leader>cw", "<cmd>Yazi cwd<cr>", desc = "Open the file manager in nvim's working directory" },
    { "<c-up>", "<cmd>Yazi toggle<cr>", desc = "Resume the last yazi session" },
  },
  opts = {
    open_for_directories = false,
    -- 正确配置 keymaps 的地方
    keymaps = {
      show_help = "<f1>",
    },
  },
  init = function()
    vim.g.loaded_netrwPlugin = 1
  end,
}
