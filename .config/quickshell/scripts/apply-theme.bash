#!/usr/bin/env bash
#
# Applies a quickshell theme to everything outside quickshell. Run by
# services/Theme.qml whenever the theme changes, and usable by hand:
#
#     ./apply-theme.bash shorekeeper-blue
#
# Every executable script in themes/ is run with the theme id. Adding another
# application means dropping a script in there; nothing here needs to change.
#
set -euo pipefail

THEME="${1:-}"
[[ -n $THEME ]] || { echo "usage: ${0##*/} <theme-id>" >&2; exit 2; }

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

status=0

for script in "$SCRIPT_DIR"/themes/*.bash; do
    [[ -f $script ]] || continue

    # One failing application must not stop the others, so failures are
    # collected and reported at the end instead of aborting the run.
    if ! "$script" "$THEME"; then
        echo "apply-theme: ${script##*/} failed for theme '$THEME'" >&2
        status=1
    fi
done

exit "$status"
