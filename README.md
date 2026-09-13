# clone_voz

Setup for [VibeVoice](https://github.com/vibevoice-community/VibeVoice) — the
community-maintained fork of Microsoft's long-form, multi-speaker conversational
TTS model.

## Setup

```bash
./setup.sh
```

That runs the upstream install steps:

```bash
git clone https://github.com/vibevoice-community/VibeVoice
cd VibeVoice
pip install -e .
```

The clone lands in `./VibeVoice/` and is git-ignored — this repo holds the setup,
not a vendored copy of upstream.

## Verify

```bash
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

- Python >= 3.9
- A CUDA GPU for practical inference. The package installs and imports on CPU,
  but generation is impractically slow without a GPU.

## Usage

See upstream docs after cloning: `VibeVoice/README.md`, `VibeVoice/EXAMPLES.md`,
and `VibeVoice/FINETUNING.md`.
