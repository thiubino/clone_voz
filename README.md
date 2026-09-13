# clone_voz

Setup for [VibeVoice](https://github.com/vibevoice-community/VibeVoice) — the
community-maintained fork of Microsoft's long-form, multi-speaker conversational
TTS model.

**On Windows? Follow [WINDOWS.md](WINDOWS.md)** — it has a scripted installer
and a step-by-step walkthrough. The instructions below are for Linux/macOS.

## Setup

```bash
./setup.sh
```

That runs the upstream install steps inside a local virtualenv:

```bash
git clone https://github.com/vibevoice-community/VibeVoice
python3 -m venv .venv
.venv/bin/pip install -e VibeVoice
```

The clone lands in `./VibeVoice/` and is git-ignored — this repo holds the setup,
not a vendored copy of upstream.

The virtualenv is not optional. VibeVoice depends on `aiortc`, which requires a
newer `cryptography` than the Debian-packaged one, and installing into the system
interpreter fails with:

```
ERROR: Cannot uninstall cryptography 41.0.7, RECORD file not found.
Hint: The package was installed by debian.
```

## Verify

```bash
source .venv/bin/activate
python -c "import vibevoice; print(vibevoice.__file__)"
```

## Models

Weights are downloaded from Hugging Face on first use, not by `setup.sh`:

| Model | Speakers | Generation length |
|-------|----------|-------------------|
| `vibevoice/VibeVoice-1.5B` | up to 4 | ~90 min |
| `vibevoice/VibeVoice-7B` | up to 4 | ~45 min |
| `microsoft/VibeVoice-Realtime-0.5B` | 1 | real-time streaming |

## Requirements

- Python >= 3.9 (tested on 3.11)
- A CUDA GPU for practical inference. The package installs and imports on CPU,
  but generation is impractically slow without a GPU.

## Running the Gradio demo

```bash
source .venv/bin/activate
python VibeVoice/demo/gradio_demo.py --model_path vibevoice/VibeVoice-1.5B
```

Useful flags: `--device cuda|mps|cpu` (auto-detected), `--port`, `--share`
(public Gradio tunnel), `--checkpoint_path` (LoRA adapters).

Two things this needs that a sandboxed environment may not have:

1. **Network access to `huggingface.co`**, to download the weights on first run.
   A restricted egress policy shows up as
   `ProxyError('Tunnel connection failed: 403 Forbidden')`. Pre-download the
   weights on an unrestricted machine and pass a local directory to
   `--model_path` to work offline.
2. **A browser-reachable host.** Without `--share` the demo binds to
   `127.0.0.1`, which is unreachable from outside a remote container.

## Usage

See upstream docs after cloning: `VibeVoice/README.md`, `VibeVoice/EXAMPLES.md`,
and `VibeVoice/FINETUNING.md`.
