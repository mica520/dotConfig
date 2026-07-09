# conda 占位函数 – 延迟加载初始化脚本
function global:conda {
    # 加载静态初始化脚本（首次执行）
    . (Join-Path (Split-Path $PROFILE) "conda_init.ps1")

    # 此时 conda 函数已被初始化脚本重新定义（或成为外部命令别名）
    # 转发当前命令参数给真正的 conda
     conda @args
}
