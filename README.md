# dotfiles

macOS config for a [fish](https://fishshell.com/)-first setup. fish is the
interactive shell; the bash/zsh files exist only so those shells stay usable.

```
fish/
  config.fish          PATH, language managers, Bedrock model ids, OTEL telemetry
  fish_plugins         fisher plugin list
  conf.d/rustup.fish   cargo env
  functions/ch.fish    ClickHouse client wrapper
  functions/pg.fish    read-only psql wrapper
  functions/sf.fish    Snowflake `snow sql` wrapper
  local.fish.example   template for secrets + machine-specific hosts
git/                   gitconfig and global gitignore
shell/                 .profile, .bashrc, .bash_profile, .zshrc, .zshenv
Brewfile               brew / cask / vscode / go / uv / npm packages
install.fish           symlinks everything into place
```

## Install

```fish
git clone https://github.com/Vadman97/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.fish --dry-run   # look first
./install.fish

brew bundle --file=Brewfile
fisher update              # installs fish/fish_plugins
$EDITOR ~/.config/fish/local.fish
```

`install.fish` symlinks rather than copies, and moves anything already at a
destination into `~/.dotfiles-backup/<timestamp>/` first.

## Secrets

Nothing secret is committed. `config.fish` ends by sourcing
`~/.config/fish/local.fish`, which is gitignored and is where tokens, API keys,
the OTEL endpoint, and database hostnames live. `install.fish` seeds it from
`fish/local.fish.example` on first run.

Database passwords are not kept there either — `ch setpw <env>` and
`pg setpw <env>` write them to `~/.config/fish/.ch_passwords` /
`.pg_passwords`, both mode 0600 and both gitignored.

## `ch` / `pg`

Both are table-driven: define one host per environment in `local.fish` and the
environment name becomes the subcommand.

```fish
set -gx ch_envs      prod staging
set -gx ch_host_prod abc123.us-east-1.aws.clickhouse.cloud
set -gx ch_user_prod default
set -gx ch_db_prod   default
```

```fish
ch setpw prod                 # store the password once
ch prod -q "SELECT 1"
ch prod < query.sql
pg prod -c "select now()"     # always default_transaction_read_only=on
```

`pg` forces `default_transaction_read_only=on` so a stray `UPDATE` against a
production replica fails instead of landing.

## Notes

- `config.fish` guards every tool shim (`pyenv`, `goenv`, `nvm`, `rvm`,
  `cargo`) behind an existence check, so a fresh machine gets a working shell
  before the Brewfile has been applied.
- `PATH` entries use `fish_add_path`, which is idempotent — re-sourcing
  `config.fish` will not grow `PATH`.
- Telemetry exporters only switch on when `OTEL_EXPORTER_OTLP_ENDPOINT` is set
  in `local.fish`.
- Plugin-generated files (`functions/fisher.fish`, `conf.d/nvm.fish`,
  `conf.d/omf.fish`, `completions/`) are intentionally not tracked; `fisher
  update` recreates them.
