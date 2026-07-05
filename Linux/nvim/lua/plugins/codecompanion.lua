-- lua/plugins/codecompanion.lua
return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "MeanderingProgrammer/render-markdown.nvim",
  },
  event = "VeryLazy",

  opts = function()
    ----------------------------------------------------------------
    -- DeepSeek adapter
    ----------------------------------------------------------------
    local function deepseek_adapter(name, overrides)
      return function()
        return require("codecompanion.adapters").extend(
          "deepseek",
          vim.tbl_extend("force", {
            env = {
              api_key = function()
                return os.getenv("DEEPSEEK_API_KEY")
              end,
            },
            schema = {
              model = {
                default = "deepseek-chat",
                choices = {
                  "deepseek-chat",
                  "deepseek-coder",
                },
              },
              temperature = { default = 0.3 },
              max_tokens = { default = 8192 },
            },
          }, overrides or {})
        )
      end
    end

    return {
      opts = {
        language = "Chinese",
      },

      adapters = {
        deepseek = deepseek_adapter("deepseek"),
      },

      strategies = {
        chat = {
          adapter = "deepseek",
          keymaps = {
            close = { modes = { n = "q" } },
          },
        },
        inline = {
          adapter = "deepseek",
        },
        agent = {
          adapter = "deepseek",
        },
      },

      interactions = {
        inline = {
          placement = "replace",
          diff = {
            enabled = true,
            provider = "default",
          },
        },
      },

      display = {
        action_palette = {
          width = 95,
          height = 14,
          prompt = "CodeCompanion> ",
        },
        chat = {
          window = {
            layout = "vertical",
            border = "rounded",
            height = 0.85,
            width = 0.80,
            relative = "editor",
          },
          show_settings = true,
        },
        -- ✨ 新增：启用操作通知（重构、内联编辑等都会显示提示）
        notifications = {
          enabled = true,
        },
      },

      system_prompt = function()
        return [[
You are an expert programmer.
When asked to rewrite/fix/refactor SELECTED CODE:
- Output ONLY the replacement code.
- Do NOT add explanations before/after the code.
- Do NOT wrap in markdown fences (no ```lua / ```).
- Preserve surrounding indentation.
If the user asks a general question (not a code edit), then answer normally.
]]
      end,
    }
  end,

  config = function(_, opts)
    require("codecompanion").setup(opts)

    vim.defer_fn(function()
      -- 普通模式：切换聊天窗口
      vim.keymap.set(
        "n",
        "<leader>aa",
        "<cmd>CodeCompanionChat Toggle<cr>",
        { desc = "AI: Toggle Chat", silent = true, noremap = true }
      )

      -- 可视模式：对选中代码执行 AI 命令（显式指定范围，避免占位符问题）
      vim.keymap.set(
        "v",
        "<leader>aa",
        ":'<,'>CodeCompanion ",
        { desc = "AI: Execute command on selection", silent = false, noremap = true }
      )

      -- 普通模式：打开动作面板
      vim.keymap.set(
        "n",
        "<leader>ac",
        "<cmd>CodeCompanionActions<cr>",
        { desc = "AI: Actions Panel", silent = true, noremap = true }
      )

      -- 可选：新建聊天
      vim.keymap.set(
        "n",
        "<leader>an",
        "<cmd>CodeCompanionChat New<cr>",
        { desc = "AI: New Chat", silent = true, noremap = true }
      )
    end, 200)
  end,
}
