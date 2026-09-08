#!/usr/bin/env bash
#
# Installs this repository's configs into ~/.config by symlinking each directory
# under .config/ into place, so the repo stays the single copy: edit here and the
# change is live, and anything a program writes back (quickshell's state/*.json)
# lands in the repo where it is tracked.
#
# Re-running is how you replace an older install: whatever is sitting in the way
# is moved into a timestamped backup directory first, then linked fresh.
#
#     ./install.sh                 # link everything, after showing the plan
#     ./install.sh -n              # show the plan and stop
#     ./install.sh quickshell      # relink just one config
#     ./install.sh -p              # install packages first, then link
#
set -euo pipefail

# Resolved from the script's own location rather than $PWD, so it does the same
# thing whether or not you happen to be standing in the repo.
DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
SOURCE_DIR="$DOTFILES_DIR/.config"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_DIR="$CONFIG_DIR-backup/$(date +%Y%m%d-%H%M%S)"

# Everything below is in the official repositories, verified with `pacman -Si`.
REPO_PACKAGES=(
    hyprland
    quickshell
    awww
    kitty
    waybar
    wl-clipboard
    # Clipboard history for the quickshell launcher, fed by the wl-paste
    # watchers in the Hyprland autostart.
    cliphist
    # qalc, the calculator behind the launcher's math results.
    libqalculate
    # Read by scripts/themes/change-kitty-colors.bash to turn a theme's JSON
    # into kitty's colour overrides.
    jq
    nautilus
    brightnessctl
    playerctl
    wireplumber
    qt5ct
    qt6ct
    kvantum
    breeze-icons
    gsettings-desktop-schemas
    ttf-annotationmono-nerd
)

# AUR. yay and paru resolve repository packages too, so when one is present it
# gets the whole list and this split only matters for the pacman-only path.
AUR_PACKAGES=(
    wlogout
    hyprshot-git
    vicinae-bin
    adw-gtk3
    # "Material Symbols Outlined", used for the UI glyphs in the quickshell bar.
    ttf-material-symbols-variable-git
)

# ------------------------------------------------------------------- output --

if [[ -t 1 ]]; then
    BOLD=$'\e[1m'; DIM=$'\e[2m'; RED=$'\e[31m'; GREEN=$'\e[32m'
    YELLOW=$'\e[33m'; BLUE=$'\e[34m'; RESET=$'\e[0m'
else
    BOLD=''; DIM=''; RED=''; GREEN=''; YELLOW=''; BLUE=''; RESET=''
fi

info() { printf '%s\n' "$*"; }
warn() { printf '%swarning:%s %s\n' "$YELLOW" "$RESET" "$*" >&2; }
die()  { printf '%serror:%s %s\n' "$RED" "$RESET" "$*" >&2; exit 1; }

usage() {
    cat <<EOF
${BOLD}Usage:${RESET} ./install.sh [OPTIONS] [CONFIG...]

Symlinks this repository's configs into $CONFIG_DIR.

${BOLD}Arguments:${RESET}
  CONFIG...          Deploy only these configs. Default: all of them.
                     Available: $(available_configs | paste -sd' ')

${BOLD}Options:${RESET}
  -p, --packages     Install the packages these configs need, first.
  -n, --dry-run      Print the plan and exit without changing anything.
  -f, --force        Do not ask for confirmation.
      --no-backup    Delete what is in the way instead of backing it up.
  -h, --help         Show this message.
EOF
}

# -------------------------------------------------------------------- plans --

