# Determine Miniconda root: use %CONDA_EXE% if set, otherwise derive from HOME
$CondaRoot = if ($Env:CONDA_EXE) {
    Split-Path (Split-Path $Env:CONDA_EXE)
} elseif (Test-Path "$HOME\Miniconda3") {
    "$HOME\Miniconda3"
} else {
    $candidates = @("$HOME\Miniconda3", "C:\Miniconda3", "C:\ProgramData\Miniconda3")
    $found = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $found) { throw "Miniconda3 not found. Set `$Env:CONDA_EXE or install Miniconda3." }
    $found
}

$Env:CONDA_EXE = Join-Path $CondaRoot "Scripts\conda.exe"
$Env:_CONDA_EXE = $Env:CONDA_EXE
$Env:_CE_M = $null
$Env:_CE_CONDA = $null
$Env:CONDA_PYTHON_EXE = Join-Path $CondaRoot "python.exe"
$Env:_CONDA_ROOT = $CondaRoot
$CondaModuleArgs = @{ChangePs1 = $True}

Import-Module "$Env:_CONDA_ROOT\shell\condabin\Conda.psm1" -ArgumentList $CondaModuleArgs

Remove-Variable CondaModuleArgs
