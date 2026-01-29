# Getting started with Codex CLI

For an overview of Codex CLI features, see [this documentation](https://developers.openai.com/codex/cli/features#running-in-interactive-mode).

## Tokonix wrapper (optional)
To run the CLI as `tokonix`, invoke the wrapper from the repo root:

```bash
./scripts/tokonix --help
```

If you want `tokonix` on your PATH, symlink it (macOS example):

```bash
ln -s "$(pwd)/scripts/tokonix" /opt/homebrew/bin/tokonix
```

## macOS overlay (experimental)
If you have the macOS overlay app available, you can launch it from the CLI:

```bash
tokonix overlay
```

To build the bundle before launching, run:

```bash
tokonix overlay --build
```

Set `TOKONIX_OVERLAY_APP` to point at a custom `.app` bundle, or pass `--app /path/to/Tokonix.app`.
By default the overlay uses its own profile home; set `TOKONIX_VOICE_OVERLAY_HOME` to reuse your CLI profile.
