# Running VibeVoice on Windows


**Prefer a web page you can read on the Windows machine?**
<https://claude.ai/code/artifact/38baf99d-a942-44ef-a5b8-a5c6640cc8c3>

A step-by-step guide. You do not need to understand any of the commands —
copy, paste, press Enter.

## What you need first

**Python 3.12** and **git**. If you already have them, skip to *Install*.

1. **Python** — <https://www.python.org/downloads/>
   On the first installer screen, tick **"Add python.exe to PATH"** before
   clicking Install. This one checkbox causes most "python is not recognized"
   problems when missed.
2. **Git** — <https://git-scm.com/download/win>
   Accept every default.

After installing either one, **close every PowerShell window and open a new
one**. PATH changes only apply to newly opened windows.

## Install

1. Press `Windows key`, type `powershell`, press Enter.
2. Choose a folder and download the setup scripts:

   ```powershell
   cd $HOME
   git clone https://github.com/thiubino/clone_voz.git
   cd clone_voz\windows
   ```

3. Check your machine before downloading gigabytes:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\install.ps1 -CheckOnly
   ```

   This prints what it found — Python, git, and whether you have a usable
   NVIDIA GPU — and installs nothing.

4. Run the real install:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\install.ps1
   ```

   Expect 10-30 minutes; PyTorch alone is several GB. The script picks the
   GPU or CPU build of PyTorch for you, and ends with `INSTALL COMPLETE`.

## Run it

```powershell
powershell -ExecutionPolicy Bypass -File .\run_demo.ps1
```

The **first** run downloads about 5.4 GB of model weights and will look
frozen for several minutes. It is not frozen. Later runs skip this.

When you see:

```
Running on local URL:  http://127.0.0.1:7860
```

open `http://127.0.0.1:7860` in your browser. Pick a voice, type dialogue,
press Generate. Press `Ctrl+C` in PowerShell to stop the demo.

## About speed

Generation speed depends entirely on your hardware:

| Hardware | What to expect |
|---|---|
| NVIDIA GPU, 8 GB+ VRAM | Comfortable. Seconds per sentence. |
| NVIDIA GPU, under 8 GB | May run out of memory. Re-run install with `-ForceCpu`. |
| No NVIDIA GPU (CPU) | Works, but minutes of computing per sentence. |

On CPU, start with a **single short sentence** to confirm everything works
before attempting anything long. A full podcast script on CPU can take hours.

CPU also needs about 11 GB of free RAM, because the model runs at full
precision there. On a 16 GB machine, close other applications first.

## If something goes wrong

**"running scripts is disabled on this system"**
Use the full command including `-ExecutionPolicy Bypass`, exactly as written
above. That flag applies to the single command only and changes nothing
permanently.

**"python is not recognized"**
Python is not on your PATH. Reinstall it with **"Add python.exe to PATH"**
ticked, then open a new PowerShell window.

**A red `flash_attention_2` error, then it keeps going**
Normal and harmless. `flash-attn` is not available on Windows, so VibeVoice
falls back to a slower built-in attention implementation and continues.

**`Cannot uninstall cryptography` / permission errors**
You are installing outside the virtualenv. Always use the scripts, or
activate the environment first with `.venv\Scripts\Activate.ps1`.

**Out of memory during generation**
Use shorter text, fewer speakers, or reinstall on CPU with:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -ForceCpu
```

## Useful options

```powershell
# Force CPU even if you have a GPU
powershell -ExecutionPolicy Bypass -File .\run_demo.ps1 -Device cpu

# Use the larger, better, slower 7B model (needs ~16 GB VRAM)
powershell -ExecutionPolicy Bypass -File .\run_demo.ps1 -Model vibevoice/VibeVoice-7B

# Older NVIDIA driver? Pick a different CUDA build
powershell -ExecutionPolicy Bypass -File .\install.ps1 -CudaIndex https://download.pytorch.org/whl/cu121
```

`run_demo.ps1 -Share` creates a **public internet link** to your demo that
anyone can use while it runs. You do not need it to use VibeVoice on your own
machine — only add it if you specifically want to share access with someone
else.

## A note on what this model can do

VibeVoice clones voices from short audio samples. Only clone a voice you own
or have permission to use, and don't present synthetic audio as a real
recording of someone. Upstream ships audible disclaimers in its outputs for
this reason.
