return {
  "iamcco/markdown-preview.nvim",
  cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  ft = { "markdown" },
  build = function()
    vim.fn["mkdp#util#install"]()
  end,
  config = function()
    -- 快捷键绑定
    vim.keymap.set("n", "<leader>mp", "<Plug>MarkdownPreviewToggle", { desc = "Toggle Markdown Preview" })
    -- 其他配置...
  end,
}
