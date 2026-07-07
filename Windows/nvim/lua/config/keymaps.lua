--
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
-- 用普通模式下 jj，可视模式下 jk 替代<esc>
vim.keymap.set("i", "jj", "<Esc>")
vim.keymap.set("v", "jk", "<Esc>")

-- 在 keymaps.lua 中
local map = vim.keymap.set

-- 插入模式和选择模式下，用 <C-j> 替代 <Tab> 展开或跳转
map("i", "<C-j>", "<Plug>luasnip-expand-or-jump", { expr = true })
map("s", "<C-j>", "<Plug>luasnip-expand-or-jump", { expr = true })

-- 用 <C-k> 替代 <S-Tab> 跳转到上一个占位符
map("i", "<C-k>", "<Plug>luasnip-jump-prev", { expr = true })
map("s", "<C-k>", "<Plug>luasnip-jump-prev", { expr = true })
