# Music Generation Workspace

This workspace generates procedural music using Python + NumPy.

## 1) Set up the environment
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

## 2) Run
```bash
python3 music_gen.py
```

Output file: `lofi.wav`

## Customization

Edit the constants at the top of `music_gen.py` (tempo, bars, progression) to change the style.
