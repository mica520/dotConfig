return {
  "hedyhli/markdown-toc.nvim",
  ft = "markdown",
  cmd = { "Mtoc" },
  keys = {
    { "<leader>mt", "<cmd>Mtoc<CR>", desc = "Generate/Update TOC" },
  },
  opts = {
    auto_update = true,
  },
}
