<#
.SYNOPSIS
    Starts the VibeVoice Gradio demo and opens it in your browser.
.PARAMETER Model
    Hugging Face model id, or a path to a local folder of weights.
.PARAMETER Device
    Force a device: cuda or cpu. Default: auto-detect.
.PARAMETER Share
    Create a public Gradio link. This exposes the demo to the internet for
    72 hours - only use it if you actually need remote access.
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\run_demo.ps1
#>
[CmdletBinding()]
param(
    [string]$InstallDir = $PSScriptRoot,
    [string]$Model = "vibevoice/VibeVoice-1.5B",
    [ValidateSet("", "cuda", "cpu")] [string]$Device = "",
    [switch]$Share
)

$ErrorActionPreference = "Stop"
$venvPy = Join-Path $InstallDir ".venv\Scripts\python.exe"
$demo   = Join-Path $InstallDir "VibeVoice\demo\gradio_demo.py"

if (-not (Test-Path $venvPy)) {
    Write-Host "VibeVoice is not installed yet." -ForegroundColor Red
    Write-Host "Run this first:  powershell -ExecutionPolicy Bypass -File .\install.ps1" -ForegroundColor Yellow
    exit 1
}
if (-not (Test-Path $demo)) {
    Write-Host "Could not find the demo at $demo" -ForegroundColor Red
    Write-Host "Re-run install.ps1 to restore the VibeVoice folder." -ForegroundColor Yellow
    exit 1
}

# Windows without Developer Mode cannot create symlinks, so the Hugging Face
# cache falls back to copying files. That works fine; silence the warning.
$env:HF_HUB_DISABLE_SYMLINKS_WARNING = "1"

$demoArgs = @($demo, "--model_path", $Model)
if ($Device) { $demoArgs += @("--device", $Device) }
if ($Share)  { $demoArgs += "--share" }

Write-Host "Starting VibeVoice..." -ForegroundColor Cyan
Write-Host "Model: $Model"
if (-not $Share) {
    Write-Host "`nWhen you see a line like 'Running on local URL: http://127.0.0.1:7860'," -ForegroundColor Yellow
    Write-Host "open that address in your browser. Press Ctrl+C here to stop the demo.`n" -ForegroundColor Yellow
} else {
    Write-Host "`n-Share is on: a PUBLIC link will be printed below. Anyone with that" -ForegroundColor Yellow
    Write-Host "link can use your demo until you stop it.`n" -ForegroundColor Yellow
}
Write-Host "The first run downloads ~5.4 GB of weights and will appear stuck. It is not.`n"

& $venvPy @demoArgs
