function sf --description "Query Snowflake (LaunchDarkly) via the snow CLI"
    if test (count $argv) -ge 1; and test "$argv[1]" = help
        echo "Usage:"
        echo "  sf -q \"SELECT current_user()\"     # inline query"
        echo "  sf -f query.sql                   # from a file"
        echo "  sf < query.sql                    # from stdin (like 'ch prod < q.sql')"
        echo "  sf etl -q \"...\"                   # use the 'etl' password connection"
        echo "  sf -q \"...\" --format csv          # csv output for diffing"
        echo ""
        echo "Connections are in ~/.snowflake/config.toml:"
        echo "  ld  (default) - Okta SSO via browser, no stored secret"
        echo "  etl           - password auth; needs"
        echo "                  set -x SNOWFLAKE_CONNECTIONS_ETL_PASSWORD (read -s)"
        return 0
    end

    set -l conn ld
    if test (count $argv) -ge 1
        switch $argv[1]
            case ld etl
                set conn $argv[1]
                set -e argv[1]
        end
    end

    if isatty stdin
        if test (count $argv) -eq 0
            sf help
            return 1
        end
        snow sql --connection $conn $argv
    else
        snow sql --connection $conn --stdin $argv
    end
end
