# terminal-setup-minimal

A slimmed-down terminal setup bundle focused on two things:

- terminal beautification
- shell completion and interactive feedback

What this edition keeps:

- Ghostty config
- Starship prompt
- MesloLGS NF Nerd Font
- Fish shell support
- Zsh with `zsh-autosuggestions`, `zsh-syntax-highlighting`, and `zsh-completions`

What this edition removes:

- bundled CLI extras such as `eza`, `tldr`, `delta`, and `lazygit`
- smart-cd and fuzzy-finder extras such as `zoxide` and `fzf`
- Node tooling such as `fnm`
- optional multiplexer setup such as `zellij`
- preview images and other non-runtime assets

Usage:

```bash
./setup.sh
./setup.sh --fish
./setup.sh --zsh
./setup.sh --dry-run
```

Notes:

- Fonts are still included because prompt glyphs depend on Nerd Font support.
- On Linux, Ghostty is not installed automatically; only the config is provided.
- On WSL, use Ghostty or Windows Terminal on the Windows side.
