-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--- lua/config/keymaps.lua
-- Keymaps are automatically loaded on the VeryLazy event
-- Add any additional keymaps here

-- 将 <leader>fr 改为打开最近文件
-- 将 <leader>fr 改为打开最近文件列表（使用 LazyVim.pick）
vim.keymap.set("n", "<leader>fr", function()
  LazyVim.pick("oldfiles")()
end, { desc = "Recent Files" })

-- 普通模式下，Ctrl+a 全选
vim.keymap.set("n", "<C-a>", "<Cmd>normal! ggVG<CR>", { desc = "Select all" })
