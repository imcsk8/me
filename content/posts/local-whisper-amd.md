+++
title = 'Local Whisper Amd'
date = 2024-12-08T22:54:54-06:00
draft = false
summary = "Quick tutorial for text to speech using a local whisper instance"
+++

# Local Text to Speech

[Whisper](https://openai.com/research/whisper) is a text to speech recognition system
developed by OpenAI. It uses a transformer architecture to generate text from audio files.

## Install dependencies



```bash
sudo dnf install -y python3-whisper.noarch python3-ipywidgets.noarch \
  python3-torch-rocm-gfx9 python3-torch python3-torchvision
```

Unfortunately Fedora does not have all the dependencies we need so we have to create a
`requirements.txt` file.


```bash
cat <<EOF > requirements.txt
datasets
transformers
numba
pysoundfile
EOF
```

## Translate test data

```python
#!/usr/bin/python

import torch
from transformers import pipeline

TEST_DIR="test_data"
TEST_FILE=f"{TEST_DIR}/preamble.wav"

device = "cuda:0" if torch.cuda.is_available() else "cpu"

pipe = pipeline(
  "automatic-speech-recognition",
  model="openai/whisper-medium.en",
  chunk_length_s=30,
  device=device,
)

transcription = pipe(TEST_FILE)['text']
print(transcription)
```


# References

* https://rocm.blogs.amd.com/artificial-intelligence/whisper/README.html
