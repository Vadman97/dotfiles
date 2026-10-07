# ~/.config/fish/config.fish
#
# Machine-specific values and every secret live in ~/.config/fish/local.fish,
# which is sourced at the end of this file and is never committed.
# See fish/local.fish.example for the shape of that file.

# ---------------------------------------------------------------- PATH --
fish_add_path -g $HOME/bin
fish_add_path -g $HOME/.local/bin
fish_add_path -g $HOME/.local/share/aws-cli
fish_add_path -g /opt/homebrew/bin
fish_add_path -g $HOME/work/dev/bin

# ------------------------------------------------------- language envs --
set -gx NVM_DIR $HOME/.nvm
set -gx GOENV_ROOT $HOME/.goenv
set -gx PYENV_ROOT $HOME/.pyenv
set -gx BUN_INSTALL $HOME/.bun

fish_add_path -g $GOENV_ROOT/bin
fish_add_path -g $PYENV_ROOT/bin
fish_add_path -g $BUN_INSTALL/bin

# ------------------------------------------------------------ toolchain --
set -gx CPATH /opt/homebrew/include
set -gx LIBRARY_PATH /opt/homebrew/lib
set -gx DYLD_LIBRARY_PATH "/opt/homebrew/lib:$DYLD_LIBRARY_PATH"

# ------------------------------------------------------------------ aws --
set -gx AWS_REGION us-east-1

# ------------------------------------------- Bedrock model id shortcuts --
# Public model identifiers; handy for `ANTHROPIC_MODEL=$OPUS_45 claude`.
set -gx OPUS_46 us.anthropic.claude-opus-4-6-v1
set -gx OPUS_45 us.anthropic.claude-opus-4-5-20251101-v1:0
set -gx OPUS_41 us.anthropic.claude-opus-4-1-20250805-v1:0
set -gx OPUS_40 us.anthropic.claude-opus-4-20250514-v1:0
set -gx SONNET_45 us.anthropic.claude-sonnet-4-5-20250929-v1:0
set -gx SONNET_40 us.anthropic.claude-sonnet-4-20250514-v1:0
set -gx SONNET_37 us.anthropic.claude-3-7-sonnet-20250219-v1:0
set -gx HAIKU_35 us.anthropic.claude-3-5-haiku-20241022-v1:0

# ------------------------------------------- Claude Code OTEL telemetry --
# The destination endpoint and the project header are set in local.fish;
# without them the exporters stay off.
if set -q OTEL_EXPORTER_OTLP_ENDPOINT
    set -gx CLAUDE_CODE_ENABLE_TELEMETRY 1
    set -gx OTEL_METRICS_EXPORTER otlp
    set -gx OTEL_LOGS_EXPORTER otlp
    set -gx OTEL_TRACES_EXPORTER otlp
    set -gx OTEL_EXPORTER_OTLP_PROTOCOL grpc
    set -gx OTEL_METRIC_EXPORT_INTERVAL 31000
    set -gx OTEL_LOGS_EXPORT_INTERVAL 31000
end

# ---------------------------------------------------------------- shims --
if status is-interactive
    # Keep pyenv's shims out of brew's PATH, otherwise brew warns constantly.
    if type -q pyenv
        alias brew="env PATH=(string replace (pyenv root)/shims '' \"\$PATH\") brew"
        pyenv init - | source
    end

    fish_add_path /opt/homebrew/opt/llvm/bin
    fish_add_path /opt/homebrew/opt/libpq/bin

    type -q goenv; and goenv init - | source

    functions -q nvm; and nvm use v22 >/dev/null

    type -q rvm; and rvm default

    test -f "$HOME/.cargo/env.fish"; and source "$HOME/.cargo/env.fish"

    # Work rc file, installed by my employer's dev-environment bootstrap.
    if test -f ~/.launchdarklyrc; and type -q bass
        bass source ~/.launchdarklyrc
    end
end

# ------------------------------------------------------------- aliases --
alias get_idf=". $HOME/work/esp-idf/export.fish"

# ------------------------------------- secrets / machine-local settings --
if test -f ~/.config/fish/local.fish
    source ~/.config/fish/local.fish
end

true
