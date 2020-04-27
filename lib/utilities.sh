#!/usr/bin/env bash

set -e
set -u

_NODE="$(command -v node)" || command_not_found "node"
_JQ="$(command -v jq)" || command_not_found "jq" "https://stedolan.github.io/jq/"
_CHROME="$(command -v chrome)" || _CHROME="$(command -v chromium)" || command_not_found "chrome"
_LOGIN_TWITTER_JS="./bin/login-twitter.js"
_TIMESTAMP=$(date +%s)
_LOG_DIR="./log" && mkdir -p "$_LOG_DIR"

usage() {
    # Display usage message
    printf "\n%b\n" "$(grep '^#/' "$0" | cut -c4-)" && exit 0
}

command_not_found() {
    # Show command not found message
    # $1: command name
    # $2: installation URL
    printf "%b\n" '\033[31m'"$1"'\033[0m command not found!'
    [[ -n "${2:-}" ]] && printf "%b\n" 'Install from \033[31m'"$2"'\033[0m'
    exit 1
}

is_token_expired() {
    # Check if token is expried or not
    # $1 token file
    # $2 time to expire
    local o
    o="yes"
    if [[ -f "$1" && -s "$1" ]]; then
        local d n
        d=$(date -d "$(date -r "$1") $2" +%s)
        n=$(date +%s)

        if [[ "$n" -lt "$d" ]]; then
            o="no"
        fi
    fi
    echo "$o"
}

login_twitter() {
    # Fetch tokens from twitter login
    local r

    if [[ "$(is_token_expired "$_LOG_DIR/last_tokens.log" "+1 year")" == "yes" ]]; then
        if [[ "${_HEADLESS_MODE:-}" == true ]]; then
            local u p
            echo -n "Twitter email/phone: " >&2
            read -r u
            echo -n "Twitter password: " >&2
            read -rs p
            echo ""
            r=$($_NODE --no-warnings "$_LOGIN_TWITTER_JS" "$_CHROME" 1 "$u" "$p")
        else
            r=$($_NODE --no-warnings "$_LOGIN_TWITTER_JS" "$_CHROME" 0)
        fi

        if [[ "$_KEEP_TOKENS" == true ]]; then
            echo "$r" > "$_LOG_DIR/last_tokens.log"
        fi
    else
        r=$(cat "$_LOG_DIR/last_tokens.log")
    fi

    _COOKIE=$(grep "kdt" <<< "$r" | $_JQ -r '.[] | "\(.name)=\(.value);"' | awk '{printf "%s", $0}')
    _CSRF_TOKEN=$(grep "x-csrf-token" <<< "$r" | $_JQ -r '."x-csrf-token"' | head -1)
    _AUTH_TOKEN=$(grep "authorization" <<< "$r" | $_JQ -r '.authorization' | head -1)
}

cleanup() {
    # Invalid all tokens when exit
    if [[ -n "${_COOKIE:-}" && -n "${_CSRF_TOKEN:-}" && -n "${_AUTH_TOKEN:-}" && "$_KEEP_TOKENS" == false ]]; then
        rm -f "$_LOG_DIR/last_tokens.log"
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
