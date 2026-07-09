# Invoke-Expression (&starship init powershell)
# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"

}

function y {
    $tmp = (New-TemporaryFile).FullName
    yazi.exe @args --cwd-file="$tmp"
    $cwd = Get-Content -Path $tmp -Encoding UTF8
    if ($cwd -and $cwd -ne $PWD.Path -and (Test-Path -LiteralPath $cwd -PathType Container)) {
        Set-Location -LiteralPath (Resolve-Path -LiteralPath $cwd).Path
    }
    Remove-Item -Path $tmp
}
$env:FZF_DEFAULT_COMMAND = 'fd --type f --hidden --follow --exclude .git'



function winget {
    $wingetPath = (Get-Command winget.exe -CommandType Application -ErrorAction SilentlyContinue).Source
    if (-not $wingetPath) {
        Write-Error "winget.exe not found."
        return
    }

    # 执行原始 winget 命令，屏蔽错误输出（保持原有行为）
    & $wingetPath $args 2>$null

    # 如果是 install/upgrade/uninstall，则导出列表
    if ($args[0] -match "install|upgrade|uninstall") {
        # Derive repo root from profile symlink target: $PROFILE is symlinked
        # from <repo>/powershell/Microsoft.PowerShell_profile.ps1, so the
        # real directory is <repo>/powershell. One level up = repo root.
        $repoRoot = Split-Path (Get-Item $PROFILE).DirectoryName
        $exportPath = Join-Path $repoRoot "packages.winget.json"
        $dir = Split-Path $exportPath -Parent
        if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

        # 英文提示：导出中...
        Write-Host "Exporting winget package list..." -ForegroundColor Yellow

        # 静默导出：重定向所有输出（包括进度、结果、错误）到 $null
        & $wingetPath export -o $exportPath --include-versions --accept-source-agreements *>$null

        # 英文提示：导出成功
        Write-Host "Winget package list exported to $exportPath" -ForegroundColor Green
    }
}

function tmux { wsl tmux $args }
. (Join-Path (Split-Path $PROFILE) "starship_init.ps1")
. (Join-Path (Split-Path $PROFILE) "conda_lazy.ps1")

Set-Alias -Name n -Value nvim 
function f { fastfetch | meow }
Set-Alias -Name s -Value SumatraPDF  
Set-Alias -Name c -Value  clear  
Set-Alias -Name sudo -Value  gsudo  
function tn {tmux new}
function ta {tmux attach -t $args}
function tl {tmux ls}

