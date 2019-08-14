#!/usr/bin/env bash
#
# Erase some/all user tweets/RTs/favorites
#
#/ Usage:
#/   ./tweet-eraser.sh [-t|-r|-f|-a]
#/
#/ Options:
#/   -t               Optional, remove tweets
#/   -r               Optional, remove tweets and RTs
#/   -f               Optional, remove favorites/likes
#/   -a               Optional, remove all user tweets, RTs and favorites/likes
#/   -h | --help      Display this help message

set -e
set -u

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
}

set_command() {
    # Declare commands
    _CURL="$(command -v curl)" || command_not_found "curl"
    _NODE="$(command -v node)" || command_not_found "node"
    _JQ="$(command -v jq)" || command_not_found "jq" "https://stedolan.github.io/jq/"
    _CHROME="$(command -v chrome)" || _CHROME="$(command -v chromium)" || command_not_found "chrome"
}

check_var() {
    # Check _DELETE_TWEET, _DELETE_TWEET_RT and _DELETE_FAV
    if [[ -z "${_DELETE_TWEET:-}" && -z "${_DELETE_TWEET_RT:-}" && -z "${_DELETE_FAV:-}" ]]; then
        echo "Missing option! At least option is required!" && usage
    fi
}

set_args() {
    # Declare arguments
    expr "$*" : ".*--help" > /dev/null && usage
    while getopts ":htrfa" opt; do
        case $opt in
            t)
                _DELETE_TWEET=true
                ;;
            r)
                _DELETE_TWEET_RT=true
                ;;
            f)
                _DELETE_FAV=true
                ;;
            a)
                _DELETE_TWEET=true
                _DELETE_TWEET_RT=true
                _DELETE_FAV=true
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

command_not_found() {
    # Show command not found message
    # $1: command name
    # $2:installation URL
    printf "%b\n" '\033[31m'"$1"'\033[0m command not found!'
    [[ -n "${2:-}" ]] && printf "%b\n" 'Install from \033[31m'"$2"'\033[0m'
    exit 1
}

login_twitter() {
    # Fetch tokens from twitter login
    local u p r
    echo -n "Twitter email/phone: " >&2
    read -r u
    echo -n "Twitter password: " >&2
    read -rs p
    echo ""

    r=$($_NODE "$_LOGIN_TWITTER_JS" "$u" "$p" "$_CHROME" | tee "${_TIMESTAMP}_tokens.log")

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

call_user_timeline() {
    # Get max. 200 tweents since max_id, exclude RTs
    # $1: max_id
    # $2: including RTs? true or false
    echo "max id: $1" >&2
    $_CURL -sSX GET "$_HOST/statuses/user_timeline.json?max_id=$1&include_rts=$2&count=200" \
        -H 'Accept: */*' \
        -H 'Cache-Control: no-cache' \
        -H 'Connection: keep-alive' \
        -H 'Cookie: '"$_COOKIE" \
        -H 'authorization: '"$_AUTH_TOKEN" \
        -H 'x-csrf-token: '"$_CSRF_TOKEN" \
        -H 'cache-control: no-cache' \
    | $_JQ -r '.[].id_str'
}

call_favorites_list() {
    # Get max. 200 favorites since max_id
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
    | $_JQ -r '.[].id_str'
}

fetch_tweet_ids() {
    # Get tweet ids
    # $1: tweet or rt or fav
    local maxid currentmaxid currentids ids

    maxid="$_MAX_ID"
    currentmaxid=""
    currentids=""
    ids=""

    while true; do
        if [[ "${1:-}" == "rt" ]]; then
            currentids="$(call_user_timeline "$maxid" true)"
        elif [[ "${1:-}" == "tweet" ]]; then
            currentids="$(call_user_timeline "$maxid" false)"
        elif [[ "${1:-}" == "fav" ]]; then
            currentids="$(call_favorites_list "$maxid")"
        else
            echo "Nothing to fetch!" && exit 1
        fi

        currentmaxid=$(echo "$currentids" | tail -1)

        if [[ "$maxid" == "$currentmaxid" ]]; then
            break
        else
            ids=$(printf "%s\n%s" "$ids" "$currentids" | sed -E '/^\s*$/d')
            maxid="$currentmaxid"
        fi
    done
    echo "$ids" | sort -n | tee "${_TIMESTAMP}_ids_${1:-}.log"
}

delete_favorites() {
    # Destory favorites
    # $1: tweet id
    printf "\nDeleting %s... " "$1" >&2
    $_CURL -sSX POST "$_HOST/favorites/destroy.json?id=$1" \
        -H 'Accept: */*' \
        -H 'Cache-Control: no-cache' \
        -H 'Connection: keep-alive' \
        -H 'Cookie: '"$_COOKIE" \
        -H 'authorization: '"$_AUTH_TOKEN" \
        -H 'x-csrf-token: '"$_CSRF_TOKEN" \
        -H 'cache-control: no-cache'
}

delete_tweet() {
    # Destory tweet
    # $1: tweet id
    printf "\nDeleting %s... " "$1" >&2
    $_CURL -sSX POST "$_HOST/statuses/destroy/$1.json" \
      -H 'Accept: */*' \
      -H 'Cache-Control: no-cache' \
      -H 'Connection: keep-alive' \
      -H 'Cookie: '"$_COOKIE" \
      -H 'authorization: '"$_AUTH_TOKEN" \
      -H 'x-csrf-token: '"$_CSRF_TOKEN" \
      -H 'cache-control: no-cache'
}

delete_user_tweets() {
    # Delete all user tweets
    echo "Deleting all tweets..."
    for id in $(fetch_tweet_ids "tweet"); do
        delete_tweet "$id"
    done
}

delete_tweet_retweets() {
    # Delete all retweets
    echo "Deleting all tweets and RTs..."
    for id in $(fetch_tweet_ids "rt"); do
        delete_tweet "$id"
    done
}

delete_user_favorites() {
    # Delete all favorites
    echo "Deleting all favorites..."
    for id in $(fetch_tweet_ids "fav"); do
        delete_favorites "$id"
    done
}

main() {
    set_args "$@"
    set_command
    set_var
    check_var
    login_twitter
    [[ "${_DELETE_TWEET:-}" == true ]] && delete_user_tweets
    [[ "${_DELETE_TWEET_RT:-}" == true ]] && delete_tweet_retweets
    [[ "${_DELETE_FAV:-}" == true ]] && delete_user_favorites
    logout_twitter
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
