return {
  "benlubas/molten-nvim",
  version = "^1.0.0", -- 建议使用稳定版本[reference:23][reference:24]
  build = ":UpdateRemotePlugins", -- 安装或更新后自动更新远程插件[reference:25]
  init = function()
    -- 在这里添加快捷键映射
    vim.keymap.set("n", "<leader>mi", ":MoltenInit<CR>", { desc = "Init Molten" })
    vim.keymap.set("n", "<leader>me", ":MoltenEvaluateOperator<CR>", { desc = "Evaluate Operator" })
    vim.keymap.set("n", "<leader>ml", ":MoltenEvaluateLine<CR>", { desc = "Evaluate Line" })
    vim.keymap.set("v", "<leader>mr", ":<C-u>MoltenEvaluateVisual<CR>", { desc = "Evaluate Visual" })
    vim.keymap.set("n", "<leader>md", ":MoltenDelete<CR>", { desc = "Delete Output" })
  end,
}
