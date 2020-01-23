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
        r=$($_NODE --no-warnings "$_LOGIN_TWITTER_JS" "$_CHROME" 1 "$u" "$p" | tee "$_LOG_DIR/${_TIMESTAMP}_tokens.log")
    else
        r=$($_NODE --no-warnings "$_LOGIN_TWITTER_JS" "$_CHROME" 0 | tee "$_LOG_DIR/${_TIMESTAMP}_tokens.log")
    fi

    _COOKIE=$(echo "$r" | grep "kdt" | $_JQ -r '.[] | "\(.name)=\(.value);"' | awk '{printf "%s", $0}')
    _CSRF_TOKEN=$(echo "$r" | grep "x-csrf-token" | $_JQ -r '."x-csrf-token"' | head -1)
    _AUTH_TOKEN=$(echo "$r" | grep "authorization" | $_JQ -r '.authorization' | head -1)
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
