-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- 自动切换输入法 适用于wsl
if vim.fn.executable("im-select.exe") == 1 then
  local im_select = "im-select.exe" -- 或绝对路径
  local ENG = "1033"
  local CHN = "2052"

  vim.api.nvim_create_augroup("ime_imselect", { clear = true })
  vim.api.nvim_create_autocmd("InsertLeave", {
    group = "ime_imselect",
    callback = function()
      vim.system({ im_select, ENG })
    end,
  })
  vim.api.nvim_create_autocmd("InsertEnter", {
    group = "ime_imselect",
    callback = function()
      vim.system({ im_select, CHN })
    end,
  })
end

-- 保存折叠状态（在离开缓冲区时保存视图）
vim.api.nvim_create_autocmd({ "BufWinLeave" }, {
  pattern = "*.*",
  callback = function()
    vim.cmd("mkview")
  end,
})

-- 恢复折叠状态（在进入缓冲区时尝试加载视图，但忽略失败情况）
vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
  pattern = "*.*",
  callback = function()
    pcall(vim.cmd, "loadview") -- 使用 pcall 安全执行
  end,
})
