-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
-- 确保 treesitter 的 site 目录在 runtimepath 中
local site_path = vim.fn.stdpath("data") .. "/site"
if not vim.tbl_contains(vim.opt.runtimepath:get(), site_path) then
  vim.opt.runtimepath:append(site_path)
end