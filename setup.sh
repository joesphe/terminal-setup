#!/bin/bash
#
# terminal-setup-minimal — terminal beautification + shell completion
#
# Platforms: macOS, Debian/Ubuntu, Windows (via WSL)
# Keeps: Ghostty config, Starship, MesloLGS NF, Fish/Zsh, Zsh completion plugins
# Removes: extra CLI tools, Git UI tools, Node tooling, optional multiplexers
#
# Usage:
#   ./setup.sh
#   ./setup.sh --fish
#   ./setup.sh --zsh
#   ./setup.sh --dry-run
#

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

DRY_RUN=false
SHELL_CHOICE=""

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

run_cmd() {
    if $DRY_RUN; then
        echo -e "${YELLOW}[DRY-RUN]${NC} $*"
    else
        "$@"
    fi
}

has_cmd() {
    command -v "$1" &>/dev/null
}

detect_os() {
    case "$(uname -s)" in
        Darwin) echo "macos" ;;
        Linux)
            if grep -qiE '(microsoft|wsl)' /proc/version 2>/dev/null; then
                echo "wsl"
            elif [[ -f /etc/debian_version ]] || grep -qi 'debian\|ubuntu' /etc/os-release 2>/dev/null; then
                echo "debian"
            else
                echo "unsupported"
            fi
            ;;
        *) echo "unsupported" ;;
    esac
}

pkg_install() {
    local pkg="$1"
    case "$OS" in
        macos)
            if brew list "$pkg" &>/dev/null; then
                success "$pkg already installed"
            else
                info "Installing $pkg..."
                run_cmd brew install "$pkg"
                success "$pkg installed"
            fi
            ;;
        debian|wsl)
            if dpkg -s "$pkg" &>/dev/null 2>&1; then
                success "$pkg already installed"
            else
                info "Installing $pkg..."
                run_cmd sudo apt-get install -y "$pkg"
                success "$pkg installed"
            fi
            ;;
    esac
}

for arg in "$@"; do
    case "$arg" in
        --fish) SHELL_CHOICE="fish" ;;
        --zsh) SHELL_CHOICE="zsh" ;;
        --dry-run) DRY_RUN=true ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_DIR="$SCRIPT_DIR/configs"
FONTS_DIR="$SCRIPT_DIR/fonts"
OS="$(detect_os)"

case "$OS" in
    macos|debian|wsl) ;;
    *) error "Unsupported OS: $(uname -s)" ;;
esac

if [[ -z "$SHELL_CHOICE" ]]; then
    echo ""
    echo -e "${BOLD}Which shell do you want to use?${NC}"
    echo -e "  ${GREEN}1)${NC} ${BOLD}Fish${NC}"
    echo -e "  ${GREEN}2)${NC} ${BOLD}Zsh${NC}"
    while true; do
        read -rp "Choose [1/2]: " choice
        case "$choice" in
            1|fish) SHELL_CHOICE="fish"; break ;;
            2|zsh) SHELL_CHOICE="zsh"; break ;;
            *) echo "Please enter 1 or 2." ;;
        esac
    done
fi

echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo -e "${BOLD}  📦 Step 1/6: Base Packages${NC}"
echo -e "${BOLD}══════════════════════════════════════════${NC}"

case "$OS" in
    macos)
        if ! has_cmd brew; then
            info "Installing Homebrew..."
            run_cmd /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        success "Homebrew ready"
        ;;
    debian|wsl)
        info "Updating apt package index..."
        run_cmd sudo apt-get update
        pkg_install curl
        pkg_install git
        pkg_install unzip
        success "apt ready"
        ;;
esac

echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo -e "${BOLD}  👻 Step 2/6: Terminal Styling${NC}"
echo -e "${BOLD}══════════════════════════════════════════${NC}"

case "$OS" in
    macos)
        if [[ ! -d "/Applications/Ghostty.app" ]]; then
            info "Installing Ghostty..."
            run_cmd brew install --cask ghostty
        fi
        success "Ghostty ready"
        ;;
    debian)
        warn "Ghostty on Linux is not installed automatically."
        echo -e "  Install manually if needed: ${BOLD}https://ghostty.org/docs/install${NC}"
        ;;
    wsl)
        info "WSL detected. Use Ghostty or Windows Terminal on the Windows side."
        ;;
esac

echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo -e "${BOLD}  🔤 Step 3/6: Nerd Font${NC}"
echo -e "${BOLD}══════════════════════════════════════════${NC}"

case "$OS" in
    macos) FONT_DIR="$HOME/Library/Fonts" ;;
    debian|wsl) FONT_DIR="$HOME/.local/share/fonts" ;;
esac

run_cmd mkdir -p "$FONT_DIR"

MESLO_FONTS=(
    "MesloLGS NF Regular.ttf"
    "MesloLGS NF Bold.ttf"
    "MesloLGS NF Italic.ttf"
    "MesloLGS NF Bold Italic.ttf"
)

for font in "${MESLO_FONTS[@]}"; do
    if [[ -f "$FONTS_DIR/$font" ]]; then
        run_cmd cp "$FONTS_DIR/$font" "$FONT_DIR/$font"
    else
        warn "Missing bundled font: $font"
    fi
done

if [[ "$OS" == "debian" || "$OS" == "wsl" ]]; then
    run_cmd fc-cache -f "$FONT_DIR"
fi
success "Fonts installed"

echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo -e "${BOLD}  🐚 Step 4/6: Shell + Completion${NC}"
echo -e "${BOLD}══════════════════════════════════════════${NC}"

if [[ "$SHELL_CHOICE" == "fish" ]]; then
    if [[ "$OS" == "macos" ]]; then
        pkg_install fish
    else
        if ! has_cmd fish; then
            if [[ -f /etc/lsb-release ]] && grep -qi ubuntu /etc/lsb-release 2>/dev/null; then
                run_cmd sudo apt-add-repository -y ppa:fish-shell/release-3
                run_cmd sudo apt-get update
            fi
            run_cmd sudo apt-get install -y fish
        fi
        success "fish ready"
    fi

    FISH_PATH="$(which fish)"
    if ! grep -qxF "$FISH_PATH" /etc/shells 2>/dev/null; then
        echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
    fi
    if [[ "${SHELL:-}" != "$FISH_PATH" ]]; then
        run_cmd chsh -s "$FISH_PATH"
    fi
else
    if [[ "$OS" == "macos" ]]; then
        pkg_install zsh-autosuggestions
        pkg_install zsh-syntax-highlighting
        pkg_install zsh-completions
    else
        if ! has_cmd zsh; then
            run_cmd sudo apt-get install -y zsh
        fi
        run_cmd sudo apt-get install -y zsh-autosuggestions zsh-syntax-highlighting || true
        if ! dpkg -s zsh-completions &>/dev/null 2>&1; then
            info "Installing zsh-completions..."
            run_cmd sudo apt-get install -y zsh-completions || true
        fi
    fi

    ZSH_PATH="$(which zsh)"
    if [[ "${SHELL:-}" != "$ZSH_PATH" ]]; then
        run_cmd chsh -s "$ZSH_PATH"
    fi
    success "zsh and plugins ready"
fi

echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo -e "${BOLD}  🚀 Step 5/6: Starship${NC}"
echo -e "${BOLD}══════════════════════════════════════════${NC}"

if has_cmd starship; then
    success "Starship already installed"
else
    case "$OS" in
        macos)
            run_cmd brew install starship
            ;;
        debian|wsl)
            run_cmd sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- --yes
            ;;
    esac
    success "Starship installed"
fi

echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo -e "${BOLD}  📦 Step 6/6: Deploy Configs${NC}"
echo -e "${BOLD}══════════════════════════════════════════${NC}"

deploy_ghostty_config() {
    local ghostty_config_dir
    case "$OS" in
        macos) ghostty_config_dir="$HOME/Library/Application Support/com.mitchellh.ghostty" ;;
        debian|wsl) ghostty_config_dir="$HOME/.config/ghostty" ;;
    esac

    run_cmd mkdir -p "$ghostty_config_dir"
    case "$OS" in
        macos)
            run_cmd cp "$CONFIGS_DIR/ghostty.config" "$ghostty_config_dir/config.ghostty"
            ;;
        debian|wsl)
            run_cmd cp "$CONFIGS_DIR/ghostty.config" "$ghostty_config_dir/config"
            ;;
    esac
    success "Ghostty config deployed"
}

run_cmd mkdir -p "$HOME/.config"
deploy_ghostty_config
run_cmd cp "$CONFIGS_DIR/starship.toml" "$HOME/.config/starship.toml"
success "Starship config deployed"

if [[ "$SHELL_CHOICE" == "fish" ]]; then
    FISH_CONFIG_DIR="$HOME/.config/fish"
    run_cmd mkdir -p "$FISH_CONFIG_DIR"
    run_cmd cp "$CONFIGS_DIR/config.fish" "$FISH_CONFIG_DIR/config.fish"
    if [[ "$OS" != "macos" ]]; then
        sed -i 's|/opt/homebrew/bin/starship|starship|g' "$FISH_CONFIG_DIR/config.fish"
        sed -i 's|fish_add_path /opt/homebrew/bin|# Linux uses system PATH for starship|g' "$FISH_CONFIG_DIR/config.fish"
    fi
    success "Fish config deployed"
else
    run_cmd cp "$CONFIGS_DIR/.zshrc" "$HOME/.zshrc"
    if [[ "$OS" != "macos" ]]; then
        sed -i 's|export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:\$PATH"|export PATH="$HOME/.local/bin:$PATH"|' "$HOME/.zshrc"
        sed -i 's|/opt/homebrew/share/zsh-syntax-highlighting/|/usr/share/zsh-syntax-highlighting/|g' "$HOME/.zshrc"
        sed -i 's|/opt/homebrew/share/zsh-autosuggestions/|/usr/share/zsh-autosuggestions/|g' "$HOME/.zshrc"
        sed -i 's|/opt/homebrew/share/zsh-completions|/usr/share/zsh-completions|g' "$HOME/.zshrc"
    fi
    success "Zsh config deployed"
fi

echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}  ✅ Done${NC}"
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo ""
echo -e "  Kept in this minimal edition:"
echo -e "    • Ghostty config"
echo -e "    • MesloLGS NF nerd font"
echo -e "    • Starship prompt"
echo -e "    • Fish or Zsh shell"
echo -e "    • Zsh autosuggestions / syntax highlighting / completions"
echo ""
echo -e "  Removed from this edition:"
echo -e "    • eza / bat / fd / rg / btop / jq / tldr"
echo -e "    • zoxide / fnm / Node / lazygit / delta / zellij"
echo ""
