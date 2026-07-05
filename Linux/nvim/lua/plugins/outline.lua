return {
  "hedyhli/outline.nvim",
  lazy = true,
  cmd = { "Outline", "OutlineOpen" },
  keys = {
    -- 设置快捷键 <leader>o 来切换大纲视图
    { "<leader>mo", "<cmd>Outline<CR>", desc = "Toggle outline" },
  },
  opts = {
    -- 这里可以放你的自定义配置，留空则使用默认值
  },
}
