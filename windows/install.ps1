<#
.SYNOPSIS
    Installs VibeVoice (community fork) on Windows.
.DESCRIPTION
    Checks prerequisites, clones the repo, creates a virtualenv, installs the
    right PyTorch build for your hardware, then installs VibeVoice and verifies
    the result. Safe to re-run - it skips work that is already done.
.PARAMETER InstallDir
    Where to install. Defaults to the folder this script lives in.
.PARAMETER ForceCpu
    Install the CPU build of PyTorch even if an NVIDIA GPU is detected.
.PARAMETER CudaIndex
    PyTorch wheel index for the CUDA build. Override if your driver needs a
    different CUDA version (e.g. cu121, cu126, cu128).
.PARAMETER CheckOnly
    Only report what was detected (git, Python, GPU) and exit without
    downloading anything. Useful as a first run.
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\install.ps1
#>
[CmdletBinding()]
param(
    [string]$InstallDir = $PSScriptRoot,
    [switch]$ForceCpu,
    [string]$CudaIndex = "https://download.pytorch.org/whl/cu124",
    [switch]$CheckOnly
)

$ErrorActionPreference = "Stop"
# Let this script report native-command failures itself, with a useful message,
# instead of PowerShell 7.4+ throwing a bare exception on any non-zero exit.
if (Test-Path Variable:PSNativeCommandUseErrorActionPreference) {
    $PSNativeCommandUseErrorActionPreference = $false
}

$REPO_URL = "https://github.com/vibevoice-community/VibeVoice"

function Write-Step { param($m) Write-Host "`n==> $m" -ForegroundColor Cyan }
function Write-Ok   { param($m) Write-Host "    OK: $m" -ForegroundColor Green }
function Write-Warn { param($m) Write-Host "    WARNING: $m" -ForegroundColor Yellow }
function Fail {
    param($Problem, $Fix)
    Write-Host "`nSTOPPED: $Problem" -ForegroundColor Red
    if ($Fix) { Write-Host "`nHow to fix:`n$Fix" -ForegroundColor Yellow }
    exit 1
}

# ---------------------------------------------------------------- prereqs ---
Write-Step "Checking prerequisites"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Fail "git is not installed (or not on your PATH)." @'
  1. Download it from https://git-scm.com/download/win
  2. Run the installer and accept every default.
  3. CLOSE this window, open a NEW PowerShell, and run this script again.
     (A new window is required before PATH changes take effect.)
'@
}
Write-Ok "git found"

# Find a Python we trust. $pyExe plus $pyPre lets us support both the "py"
# launcher ("py -3.12") and a bare "python" without index gymnastics.
$pyExe = $null
$pyPre = @()
if (Get-Command py -ErrorAction SilentlyContinue) {
    foreach ($v in @("3.12", "3.11", "3.10")) {
        & py "-$v" -c "import sys" 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) { $pyExe = "py"; $pyPre = @("-$v"); break }
    }
}
if (-not $pyExe) {
    $cmd = Get-Command python -ErrorAction SilentlyContinue
    # Windows ships a stub python.exe that just opens the Microsoft Store.
    if ($cmd -and $cmd.Source -notlike "*WindowsApps*") {
        $ver = & python -c "import sys; print('%d.%d' % sys.version_info[:2])" 2>$null
        if ($LASTEXITCODE -eq 0) {
            if ([version]$ver -lt [version]"3.9") {
                Fail "Python $ver is too old. VibeVoice needs 3.9+ (3.12 recommended)." "Install Python 3.12 from https://www.python.org/downloads/"
            }
            if ([version]$ver -ge [version]"3.13") {
                Write-Warn "Python $ver is newer than these pinned dependencies are tested against. If the install fails, install Python 3.12 and re-run."
            }
            $pyExe = "python"
        }
    }
}
if (-not $pyExe) {
    Fail "No usable Python installation found." @'
  1. Download Python 3.12 from https://www.python.org/downloads/
  2. IMPORTANT: on the first installer screen, tick "Add python.exe to PATH".
  3. Finish the install, CLOSE this window, open a NEW PowerShell,
     and run this script again.
'@
}
Write-Ok "Python found: $(& $pyExe @pyPre -c 'import sys; print(sys.version.split()[0])')"

# ------------------------------------------------------------------- gpu ----
Write-Step "Checking for an NVIDIA GPU"
$useCuda = $false
$gpuNote = ""

if ($ForceCpu) {
    $gpuNote = "-ForceCpu was passed, so the CPU build will be installed."
} elseif (Get-Command nvidia-smi -ErrorAction SilentlyContinue) {
    $smi = & nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>$null
    if ($LASTEXITCODE -eq 0 -and $smi) {
        $useCuda = $true
        $first = (@($smi))[0].Trim()
        Write-Ok "NVIDIA GPU detected: $first"
        if ($first -match '(\d+)\s*MiB') {
            $vramGb = [math]::Round([int]$Matches[1] / 1024, 1)
            if ($vramGb -lt 7.5) {
                Write-Warn "This GPU reports $vramGb GB of VRAM; the 1.5B model wants about 8 GB. If generation dies with an out-of-memory error, re-run install.ps1 with -ForceCpu."
            }
        }
    }
}

