#!/usr/bin/env bash
#
# Download likes to markdown file
#
#/ Usage:
#/   ./like-downloader.sh [-p]
#/
#/ Options:
#/   -p               Optional, hide browser (use headless mode) and login from terminal
#/                    This option doesn't support 2FA
#/   -h | --help      Display this help message

set -e
set -u
trap cleanup INT
trap cleanup EXIT
source ./lib/utilities.sh
source ./lib/twitter-api-call.sh

set_var() {
    # Declare variables
    _MAX_ID="9223000000000000000"
    _LOG_DIR="./log" && mkdir -p "$_LOG_DIR"
    _OUTPUT_FILE="$_LOG_DIR/$(date +%s).md"
}

set_command() {
    # Declare commands
    _JQ="$(command -v jq)" || command_not_found "jq" "https://stedolan.github.io/jq/"
}

set_args() {
    # Declare arguments
    expr "$*" : ".*--help" > /dev/null && usage
    while getopts ":hp" opt; do
        case $opt in
            p)
                _HEADLESS_MODE=true
                ;;
            h)
                usage
                ;;
            \?)
                echo "Invalid option: -$OPTARG" >&2
                usage
                ;;
        esac
    done
}

download_likes() {
    # Download likes
    local maxid currentmaxid data

    maxid="$_MAX_ID"
    currentmaxid=""
    data=""
    while true; do
        data="$(call_favorites_list "$maxid" | $_JQ -r '.[] | "---\n\(.text)\nhttps://twitter.com/\(.user.screen_name)/status/\(.id_str)"')"
        currentmaxid=$(echo "$data" | tail -1 | sed -E 's/.*status\///')

        if [[ "$maxid" == "$currentmaxid" ]]; then
            break
        else
            echo "$data" >> "$_OUTPUT_FILE"
            maxid="$currentmaxid"
        fi
    done
}

main() {
    set_args "$@"
    set_command
    set_var
    login_twitter
    download_likes
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
