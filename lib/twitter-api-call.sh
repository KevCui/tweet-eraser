#!/usr/bin/env bash

set -e
set -u

_CURL="$(command -v curl)" || command_not_found "curl"
_HOST="https://api.twitter.com/1.1"

logout_twitter() {
    # Logout and clean tokens
    printf "\nLog out... " >&2
    $_CURL -sSX POST "$_HOST/account/logout.json" \
        -H 'Accept: */*' \
        -H 'Cache-Control: no-cache' \
        -H 'Connection: keep-alive' \
        -H 'authorization: '"$_AUTH_TOKEN" \
        -H 'x-csrf-token: '"$_CSRF_TOKEN" \
        -H 'Cookie: '"$_COOKIE" \
        -H 'cache-control: no-cache'
}

call_user_timeline() {
    # Get max. 200 tweets since max_id, exclude RTs
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
        -H 'cache-control: no-cache'
}

delete_likes() {
    # Destory likes
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
