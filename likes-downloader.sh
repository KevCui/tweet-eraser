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

usage() {
    # Display usage message
    printf "\n%b\n" "$(grep '^#/' "$0" | cut -c4-)" && exit 0
}

set_var() {
    # Declare variables
    _HOST="https://api.twitter.com/1.1"
    _TIMESTAMP=$(date +%s)
    _LOGIN_TWITTER_JS="./login-twitter.js"
    _MAX_ID="9223000000000000000"
    _OUTPUT_FILE="$(date +%s).md"
}

set_command() {
    # Declare commands
    _CURL="$(command -v curl)" || command_not_found "curl"
    _NODE="$(command -v node)" || command_not_found "node"
    _JQ="$(command -v jq)" || command_not_found "jq" "https://stedolan.github.io/jq/"
    _CHROME="$(command -v chrome)" || _CHROME="$(command -v chromium)" || command_not_found "chrome"
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

cleanup() {
    # Invalid all tokens when exit
    if [[ -n "${_COOKIE:-}" && -n "${_CSRF_TOKEN:-}" && -n "${_AUTH_TOKEN:-}" ]]; then
        logout_twitter
    fi
}

tweets_or_likes() {
    # Determine input file is using for tweets or likes
    # $1: input file, tweet.js or like.js
    local firstline

    firstline=$(head -1 "$1")
    if [[ "$firstline" == *"tweet.part"*  ]]; then
        echo "tweets"
    elif [[ "$firstline" == *"like.part"*  ]]; then
        echo "likes"
    else
        echo "Cannot figure out input file data format!" >&2 && exit 1
    fi
}

command_not_found() {
    # Show command not found message
    # $1: command name
    # $2: installation URL
    printf "%b\n" '\033[31m'"$1"'\033[0m command not found!'
    [[ -n "${2:-}" ]] && printf "%b\n" 'Install from \033[31m'"$2"'\033[0m'
    exit 1
}

login_twitter() {
    # Fetch tokens from twitter login
    local r

    if [[ "${_HEADLESS_MODE:-}" == true ]]; then
        local u p
        echo -n "Twitter email/phone: " >&2
        read -r u
        echo -n "Twitter password: " >&2
        read -rs p
        echo ""
        r=$($_NODE "$_LOGIN_TWITTER_JS" "$_CHROME" 1 "$u" "$p" | tee "${_TIMESTAMP}_tokens.log")
    else
        r=$($_NODE "$_LOGIN_TWITTER_JS" "$_CHROME" 0 | tee "${_TIMESTAMP}_tokens.log")
    fi

    _COOKIE=$(echo "$r" | grep "kdt" | $_JQ -r '.[] | "\(.name)=\(.value);"' | awk '{printf $0}')
    _CSRF_TOKEN=$(echo "$r" | grep "x-csrf-token" | $_JQ -r '."x-csrf-token"')
    _AUTH_TOKEN=$(echo "$r" | grep "authorization" | $_JQ -r '.authorization')
}

logout_twitter() {
    # Logout and clean tokens
    printf "\nLog out... " >&2
    $_CURL -sSX POST "$_HOST/account/logout.json" \
        -H 'Accept: */*' \
        -H 'Cache-Control: no-cache' \
        -H 'Connection: keep-alive' \
        -H 'authorization: '"$_AUTH_TOKEN" \
        -H 'x-csrf-token: '"$_CSRF_TOKEN" \
        -H 'cache-control: no-cache'
}

call_favorites_list() {
    # Get max. 200 likes since max_id
    # $1: max_id
    echo "max id: $1" >&2
    $_CURL -sSX GET "$_HOST/favorites/list.json?max_id=$1&count=200" \
        -H 'Accept: */*' \
        -H 'Cache-Control: no-cache' \
        -H 'Connection: keep-alive' \
        -H 'Cookie: '"$_COOKIE" \
        -H 'authorization: '"$_AUTH_TOKEN" \
        -H 'x-csrf-token: '"$_CSRF_TOKEN" \
        -H 'cache-control: no-cache' \
    | $_JQ -r '.[] | "---\n\(.text)\nhttps://twitter.com/\(.user.screen_name)/status/\(.id_str)"'
}

download_likes() {
    # Download likes
    local maxid currentmaxid data

    maxid="$_MAX_ID"
    currentmaxid=""
    data=""
    while true; do
        data="$(call_favorites_list "$maxid")"
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