if (-not $useCuda -and -not $ForceCpu) {
    # Guard on the cmdlet existing: Get-CimInstance is Windows-only, and a
    # missing cmdlet is a command-not-found error that -ErrorAction cannot
    # suppress, which would abort the whole script.
    $gpus = ""
    if (Get-Command Get-CimInstance -ErrorAction SilentlyContinue) {
        try {
            $gpus = (Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue |
                     Select-Object -ExpandProperty Name) -join ", "
        } catch { $gpus = "" }
    }
    if ($gpus) {
        $gpuNote = "No usable NVIDIA CUDA GPU found. Graphics adapters detected: $gpus"
    } else {
        $gpuNote = "No usable NVIDIA CUDA GPU found."
    }
}

if ($useCuda) {
    $torchIndex = $CudaIndex
    Write-Ok "Installing the CUDA build of PyTorch."
} else {
    $torchIndex = "https://download.pytorch.org/whl/cpu"
    Write-Warn $gpuNote
    Write-Host @'

    Installing the CPU build. Everything will work, but generation will be
    SLOW - expect minutes of computing per sentence of audio, versus seconds
    on an NVIDIA GPU. Fine for trying it out, painful for real use.

'@ -ForegroundColor Yellow
}

if ($CheckOnly) {
    Write-Host ""
    Write-Host "-CheckOnly was passed, so nothing was downloaded or installed." -ForegroundColor Cyan
    Write-Host "Re-run without -CheckOnly to do the real install."
    Write-Host ""
    exit 0
}

# ----------------------------------------------------------------- clone ----
$repoDir = Join-Path $InstallDir "VibeVoice"
Write-Step "Getting the VibeVoice source"
if (Test-Path (Join-Path $repoDir ".git")) {
    Write-Ok "Already cloned at $repoDir"
    git -C $repoDir pull --ff-only
    if ($LASTEXITCODE -ne 0) { Write-Warn "Could not update the existing clone; continuing with the version you already have." }
} else {
    git clone $REPO_URL $repoDir
    if ($LASTEXITCODE -ne 0) { Fail "git clone failed." "Check your internet connection, then run this script again." }
    Write-Ok "Cloned to $repoDir"
}

# ------------------------------------------------------------------ venv ----
$venv   = Join-Path $InstallDir ".venv"
$venvPy = Join-Path $venv "Scripts\python.exe"
Write-Step "Setting up an isolated Python environment"
if (-not (Test-Path $venvPy)) {
    & $pyExe @pyPre -m venv $venv
    if (-not (Test-Path $venvPy)) { Fail "Could not create the virtual environment at $venv." "Make sure you can write to this folder (try a path under your user folder, not Program Files), then re-run." }
}
Write-Ok "Environment ready at $venv"

& $venvPy -m pip install --upgrade pip setuptools wheel
if ($LASTEXITCODE -ne 0) { Fail "Could not upgrade pip." "Check your internet connection and re-run." }

# ----------------------------------------------------------------- torch ----
# Install torch FIRST, from the hardware-specific index. VibeVoice's pyproject
# asks for a bare "torch", so pip would otherwise take the default PyPI wheel,
# which on Windows is CPU-only - silently leaving you with no GPU support.
Write-Step "Installing PyTorch (the big one - several GB, please be patient)"
& $venvPy -m pip install torch --index-url $torchIndex
if ($LASTEXITCODE -ne 0) {
    Fail "PyTorch installation failed." @'
  The usual cause is a CUDA build that does not match your driver.

  Try the CPU build:
      powershell -ExecutionPolicy Bypass -File .\install.ps1 -ForceCpu

  Or a different CUDA version (see https://pytorch.org/get-started/locally/):
      powershell -ExecutionPolicy Bypass -File .\install.ps1 -CudaIndex https://download.pytorch.org/whl/cu121
'@
}
Write-Ok "PyTorch installed"

# ------------------------------------------------------------- vibevoice ----
Write-Step "Installing VibeVoice and its dependencies"
& $venvPy -m pip install -e $repoDir
if ($LASTEXITCODE -ne 0) { Fail "VibeVoice installation failed." "Scroll up to the first line starting with ERROR - it names the package that failed. Send that line to Claude." }
Write-Ok "VibeVoice installed"

# ---------------------------------------------------------------- verify ----
Write-Step "Verifying the installation"
& $venvPy -c @'
import torch, vibevoice
print("    vibevoice  :", vibevoice.__file__)
print("    torch      :", torch.__version__)
print("    GPU usable :", torch.cuda.is_available())
if torch.cuda.is_available():
    print("    GPU        :", torch.cuda.get_device_name(0))
from vibevoice.modular.modeling_vibevoice_inference import VibeVoiceForConditionalGenerationInference
print("    model class imports OK")
'@
if ($LASTEXITCODE -ne 0) { Fail "VibeVoice installed but could not be imported." "Copy the error above and send it to Claude." }

Write-Host "`n================ INSTALL COMPLETE ================" -ForegroundColor Green
Write-Host @'

Next step - start the demo:

    powershell -ExecutionPolicy Bypass -File .\run_demo.ps1

The first launch downloads about 5.4 GB of model weights, so it will look
frozen for a while before the web page appears. It is not frozen.

'@
