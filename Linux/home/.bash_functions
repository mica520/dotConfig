# ----------------------------------------------------------------------
# 函数 (Functions)
# ----------------------------------------------------------------------

# Yazi 目录跳转（退出 yazi 时自动 cd 到所选目录）
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  command yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd <"$tmp"
  [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
  command rm -f -- "$tmp"
}

# 增强 apt：安装/卸载后自动更新手动安装列表
apt() {
  local sudo_cmd="sudo"
  [ "$EUID" -eq 0 ] && sudo_cmd=""
  case "$1" in
  install | remove | purge | autoremove)
    $sudo_cmd apt "$@"
    apt-mark showmanual >~/dotConfig/Linux/manual-packages.list
    ;;
  *)
    $sudo_cmd apt "$@"
    ;;
  esac
}

# Conda 延迟加载（首次调用时初始化）
conda() {
  local CONDA_ROOT="$HOME/miniconda3"
  if [ -d "$CONDA_ROOT" ]; then
    unset -f conda
    if [ -f "$CONDA_ROOT/etc/profile.d/conda.sh" ]; then
      . "$CONDA_ROOT/etc/profile.d/conda.sh"
    else
      export PATH="$CONDA_ROOT/bin:$PATH"
    fi
    conda "$@"
  else
    echo "Error: Conda not found at $CONDA_ROOT" >&2
    return 1
  fi
}

# Pandoc 转中文 PDF
pandoc-cn() {
  local input=""
  local output=""
  local size="12pt"
  local doc_class="article"

  # 手动解析选项
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -o)
        if [[ -z "$2" ]]; then
          echo "错误: -o 需要指定输出文件名"
          return 1
        fi
        output="$2"
        shift 2
        ;;
      -s|--size)
        if [[ -z "$2" ]]; then
          echo "错误: -s 需要指定字号"
          return 1
        fi
        size="$2"
        shift 2
        ;;
      -*)
        echo "错误: 未知选项 $1"
        echo "用法: pandoc-cn [-o <输出.pdf>] [-s <字号>] <输入.md>"
        return 1
        ;;
      *)
        # 第一个非选项参数作为输入文件
        if [[ -z "$input" ]]; then
          input="$1"
          shift
        else
          echo "错误: 只能指定一个输入文件"
          return 1
        fi
        ;;
    esac
  done

  if [[ -z "$input" ]]; then
    echo "错误: 未指定输入 Markdown 文件"
    echo "用法: pandoc-cn [-o <输出.pdf>] [-s <字号>] <输入.md>"
    return 1
  fi

  # 若未指定输出，则生成同名 PDF（去掉原扩展名后追加 .pdf）
  if [[ -z "$output" ]]; then
    output="${input%.*}.pdf"
  fi

  # 根据字号选择文档类
  if [[ "$size" == "14pt" || "$size" == "17pt" || "$size" == "20pt" ]]; then
    doc_class="extarticle"
    echo "检测到大字号 ($size)，自动切换至 extarticle 文档类。"
  fi

  pandoc "$input" -o "$output" --pdf-engine=xelatex \
    -V documentclass="$doc_class" \
    -V CJKmainfont="Yozai Font" \
    -V mainfont="FiraCode Nerd Font" \
    -V fontsize="$size" \
    -V geometry:margin=2cm   # ← 添加这一行，减小页边距

  if [ $? -eq 0 ]; then
    echo "✅ 转换成功！文件生成于: $output"
  else
    echo "❌ 转换失败，请检查字体名称或 Markdown 语法。"
  fi
}

# 覆盖 uv 命令，使得 uv init 自动添加 [tool.pyright]
uv() {
  if [[ "$1" == "init" ]]; then
    shift
    local init_args=("$@")

    echo "🚀 执行: uv init ${init_args[*]}"
    if ! command uv init "${init_args[@]}"; then
      echo "❌ uv init 执行失败"
      return 1
    fi

    local project_dir="."
    for arg in "${init_args[@]}"; do
      if [[ "$arg" != -* ]]; then
        project_dir="$arg"
        break
      fi
    done

    if [[ ! -d "$project_dir" ]]; then
      echo "⚠️ 警告: 项目目录 '$project_dir' 不存在，跳过 pyright 配置"
      return 0
    fi

    local toml_path="$project_dir/pyproject.toml"
    if [[ ! -f "$toml_path" ]]; then
      echo "⚠️ 警告: 未找到 $toml_path，跳过 pyright 配置"
      return 0
    fi

    if grep -q "^\[tool\.pyright\]" "$toml_path"; then
      echo "ℹ️ pyright 配置已存在，无需重复添加"
      return 0
    fi

    {
      echo ""
      echo "[tool.pyright]"
      echo "venvPath = \".\""
      echo "venv = \".venv\""
    } >>"$toml_path"

    echo "✅ 已自动添加 pyright 配置到 $toml_path"
  else
    command uv "$@"
  fi
}
