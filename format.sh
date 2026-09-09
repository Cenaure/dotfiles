#!/usr/bin/env bash
#
# Formats every source file in this repository in one pass.
#
# Prettier only understands the web-ish formats (JSON, CSS, Markdown, JS), which
# is a handful of files here, so this script chains one formatter per language
# and gives them all the same two-space indent via their own config files:
#
#     .prettierrc      json, css, md, js, yaml
#     .qmlformat.ini   qml
#     .stylua.toml     lua
#     (flags below)    bash / sh
#
#     ./format.sh              # format everything
#     ./format.sh --check      # report what is unformatted, change nothing
#     ./format.sh .config/hypr # limit the run to one path
#
set -euo pipefail

# Resolved from the script's own location rather than $PWD, so it does the same
# thing whether or not you happen to be standing in the repo.
DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
cd -- "$DOTFILES_DIR"

CHECK=0
PATHS=()
for arg in "$@"; do
    case "$arg" in
        -c | --check) CHECK=1 ;;
        -h | --help)
            sed -n '3,14p' "${BASH_SOURCE[0]}" | sed 's/^#\ \?//'
            exit 0
            ;;
        -*)
            echo "format.sh: unknown option '$arg'" >&2
            exit 2
            ;;
        *) PATHS+=("$arg") ;;
    esac
done

bold() { printf '\033[1m%s\033[0m\n' "$1"; }
warn() { printf '\033[33m%s\033[0m\n' "$1" >&2; }

# The Qt 5 qmlformat is usually the one on $PATH and it predates settings files
# entirely: no indent options, so it would silently emit four spaces. Prefer the
# Qt 6 binary, which lives outside $PATH on Arch, and fall back only if it is
# the one that turns out to be installed.
find_qmlformat() {
    local candidate
    for candidate in /usr/lib/qt6/bin/qmlformat /usr/lib/qt/bin/qmlformat qmlformat6 qmlformat; do
        if command -v "$candidate" >/dev/null 2>&1; then
            if "$candidate" --help 2>&1 | grep -q -- '--indent-width'; then
                command -v "$candidate"
                return 0
            fi
        fi
    done
    return 1
}

# Every file git knows about or would accept, which keeps .gitignore'd noise
# (.idea/, stray build output) out of the run for free. NUL-delimited so paths
# with spaces survive.
repo_files() {
    git ls-files --cached --others --exclude-standard -z -- "${PATHS[@]:-.}"
}

# Prints the subset of repo_files matching the given extensions, one per line.
files_matching() {
    local pattern="$1"
    repo_files | tr '\0' '\n' | grep -E "$pattern" || true
}

missing=()
status=0

# ── prettier ────────────────────────────────────────────────── json, css, md, js
bold "prettier"
if command -v prettier >/dev/null 2>&1; then
    mapfile -t web_files < <(files_matching '\.(json|jsonc|css|scss|md|m?js|ts|ya?ml|html)$')
    if ((${#web_files[@]})); then
        # --ignore-path is applied to explicit paths too, so .prettierignore
        # still protects the vendored and runtime-written files listed there.
        if ((CHECK)); then
            prettier --ignore-path .prettierignore --check "${web_files[@]}" || status=1
        else
            prettier --ignore-path .prettierignore --write --log-level warn "${web_files[@]}"
            echo "  formatted ${#web_files[@]} file(s)"
        fi
    else
        echo "  nothing to do"
    fi
else
    missing+=("prettier    (pacman -S prettier)")
    warn "  not installed, skipped"
fi

# ── qmlformat ─────────────────────────────────────────────────────────────── qml
bold "qmlformat"
if qmlformat_bin="$(find_qmlformat)"; then
    mapfile -t qml_files < <(files_matching '\.qml$')
    if ((${#qml_files[@]})); then
        for file in "${qml_files[@]}"; do
            if ((CHECK)); then
                # qmlformat has no --check, so compare its output to the file.
                if ! "$qmlformat_bin" -s .qmlformat.ini "$file" | diff -q - "$file" >/dev/null; then
                    echo "  $file"
                    status=1
                fi
            else
                "$qmlformat_bin" -s .qmlformat.ini -i "$file"
            fi
        done
        ((CHECK)) || echo "  formatted ${#qml_files[@]} file(s)"
    else
        echo "  nothing to do"
    fi
else
    missing+=("qmlformat   (pacman -S qt6-declarative)")
    warn "  no Qt 6 qmlformat found, skipped"
fi

# ── stylua ────────────────────────────────────────────────────────────────── lua
bold "stylua"
if command -v stylua >/dev/null 2>&1; then
    mapfile -t lua_files < <(files_matching '\.lua$')
    if ((${#lua_files[@]})); then
        if ((CHECK)); then
            stylua --check "${lua_files[@]}" || status=1
        else
            stylua "${lua_files[@]}"
            echo "  formatted ${#lua_files[@]} file(s)"
        fi
    else
        echo "  nothing to do"
    fi
else
    missing+=("stylua      (pacman -S stylua)")
    warn "  not installed, skipped"
fi

# ── shfmt ───────────────────────────────────────────────────────────── bash, sh
bold "shfmt"
if command -v shfmt >/dev/null 2>&1; then
    # shfmt has no config file, so the house style lives here: two-space indent,
    # indented case branches, binary operators kept at line ends.
    shfmt_flags=(--indent 2 --case-indent --binary-next-line --language-dialect bash)
    mapfile -t sh_files < <(files_matching '\.(sh|bash)$')
    if ((${#sh_files[@]})); then
        if ((CHECK)); then
            shfmt "${shfmt_flags[@]}" --diff "${sh_files[@]}" || status=1
        else
            shfmt "${shfmt_flags[@]}" --write "${sh_files[@]}"
            echo "  formatted ${#sh_files[@]} file(s)"
        fi
    else
        echo "  nothing to do"
    fi
else
    missing+=("shfmt       (pacman -S shfmt)")
    warn "  not installed, skipped"
fi

if ((${#missing[@]})); then
    echo
    warn "Skipped because these formatters are missing:"
    printf '  %s\n' "${missing[@]}" >&2
fi

if ((CHECK)) && ((status)); then
    echo
    echo "Some files are not formatted. Run ./format.sh to fix them." >&2
fi
exit "$status"
