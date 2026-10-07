#!/usr/bin/env fish
#
# Symlink everything in this repo into place.
#   ./install.fish            link, backing up anything already there
#   ./install.fish --dry-run  show what would happen

set -l repo (realpath (dirname (status filename)))
set -l dry_run 0
contains -- --dry-run $argv; and set dry_run 1

set -l backup_dir $HOME/.dotfiles-backup/(date +%Y%m%d-%H%M%S)

function link_one -a src dest -V repo -V dry_run -V backup_dir
    if test "$dry_run" = 1
        echo "link $dest -> $src"
        return 0
    end

    mkdir -p (dirname $dest)

    # Already pointing at us: nothing to do.
    if test -L $dest; and test (readlink $dest) = "$src"
        echo "ok   $dest"
        return 0
    end

    if test -e $dest; or test -L $dest
        set -l rel (string replace -- $HOME/ "" $dest)
        mkdir -p (dirname $backup_dir/$rel)
        mv $dest $backup_dir/$rel
        echo "save $dest -> $backup_dir/$rel"
    end

    ln -s $src $dest
    echo "link $dest -> $src"
end

# ------------------------------------------------------------------ fish --
link_one $repo/fish/config.fish $HOME/.config/fish/config.fish
link_one $repo/fish/fish_plugins $HOME/.config/fish/fish_plugins

for f in $repo/fish/functions/*.fish
    link_one $f $HOME/.config/fish/functions/(basename $f)
end

for f in $repo/fish/conf.d/*.fish
    link_one $f $HOME/.config/fish/conf.d/(basename $f)
end

# ------------------------------------------------------------------- git --
link_one $repo/git/gitconfig $HOME/.gitconfig
link_one $repo/git/ignore $HOME/.config/git/ignore

# --------------------------------------------------------- other shells --
link_one $repo/shell/profile $HOME/.profile
link_one $repo/shell/bash_profile $HOME/.bash_profile
link_one $repo/shell/bashrc $HOME/.bashrc
link_one $repo/shell/zshrc $HOME/.zshrc
link_one $repo/shell/zshenv $HOME/.zshenv

# ------------------------------------------------------- local secrets --
set -l local_fish $HOME/.config/fish/local.fish
if not test -e $local_fish
    if test "$dry_run" = 1
        echo "seed $local_fish from fish/local.fish.example"
    else
        cp $repo/fish/local.fish.example $local_fish
        chmod 600 $local_fish
        echo "seed $local_fish (fill in your own values)"
    end
end

echo
echo "Done. Next:"
echo "  brew bundle --file=$repo/Brewfile"
echo "  fisher update                        # installs fish/fish_plugins"
echo "  \$EDITOR $local_fish                  # hosts, tokens, OTEL endpoint"
