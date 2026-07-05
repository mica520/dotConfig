-- lua/plugins/vimtex.lua
return {
  "lervag/vimtex",
  lazy = false, -- 必须立即加载，否则反向搜索无法捕获
  init = function()
    -- 1. 编译器设置：使用 latexmk，XeLaTeX + BibTeX
    vim.g.vimtex_compiler_method = "latexmk"
    vim.g.vimtex_syntax_conceal_disable = 1
    vim.g.vimtex_compiler_latexmk = {
      continuous = 0, -- 默认不连续编译，可按键切换
      executable = "latexmk",
      options = {
        "-xelatex",
        "-bibtex",
        "-interaction=nonstopmode",
        "-synctex=1",
        "-file-line-error",
        "-verbose",
        "-halt-on-error",
        "--shell-escape",
      },
    }

    -- 2. 根目录标记（用于自动检测主文件）
    vim.g.vimtex_root_markers = { "main.tex", ".latexmkrc", ".git" }

    -- 3. PDF 查看器：SumatraPDF（Windows 程序，在 WSL 中调用）
    vim.g.vimtex_view_method = "general"

    -- 查找 SumatraPDF.exe 路径（优先从 PATH 中查找，或手动指定）
    local sumatra_path = vim.fn.exepath("SumatraPDF.exe")
    if sumatra_path == "" then
      -- 常见安装路径
      local possible_paths = {
        "/mnt/c/Program Files/SumatraPDF/SumatraPDF.exe",
        "/mnt/c/Program Files (x86)/SumatraPDF/SumatraPDF.exe",
      }
      for _, p in ipairs(possible_paths) do
        if vim.fn.filereadable(p) == 1 then
          sumatra_path = p
          break
        end
      end
    end
    if sumatra_path == "" then
      vim.notify("SumatraPDF.exe not found. Please install SumatraPDF or set the correct path.", vim.log.levels.WARN)
    end
    vim.g.vimtex_view_general_viewer = sumatra_path

    -- 正向搜索：从 Neovim 跳转到 PDF（Ctrl+左键或快捷键触发）
    -- 反向搜索：从 PDF 双击跳回 Neovim（使用 nvim --headless 调用 VimtexInverseSearch）
    -- 注意：%l 是行号，%o 是 PDF 路径，%f 是源文件路径
    vim.g.vimtex_view_general_options = [[
      -reuse-instance
      -forward-search "%f" %l "%o"
      -inverse-search "wsl ~/bin/vimtex-inverse %%l '%%f'"
    ]]
    -- 4. 自动打开/刷新 PDF
    vim.g.vimtex_view_automatic = 1

    -- 5. 动态检测主文件（保持不变）
    local function set_main_file()
      local current_file = vim.api.nvim_buf_get_name(0)
      if current_file == "" then
        return
      end
      local dir = vim.fn.fnamemodify(current_file, ":h")
      while dir ~= "/" and dir ~= "" do
        local main_path = dir .. "/main.tex"
        if vim.fn.filereadable(main_path) == 1 then
          vim.b.vimtex_main = main_path
          return
        end
        dir = vim.fn.fnamemodify(dir, ":h")
      end
      vim.b.vimtex_main = current_file
    end

    local augroup_main = vim.api.nvim_create_augroup("VimTeXMainFile", { clear = true })
    vim.api.nvim_create_autocmd("BufReadPre", {
      pattern = "*.tex",
      group = augroup_main,
      callback = set_main_file,
    })
  end,

  config = function()
    -- 快捷键映射
    vim.keymap.set("n", "<leader>li", "<cmd>VimtexInfo<CR>", { desc = "VimTeX: show info" })
    vim.keymap.set("n", "<leader>lv", "<cmd>VimtexView<CR>", { desc = "VimTeX: forward search (Vim to PDF)" })
    vim.keymap.set("n", "<leader>ll", "<cmd>VimtexCompile<CR>", { desc = "VimTeX: compile" })
    vim.keymap.set("n", "<leader>lk", "<cmd>VimtexStop<CR>", { desc = "VimTeX: stop compilation" })
    vim.keymap.set("n", "<leader>lc", "<cmd>VimtexClean<CR>", { desc = "VimTeX: clean temp files" })
    vim.keymap.set("n", "<leader>lC", "<cmd>VimtexCleanFull<CR>", { desc = "VimTeX: clean all (including PDF)" })

    -- 切换连续编译模式（使用单独的全局变量控制）
    vim.g.vimtex_compiler_latexmk_continuous = 0
    vim.keymap.set("n", "<leader>lt", function()
      vim.g.vimtex_compiler_latexmk_continuous = 1 - vim.g.vimtex_compiler_latexmk_continuous
      -- 更新 latexmk 选项（需重新设置）
      vim.g.vimtex_compiler_latexmk.continuous = vim.g.vimtex_compiler_latexmk_continuous
      local status = vim.g.vimtex_compiler_latexmk_continuous == 1 and "ON" or "OFF"
      print("Continuous mode: " .. status)
    end, { desc = "VimTeX: toggle continuous compilation" })

    -- 自动清理中间文件（编译成功后执行）
    local function cleanup_on_success()
      vim.cmd("VimtexClean")
      print("VimTeX: cleaned intermediate files")
    end
    local augroup_clean = vim.api.nvim_create_augroup("VimTeXAutoClean", { clear = true })
    vim.api.nvim_create_autocmd("User", {
      pattern = "VimtexEventCompileSuccess",
      group = augroup_clean,
      callback = cleanup_on_success,
    })
  end,
}
