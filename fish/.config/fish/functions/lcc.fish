function lcc -d "Local Claude Code launcher — point Claude Code at a local llama.cpp server"
    # Usage:
    #   lcc <model> [claude-args...]   launch Claude Code with the specified model
    #   lcc [-p|--print|...]           auto-detect model, pass flags through to claude
    #   lcc --help                     show this help
    #   lcc --no-check <model>         skip model validation against /v1/models
    #
    # Override host/port via env: LCC_HOST, LCC_PORT.

    argparse --ignore-unknown h/help no-check -- $argv
    or return 1

    set -q LCC_HOST; or set -l LCC_HOST 192.168.1.179
    set -q LCC_PORT; or set -l LCC_PORT 8000
    set -l base_url "http://$LCC_HOST:$LCC_PORT"

    if set -q _flag_help
        __lcc_print_help
        return 0
    end

    set -l model

    if test -z "$argv[1]"; or string match -q -- '-*' "$argv[1]"
        # ---- Auto-detect path ----
        echo (set_color --bold)"Local Claude Code"(set_color normal)" ("(set_color cyan)"GB10 @ $LCC_HOST:$LCC_PORT"(set_color normal)")"
        echo

        set -l models (__lcc_fetch_models)
        if test $status -ne 0
            echo (set_color red)"Cannot reach llama-server at $base_url"(set_color normal)
            echo
            echo (set_color white)"Make sure you're using an LLM provider that supports"(set_color normal)
            echo "  "(set_color cyan)"the Anthropic Messages API (/v1/messages endpoint)"(set_color normal)
            __lcc_print_examples
            return 1
        end

        set -l count (count $models)
        echo (set_color green)"llama-server is running"(set_color normal)

        if test $count -eq 0
            echo
            echo (set_color yellow)"No models loaded — use llama-server's --model flag, or install jq."(set_color normal)
            __lcc_print_examples
            return 0
        end

        echo
        echo (set_color white)"Loaded model(s):"(set_color normal)
        for i in (seq 1 $count)
            if test $count -eq 1
                echo "  "(set_color --bold)$models[$i](set_color normal)
            else
                echo "  "(set_color white)"$i."(set_color normal)" $models[$i]"
            end
        end

        if test $count -ne 1
            __lcc_print_examples
            return 0
        end

        set model $models[1]
        echo
        echo (set_color cyan)"Automatic model selection:"(set_color normal)" Using "(set_color --bold)$model(set_color normal)
    else
        # ---- Explicit-model path ----
        set model $argv[1]
        set -e argv[1]

        if not set -q _flag_no_check
            set -l models (__lcc_fetch_models)
            if test $status -ne 0
                echo (set_color red)"Cannot reach llama-server at $base_url"(set_color normal) >&2
                echo "Pass --no-check to launch anyway." >&2
                return 1
            end
            if not contains -- $model $models
                echo (set_color red)"Model not loaded:"(set_color normal)" $model" >&2
                if test (count $models) -gt 0
                    echo (set_color white)"Available:"(set_color normal) >&2
                    for m in $models
                        echo "  $m" >&2
                    end
                end
                echo >&2
                echo "Pass --no-check to launch anyway." >&2
                return 1
            end
        end
    end

    echo
    echo (set_color green)"Launching"(set_color normal)" "(set_color --bold)"Claude Code"(set_color normal)" "(set_color cyan)"$LCC_HOST:$LCC_PORT"(set_color normal)" / "(set_color magenta --bold)$model(set_color normal)
    set -x ANTHROPIC_BASE_URL $base_url
    set -x ANTHROPIC_AUTH_TOKEN local
    set -x ANTHROPIC_API_KEY ""
    set -x CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC 1
    exec claude --model $model $argv
end

function __lcc_print_help
    echo "Usage:"
    echo "  lcc <model> [claude-args...]   launch Claude Code with the specified model"
    echo "  lcc [-p|--print|...]           auto-detect model, pass flags to claude"
    echo "  lcc --help                     show this help"
    echo "  lcc --no-check <model>         skip model validation against /v1/models"
    __lcc_print_examples
end

function __lcc_print_examples
    echo
    echo (set_color white)"Examples:"(set_color normal)
    echo "  "(set_color green)"lcc qwen3-coder"(set_color normal)
    echo "  "(set_color green)"lcc my-model -p"(set_color normal)" # pass extra flags to claude"
    echo "  "(set_color green)"lcc -p \"hello\""(set_color normal)" # auto-detect model, pass flags"
    echo
    echo (set_color white)"Override host/port:"(set_color normal)
    echo "  "(set_color cyan)"LCC_HOST=10.0.0.5 LCC_PORT=9090 lcc mymodel"(set_color normal)
end
