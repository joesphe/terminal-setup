# terminal-setup-minimal

这是一个精简版终端环境包，只保留两类核心能力：

- 终端美化
- Shell 补全与交互增强

本版保留：

- Ghostty 配置
- Starship 提示符
- MesloLGS NF Nerd Font
- Fish Shell 支持
- Zsh 以及 `zsh-autosuggestions`、`zsh-syntax-highlighting`、`zsh-completions`

本版移除：

- `eza`、`tldr`、`delta`、`lazygit` 等额外 CLI 工具
- `zoxide`、`fzf` 这类非核心增强
- `fnm` / Node 相关能力
- `zellij` 等可选组件
- 预览图片等非运行时资源

使用方式：

```bash
./setup.sh
./setup.sh --fish
./setup.sh --zsh
./setup.sh --dry-run
```

说明：

- 字体仍然保留，因为 Starship 和 Nerd Font 图标显示依赖它。
- Linux 下不会自动安装 Ghostty，只提供配置文件。
- WSL 下建议在 Windows 侧使用 Ghostty 或 Windows Terminal。
