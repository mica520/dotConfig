return {
  -- Snacks.nvim 主插件
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      bigfile = { enabled = false },
      dashboard = { enabled = false },
      image = { enabled = false },
      explorer = {
        enabled = false,
        git_status = true,
        git_untracked = true,
        git_status_open = true,
        replace_netrw = true,
        win = {},
      },
      indent = { enabled = true },
      input = { enabled = true },
      picker = {
        enabled = true,
        ui_select = true,
        -- 可选：配置 picker 的默认选项
        layout = {
          preset = "telescope",
        },
        win = {
          input = {
            keys = {
              ["<C-s>"] = { "grep_word", mode = { "n", "i" } },
            },
          },
        },
      },
      notifier = {
        enabled = true,
        timeout = 3000,
      },
      quickfile = { enabled = true },
      scope = { enabled = true },
      scroll = { enabled = true },
      statuscolumn = { enabled = true },
      words = { enabled = true },
    },
    config = function(_, opts)
      require("snacks").setup(opts)

      -- 设置 vim.ui 的全局接管
      local snacks = require("snacks")
      vim.ui.input = snacks.input
      vim.ui.select = snacks.picker.select
    end,
    -- 解决下载超时的构建命令
    build = function()
      local plugin_dir = vim.fn.stdpath("data") .. "/lazy/snacks.nvim"
      -- 如果插件目录存在，尝试浅克隆更新
      if vim.loop.fs_stat(plugin_dir) then
        vim.cmd(string.format("!git -C %s fetch --depth=1 2>/dev/null || true", plugin_dir))
        vim.cmd(string.format("!git -C %s reset --hard origin/main 2>/dev/null || true", plugin_dir))
      end
    end,
    -- 键位映射
    keys = {
      -- Picker 相关快捷键
      {
        "<leader>ff",
        function()
          require("snacks").picker.files()
        end,
        desc = "Find Files",
      },
      {
        "<leader>fg",
        function()
          require("snacks").picker.grep()
        end,
        desc = "Grep",
      },
      {
        "<leader>fb",
        function()
          require("snacks").picker.buffers()
        end,
        desc = "Buffers",
      },
      {
        "<leader>fh",
        function()
          require("snacks").picker.help()
        end,
        desc = "Help",
      },
      {
        "<leader>fk",
        function()
          require("snacks").picker.keymaps()
        end,
        desc = "Keymaps",
      },
      {
        "<leader>fr",
        function()
          require("snacks").picker.resume()
        end,
        desc = "Resume",
      },
      {
        "<leader>fs",
        function()
          require("snacks").picker.lsp_symbols()
        end,
        desc = "LSP Symbols",
      },
      {
        "<leader>fl",
        function()
          require("snacks").picker.lines()
        end,
        desc = "Buffer Lines",
      },
      {
        "<leader>fc",
        function()
          require("snacks").picker.command_history()
        end,
        desc = "Command History",
      },
      -- 代码搜索
      {
        "<leader>sG",
        function()
          require("snacks").picker.grep()
        end,
        desc = "Grep",
      },
      {
        "<leader>sw",
        function()
          require("snacks").picker.grep_word()
        end,
        desc = "Grep Word",
      },
      -- 文件浏览
      {
        "<leader>e",
        function()
          require("snacks").explorer.open()
        end,
        desc = "Explorer",
      },
      -- 通知
      {
        "<leader>un",
        function()
          require("snacks").notifier.show_history()
        end,
        desc = "Notification History",
      },
    },
    -- 自动命令
    autocmd = {
      -- 自动处理大文件
      {
        event = "BufReadPre",
        pattern = "*",
        callback = function()
          local ft = vim.bo.filetype
          local size = vim.fn.getfsize(vim.api.nvim_buf_get_name(0))
          if size > 1024 * 1024 * 2 and ft ~= "bigfile" then -- 2MB
            vim.bo.filetype = "bigfile"
            vim.cmd("doautocmd User SnacksBigfile")
          end
        end,
      },
    },
  },

  -- 额外配置：如果仍然有下载问题，可以添加这个插件配置来强制使用浅克隆
  {
    "folke/snacks.nvim",
    dev = false,
    -- 如果手动克隆了，可以启用下面的配置
    -- dev = true,
    -- dir = vim.fn.stdpath("data") .. "/lazy/snacks.nvim",
  },
}
