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
    -- 获取当前缓冲区的名称和类型
    local bufname = vim.api.nvim_buf_get_name(0)
    local buftype = vim.api.nvim_get_option_value("buftype", { buf = 0 })

    -- 如果是终端缓冲区、无名称缓冲区或特殊文件类型，则跳过
    if
      bufname:match("term://") -- yazi 等终端缓冲区
      or buftype == "terminal" -- 终端类型
      or buftype == "nofile" -- 无文件缓冲区
      or buftype == "help" -- 帮助文档
      or bufname == ""
    then -- 未命名缓冲区
      return
    end

    -- 只有普通文件缓冲区才执行 mkview
    vim.cmd("mkview")
  end,
})
