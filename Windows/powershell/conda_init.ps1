$Env:CONDA_EXE = "C:\Users\Administrator\Miniconda3\Scripts\conda.exe"
$Env:_CONDA_EXE = "C:\Users\Administrator\Miniconda3\Scripts\conda.exe"
$Env:_CE_M = $null
$Env:_CE_CONDA = $null
$Env:CONDA_PYTHON_EXE = "C:\Users\Administrator\Miniconda3\python.exe"
$Env:_CONDA_ROOT = "C:\Users\Administrator\Miniconda3"
$CondaModuleArgs = @{ChangePs1 = $True}

Import-Module "$Env:_CONDA_ROOT\shell\condabin\Conda.psm1" -ArgumentList $CondaModuleArgs

Remove-Variable CondaModuleArgs
