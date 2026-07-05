return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        texlab = {
          settings = {
            texlab = {
              experimental = {
                labelReferenceCommands = {
                  "ctex", -- 将 \ctex 设为可补全的引用命令
                },
                citationCommands = {
                  "ctex", -- 同理，让它在引用文献时也能工作
                },
              },
            },
          },
        },
      },
    },
  },
}
