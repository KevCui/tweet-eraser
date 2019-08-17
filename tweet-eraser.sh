#!/usr/bin/env bash
#
# Erase some/all user tweets/RTs/likes
#
#/ Usage:
#/   ./tweet-eraser.sh [-t|-f <file>] [-r|-f <file>] [-l|-f <file>] [-p]
#/
#/ Options:
#/   -t               Optional, remove tweets
#/                    -f <file> to use resource file tweet.js
#/   -r               Optional, remove tweets and RTs
#/                    -f <file> to use resource file tweet.js
#/   -l               Optional, remove likes
#/                    -f <file> to use resource file like.js
#/   -p               Optional, hide browser (use headless mode) and login from terminal
#/                    This option doesn't support 2FA
#/   -h | --help      Display this help message
#/
#/ Exmaples:
#/   \e[32m- Erase most recent tweets (< 3200):\e[0m
#/     ~$ ./tweet-eraser.sh \e[33m-t\e[0m
#/
#/   \e[32m- Erase most recent tweets and RTs (< 3200):\e[0m
#/     ~$ ./tweet-eraser.sh \e[33m-r\e[0m
#/
#/   \e[32m- Erase likes:\e[0m
#/     ~$ ./tweet-eraser.sh \e[33m-l\e[0m
#/
#/   \e[32m- Erase tweets (> 3200) with local input file:\e[0m
#/     ~$ ./tweet-eraser.sh \e[33m-t -f tweet.js\e[0m
#/
#/   \e[32m- Erase likes, using headless mode:\e[0m
#/     ~$ ./tweet-eraser.sh \e[33m-l -p\e[0m

set -e
set -u
source ./lib/utilities.sh
source ./lib/twitter-api-call.sh

set_var() {
    # Declare variables
    _TIMESTAMP=$(date +%s)
    _MAX_ID="9223000000000000000"
    _LOG_DIR="./log" && mkdir -p "$_LOG_DIR"
}

set_command() {
    # Declare commands
    _JQ="$(command -v jq)" || command_not_found "jq" "https://stedolan.github.io/jq/"
}

set_args() {
    # Declare arguments
    expr "$*" : ".*--help" > /dev/null && usage
    while getopts ":htrlpf:" opt; do
        case $opt in
            t)
                _DELETE_TWEET=true
                ;;
            r)
                _DELETE_TWEET_RT=true
                ;;
            l)
                _DELETE_LIKE=true
                ;;
            f)
                _INPUT_FILE="$OPTARG"
                _TWEETS_LIKES=$(tweets_or_likes "$_INPUT_FILE")
                ;;
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

check_var() {
    # Check _DELETE_TWEET, _DELETE_TWEET_RT and _DELETE_LIKE
    if [[ -z "${_DELETE_TWEET:-}" && -z "${_DELETE_TWEET_RT:-}" && -z "${_DELETE_LIKE:-}" ]]; then
        echo "Missing option! At least one option of -t or -r of -l is required!" && usage
    fi
    if [[ "${_TWEETS_LIKES:-}" == "likes" && -n ${_DELETE_TWEET:-} ]]; then
        echo "Wrong option -t, -f indicates an input file of likes!" && usage
    fi
    if [[ "${_TWEETS_LIKES:-}" == "likes" && -n ${_DELETE_TWEET_RT:-} ]]; then
        echo "Wrong option -r, -f indicates an input file of likes!" && usage
    fi
    if [[ "${_TWEETS_LIKES:-}" == "tweets" && -n ${_DELETE_LIKE:-} ]]; then
        echo "Wrong option -l, -f indicates an input file of tweets!" && usage
    fi
}

get_tweet_id_from_file() {
    # Get tweet id from file
    # $1: input file, tweet.js or like.js
    # $2: including RTs? true or false
    #     necessary when input file is tweet.js

    if [[ "$_TWEETS_LIKES" == "tweets"  ]]; then
        if [[ "${2:-}" == true ]]; then
            sed -E '1s/.*/\[\{/' "$1" | $_JQ -r '.[].id_str'
        else
            sed -E '1s/.*/\[\{/' "$1" | $_JQ -r '.[] | select(.full_text | test("^RT @") == false) | "\(.id_str)"'
        fi
    elif [[ "$_TWEETS_LIKES" == "likes"  ]]; then
        sed -E '1s/.*/\[\{/' "$1" | $_JQ -r '.[].like.tweetId'
    else
        echo "Cannot figure out input file data format!" >&2 && exit 1
    fi
}

fetch_tweet_ids() {
    # Get tweet ids
    # $1: tweet or tweet_and_rt or fav
    local ids

    ids=""
    if [[ -z "${_INPUT_FILE:-}" ]]; then
        local maxid currentmaxid currentids

        currentmaxid=""
        currentids=""
        maxid="$_MAX_ID"
        while true; do
            if [[ "${1:-}" == "tweet_and_rt" ]]; then
                currentids="$(call_user_timeline "$maxid" true | $_JQ -r '.[].id_str')"
            elif [[ "${1:-}" == "tweet" ]]; then
                currentids="$(call_user_timeline "$maxid" false | $_JQ -r '.[].id_str')"
            elif [[ "${1:-}" == "fav" ]]; then
                currentids="$(call_favorites_list "$maxid" | $_JQ -r '.[].id_str')"
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
    else
        if [[ "${1:-}" == "tweet_and_rt" ]]; then
            ids="$(get_tweet_id_from_file "$_INPUT_FILE" true)"
        elif [[ "${1:-}" == "tweet" ]]; then
            ids="$(get_tweet_id_from_file "$_INPUT_FILE" false)"
        elif [[ "${1:-}" == "fav" ]]; then
            ids="$(get_tweet_id_from_file "$_INPUT_FILE")"
        else
            echo "Nothing to fetch!" && exit 1
        fi
    fi
    echo "$ids" | sort -n | tee "$_LOG_DIR/${_TIMESTAMP}_ids_${1:-}.log"
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
    for id in $(fetch_tweet_ids "tweet_and_rt"); do
        delete_tweet "$id"
    done
}

delete_user_likes() {
    # Delete all likes
    echo "Deleting all likes..."
    for id in $(fetch_tweet_ids "fav"); do
        delete_likes "$id"
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
    [[ "${_DELETE_LIKE:-}" == true ]] && delete_user_likes
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    trap cleanup INT
    trap cleanup EXIT
    main "$@"
fi
