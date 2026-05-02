function __lcc_fetch_models -d "Fetch model IDs from the LCC server (30s file cache)"
    # Outputs zero or more model IDs (one per line) to stdout.
    # Returns 0 if the server was reachable (or cache was used), 1 otherwise.

    set -q LCC_HOST; or set -l LCC_HOST 192.168.1.179
    set -q LCC_PORT; or set -l LCC_PORT 8000
    set -l cache_tag (string escape --style=url "$LCC_HOST:$LCC_PORT")
    set -l cache "/tmp/.lcc-models-$USER-$cache_tag"

    if test -f $cache
        set -l mtime (stat -c %Y $cache 2>/dev/null)
        if test -n "$mtime"; and test (math (date +%s) - $mtime) -lt 30
            cat $cache
            return 0
        end
    end

    set -l raw (curl -sf --max-time 3 "http://$LCC_HOST:$LCC_PORT/v1/models" 2>/dev/null)
    or return 1

    test -n "$raw"; or return 0

    if not command -q jq
        return 0
    end

    printf '%s\n' $raw | jq -r '.data[].id' 2>/dev/null | tee $cache
end