available_configs() {
    local path
    for path in "$SOURCE_DIR"/*/; do
        [[ -d $path ]] || continue
        basename -- "${path%/}"
    done
}

# What deploying one config would do, given what is already at its target:
# nothing if it is already the right symlink, otherwise link it, replacing
# whatever is there.
action_for() {
    local name="$1"
    local target="$CONFIG_DIR/$name"

    if [[ -L $target && "$(readlink -f -- "$target")" == "$SOURCE_DIR/$name" ]]; then
        printf 'skip'
    elif [[ -e $target || -L $target ]]; then
        printf 'replace'
    else
        printf 'link'
    fi
}

describe_target() {
    local target="$CONFIG_DIR/$1"

    if [[ -L $target ]]; then
        printf 'symlink to %s' "$(readlink -- "$target")"
    elif [[ -d $target ]]; then
        printf 'existing directory'
    else
        printf 'existing file'
    fi
}

deploy() {
    local name="$1" action="$2"
    local source="$SOURCE_DIR/$name"
    local target="$CONFIG_DIR/$name"

    case "$action" in
        skip) return ;;
        replace)
            if $backup; then
                mkdir -p "$BACKUP_DIR"
                mv -- "$target" "$BACKUP_DIR/$name"
            else
                rm -rf -- "$target"
            fi
            ;;
    esac

    mkdir -p "$CONFIG_DIR"
    # -n so an existing directory symlink is replaced rather than followed. Without
    # it, ln drops the new link *inside* the old target: that is where the stray
    # ~/.config/hypr/hypr came from.
    ln -sfn -- "$source" "$target"
}

# ----------------------------------------------------------------- packages --

install_packages() {
    command -v pacman >/dev/null \
        || die "pacman not found. These configs target Arch Linux."

    local helper=''
    local candidate
    for candidate in yay paru; do
        if command -v "$candidate" >/dev/null; then
            helper="$candidate"
            break
        fi
    done

    if [[ -n $helper ]]; then
        info "${BLUE}::${RESET} Installing packages with $helper..."
        "$helper" -S --needed --noconfirm "${REPO_PACKAGES[@]}" "${AUR_PACKAGES[@]}"
    else
        info "${BLUE}::${RESET} Installing repository packages with pacman..."
        sudo pacman -S --needed --noconfirm "${REPO_PACKAGES[@]}"
        warn "No AUR helper (yay or paru) found, so these were skipped:"
        warn "  ${AUR_PACKAGES[*]}"
    fi
}

# ------------------------------------------------------- conflicting daemons --

# Only one process can own org.freedesktop.Notifications on the session bus, and
# the winner is simply whoever asked first. Arch ships dunst as a D-Bus activated
# service, so the first program to send a notification starts it --- and from
# then on quickshell's notification server gets nothing and you keep seeing
# dunst's popups instead of the ones in modules/notifications.
#
# Masking is what actually stops that, rather than disabling: dunst's D-Bus
# service file delegates activation to systemd (SystemdService=dunst.service),
# and a masked unit cannot be activated. Undo with:
#
#     systemctl --user unmask dunst.service
#
disable_notification_daemons() {
    command -v systemctl >/dev/null || return 0

    local daemon
    for daemon in dunst mako swaync; do
        systemctl --user list-unit-files "$daemon.service" --no-legend 2>/dev/null \
            | grep -q . || continue

        if [[ "$(systemctl --user is-enabled "$daemon.service" 2>/dev/null)" != masked ]]; then
            info "${BLUE}::${RESET} Masking $daemon, so quickshell can own the notification bus..."
            systemctl --user mask "$daemon.service" >/dev/null
        fi

        systemctl --user stop "$daemon.service" >/dev/null 2>&1 || true
        pkill -x "$daemon" 2>/dev/null || true
    done
}

# --------------------------------------------------------------------- main --

packages=false
dry_run=false
force=false
backup=true
selected=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -p|--packages)  packages=true ;;
        -n|--dry-run)   dry_run=true ;;
        -f|--force)     force=true ;;
        --no-backup)    backup=false ;;
        -h|--help)      usage; exit 0 ;;
        -*)             die "unknown option: $1 (try --help)" ;;
        *)              selected+=("$1") ;;
    esac
    shift
done

[[ -d $SOURCE_DIR ]] || die "no .config directory in $DOTFILES_DIR"

mapfile -t configs < <(available_configs)
[[ ${#configs[@]} -gt 0 ]] || die "no configs to install in $SOURCE_DIR"

if [[ ${#selected[@]} -gt 0 ]]; then
    for name in "${selected[@]}"; do
        # shellcheck disable=SC2076
        [[ " ${configs[*]} " == *" $name "* ]] \
            || die "unknown config: $name (available: ${configs[*]})"
    done
    configs=("${selected[@]}")
fi

info "${BOLD}Shorekeeper dotfiles${RESET}"
info "${DIM}  repo    $DOTFILES_DIR${RESET}"
info "${DIM}  target  $CONFIG_DIR${RESET}"
info ''

actions=()
pending=0
replacing=0

for name in "${configs[@]}"; do
    action="$(action_for "$name")"
    actions+=("$action")

    case "$action" in
        skip)
            printf '  %s%-14s%s already linked\n' "$DIM" "$name" "$RESET"
            ;;
        link)
            printf '  %s%-14s%s link\n' "$GREEN" "$name" "$RESET"
            pending=$((pending + 1))
            ;;
        replace)
            if $backup; then
                printf '  %s%-14s%s replace %s(%s -> backup)%s\n' \
                    "$YELLOW" "$name" "$RESET" "$DIM" "$(describe_target "$name")" "$RESET"
            else
                printf '  %s%-14s%s replace %s(%s -> deleted)%s\n' \
                    "$RED" "$name" "$RESET" "$DIM" "$(describe_target "$name")" "$RESET"
            fi
            pending=$((pending + 1))
            replacing=$((replacing + 1))
            ;;
    esac
done

if $packages; then
    info ''
    info "  ${BLUE}packages${RESET}       ${#REPO_PACKAGES[@]} from the repositories, ${#AUR_PACKAGES[@]} from the AUR"
fi

if [[ $replacing -gt 0 ]] && $backup; then
    info ''
    info "${DIM}Replaced configs are moved to $BACKUP_DIR${RESET}"
fi

if $dry_run; then
    info ''
    info "${DIM}Dry run, nothing was changed.${RESET}"
    exit 0
fi

if [[ $pending -eq 0 ]] && ! $packages; then
    info ''
    info "${GREEN}Everything is already installed.${RESET}"
    exit 0
fi

if ! $force; then
    [[ -t 0 ]] || die "not running interactively; pass --force to proceed"

    info ''
    read -r -p "Proceed? [y/N] " reply
    [[ $reply == [yY] || $reply == [yY][eE][sS] ]] || { info 'Aborted.'; exit 1; }
fi

info ''

if $packages; then
    install_packages
    info ''
fi

for i in "${!configs[@]}"; do
    deploy "${configs[$i]}" "${actions[$i]}"
done

disable_notification_daemons

info "${GREEN}Done.${RESET} ${#configs[@]} config(s) linked into $CONFIG_DIR."

if [[ -d $BACKUP_DIR ]]; then
    info "Previous configs are in ${BOLD}$BACKUP_DIR${RESET}"
fi

info ''
info "${DIM}Hyprland picks up config changes on its own; restart quickshell and"
info "waybar to pick up theirs (SUPER + M logs out if you want a clean start).${RESET}"
