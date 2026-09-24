#!/usr/bin/env bash
#
# lib/code_config_excludes.sh — what to leave out of the code_config (code-server /config)
# volume backup.
#
# The volume grows without bound: every Claude Code extension auto-update installs a new
# ~140 MB version and leaves the old one behind, listed in extensions/.obsolete, which
# code-server only acts on at a restart the code container almost never gets. Add the
# VSIX download cache and boxes reached 4-5 GB, the gzip ate the 900 s backup budget and
# three timeouts auto-disabled backups (lohman-dev, leo-mezuli, rsb-dev; 2026-09-22).
#
# Everything excluded here is either a cache or a version code-server itself has marked
# for deletion. extensions/.obsolete stays in the tarball so a restored box still knows
# what to clean up.

# Always-safe cache paths, relative to the volume root (tar runs with -C /volume .).
CODE_CONFIG_CACHE_EXCLUDES="./data/CachedExtensionVSIXs ./data/logs ./.npm/_cacache"

# code_config_tar_excludes <obsolete_json> <extensions_json>
#
# Prints tar --exclude flags on one line, space-separated. <obsolete_json> is the content
# of extensions/.obsolete ({"<dir>": true, ...}); <extensions_json> is extensions.json,
# whose relativeLocation entries are the extensions in use and are never excluded.
# Either may be empty or garbage: the caches are still excluded, extensions are not.
code_config_tar_excludes() {
    local obsolete="${1:-}" in_use out="" path dir
    in_use="$(printf '%s' "${2:-}" | tr -d '[:space:]')"
    for path in $CODE_CONFIG_CACHE_EXCLUDES; do
        out="$out --exclude=$path"
    done

    # jq is not in the alpine image the backup runs in, hence grep.
    # A read loop, not `for dir in $(...)`: an unquoted "*" entry would glob.
    while IFS= read -r dir; do
        # .obsolete names a directory, never a path or a pattern: a "*" or "../x" here
        # would drop live extensions or escape the volume.
        case "$dir" in
            ""|.|..|*/*|*[!A-Za-z0-9._+-]*) continue ;;
        esac
        # Belt and braces: never drop the extension code-server is actually running.
        if printf '%s' "$in_use" | grep -qF "\"relativeLocation\":\"$dir\""; then
            continue
        fi
        out="$out --exclude=./extensions/$dir"
    done <<OBSOLETE
$(printf '%s' "$obsolete" | grep -oE '"[^"]+"[[:space:]]*:[[:space:]]*true' | cut -d'"' -f2)
OBSOLETE

    printf '%s\n' "${out# }"
}
