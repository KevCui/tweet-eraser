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
        -H 'Connection: keep-alive' \
        -H 'Cookie: '"$_COOKIE" \
        -H 'authorization: '"$_AUTH_TOKEN" \
        -H 'x-csrf-token: '"$_CSRF_TOKEN" \
        -H 'cache-control: no-cache'
}

call_list_lists() {
    # Display all lists
    # $1: user name
    $_CURL -sSX GET "$_HOST/lists/list.json?screen_name=$1" \
        -H 'Accept: */*' \
        -H 'Connection: keep-alive' \
        -H 'Cookie: '"$_COOKIE" \
        -H 'authorization: '"$_AUTH_TOKEN" \
        -H 'x-csrf-token: '"$_CSRF_TOKEN" \
        -H 'Cache-Control: no-cache'
}

call_list_member() {
    # Display members of a list
    # $1: user name
    # $2: list slug
    $_CURL -sSX GET "$_HOST/lists/members.json?owner_screen_name=${1}&slug=${2}&count=5000" \
        -H 'Accept: */*' \
        -H 'Connection: keep-alive' \
        -H 'Cookie: '"$_COOKIE" \
        -H 'authorization: '"$_AUTH_TOKEN" \
        -H 'x-csrf-token: '"$_CSRF_TOKEN" \
        -H 'Cache-Control: no-cache'
}

call_list_member_create() {
    # Add member to a list
    # $1: owner screen name
    # $2: list slug
    # $3: a comma-separated list of member screen name
    $_CURL -sSX POST "$_HOST/lists/members/create_all.json?owner_screen_name=${1}&slug=${2}&screen_name=${3}" \
        -H 'Accept: */*' \
        -H 'Connection: keep-alive' \
        -H 'Cookie: '"$_COOKIE" \
        -H 'authorization: '"$_AUTH_TOKEN" \
        -H 'x-csrf-token: '"$_CSRF_TOKEN" \
        -H 'Cache-Control: no-cache'
}

call_list_following() {
    # Display list of following accounts
    # $1: user name
    $_CURL -sSX GET "$_HOST/friends/list.json?screen_name=${1}&count=200" \
        -H 'Accept: */*' \
        -H 'Connection: keep-alive' \
        -H 'Cookie: '"$_COOKIE" \
        -H 'authorization: '"$_AUTH_TOKEN" \
        -H 'x-csrf-token: '"$_CSRF_TOKEN" \
        -H 'Cache-Control: no-cache'
}

call_list_status() {
    # Display timeline of a list
    # $1: owner screen name
    # $2: list slug
    $_CURL -sSX GET "$_HOST/lists/statuses.json?owner_screen_name=${1}&slug=${2}&count=200&include_rts=true" \
        -H 'Accept: */*' \
        -H 'Connection: keep-alive' \
        -H 'Cookie: '"$_COOKIE" \
        -H 'authorization: '"$_AUTH_TOKEN" \
        -H 'x-csrf-token: '"$_CSRF_TOKEN" \
        -H 'Cache-Control: no-cache'
}
