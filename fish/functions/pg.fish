function pg --description "Connect to a configured PostgreSQL database (read-only)"
    set -l pw_file ~/.config/fish/.pg_passwords

    if test (count $argv) -lt 1
        _pg_usage
        return 1
    end

    set -l env $argv[1]
    set -l extra_args $argv[2..]

    if test "$env" = setpw
        if test (count $argv) -lt 2
            echo "Usage: pg setpw <env>"
            return 1
        end
        set -l target $argv[2]
        if not _pg_configured $target
            echo "Unknown environment: $target"
            return 1
        end
        read -s -P "Password for pg $target: " pw
        echo
        _pg_set_pw $pw_file pg_$target $pw
        echo "Password for pg $target saved to $pw_file."
        return 0
    end

    if not _pg_configured $env
        _pg_usage
        return 1
    end

    set -l host_var pg_host_$env
    set -l user_var pg_user_$env
    set -l db_var pg_db_$env
    set -l port_var pg_port_$env

    set -l host $$host_var
    set -l port 5432
    set -q $port_var; and set port $$port_var
    set -l db postgres
    set -q $db_var; and set db $$db_var
    set -l user postgres
    set -q $user_var; and set user $$user_var

    set -l pw (_pg_get_pw $pw_file pg_$env "pg $env")
    test -z "$pw"; and return 1

    # default_transaction_read_only guards against fat-fingering a write
    # against a production replica.
    PGPASSWORD=$pw PGOPTIONS="-c default_transaction_read_only=on" \
        psql -h $host -p $port -U $user -d $db $extra_args
end

function _pg_usage
    echo "Usage: pg <env> [psql args...]"
    echo "       pg setpw <env>"
    if set -q pg_envs
        echo "Configured environments: $pg_envs"
    else
        echo "No environments configured. Define pg_envs / pg_host_<env> in"
        echo "~/.config/fish/local.fish (see fish/local.fish.example)."
    end
end

function _pg_configured
    set -l env $argv[1]
    set -l host_var pg_host_$env
    set -q $host_var
end

function _pg_get_pw
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

    read -s -P "Password for $label (run 'pg setpw $label' to save): " pw
    echo >&2
    echo $pw
end

function _pg_set_pw
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
