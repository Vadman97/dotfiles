function ch --description "Connect to a configured ClickHouse cluster"
    set -l pw_file ~/.config/fish/.ch_passwords

    if test (count $argv) -lt 1
        _ch_usage
        return 1
    end

    set -l env $argv[1]
    set -l extra_args $argv[2..]

    if test "$env" = setpw
        if test (count $argv) -lt 2
            echo "Usage: ch setpw <env>"
            return 1
        end
        set -l target $argv[2]
        if not _ch_configured $target
            echo "Unknown environment: $target"
            return 1
        end
        read -s -P "Password for ch $target: " pw
        echo
        _ch_set_pw $pw_file ch_$target $pw
        echo "Password for ch $target saved to $pw_file."
        return 0
    end

    if not _ch_configured $env
        _ch_usage
        return 1
    end

    set -l host_var ch_host_$env
    set -l user_var ch_user_$env
    set -l db_var ch_db_$env
    set -l port_var ch_port_$env

    set -l host $$host_var
    set -l user default
    set -q $user_var; and set user $$user_var

    # Default database unless the caller passed their own -d/--database.
    if not contains -- -d $extra_args; and not contains -- --database $extra_args
        set -l db default
        set -q $db_var; and set db $$db_var
        set extra_args -d $db $extra_args
    end

    if set -q $port_var
        set extra_args --port $$port_var $extra_args
    end

    set -l pw (_ch_get_pw $pw_file ch_$env "ch $env")
    test -z "$pw"; and return 1

    clickhouse client --host $host --secure --user $user --password $pw $extra_args
end

function _ch_usage
    echo "Usage: ch <env> [clickhouse args...]"
    echo "       ch setpw <env>"
    if set -q ch_envs
        echo "Configured environments: $ch_envs"
    else
        echo "No environments configured. Define ch_envs / ch_host_<env> in"
        echo "~/.config/fish/local.fish (see fish/local.fish.example)."
    end
end

function _ch_configured
    set -l env $argv[1]
    set -l host_var ch_host_$env
    set -q $host_var
end

function _ch_get_pw
    set -l pw_file $argv[1]
    set -l key $argv[2]
    set -l label $argv[3]

    if test -f $pw_file
        set -l line (string match -r "^$key=(.*)" < $pw_file)
        if test (count $line) -ge 2
            echo $line[2]
            return 0
        end
    end

    read -s -P "Password for $label (run 'ch setpw $label' to save): " pw
    echo >&2
    echo $pw
end

function _ch_set_pw
    set -l pw_file $argv[1]
    set -l key $argv[2]
    set -l pw $argv[3]

    if test -f $pw_file
        set -l tmp (mktemp)
        string match -rv "^$key=" < $pw_file > $tmp
        echo "$key=$pw" >> $tmp
        mv $tmp $pw_file
    else
        echo "$key=$pw" > $pw_file
    end
    chmod 600 $pw_file
end
