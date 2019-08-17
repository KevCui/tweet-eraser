#!/usr/bin/env bats
#
# How to run:
#   ~$ bats test/tweet-eraser.bats

BATS_TEST_SKIPPED=

setup() {
    _SCRIPT="./tweet-eraser.sh"
    _JQ="$(command -v jq)"
    _LIKE_FILE="test/test-like.js"
    _TWEET_FILE="test/test-tweet.js"
    _TWEET_IDS="test/test-tweet.ids"
    _LOG_DIR="./log" && mkdir -p "$_LOG_DIR"
    _MAX_ID="99999999999999999999999"

    source $_SCRIPT
}

@test "CHECK: command_not_found()" {
    run command_not_found "bats"
    [ "$status" -eq 1 ]
    [ "$output" = "[31mbats[0m command not found!" ]
}

@test "CHECK: command_not_found(): show where-to-install" {
    run command_not_found "bats" "batsland"
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = "[31mbats[0m command not found!" ]
    [ "${lines[1]}" = "Install from [31mbatsland[0m" ]
}

@test "CHECK: check_var(): no option" {
    run check_var
    [ "$status" -eq 0 ]
    [ "$output" = "Missing option! At least one option of -t or -r of -l is required!$(usage)" ]
}

@test "CHECK: check_var(): -t" {
    _DELETE_TWEET=true
    run check_var
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "CHECK: check_var(): -r" {
    _DELETE_TWEET_RT=true
    run check_var
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "CHECK: check_var(): -l" {
    _DELETE_LIKE=true
    run check_var
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "CHECK: check_var(): wrong option with -t -f like.js" {
    _TWEETS_LIKES="likes"
    _DELETE_TWEET=true
    run check_var
    [ "$status" -eq 0 ]
    [ "$output" = "Wrong option -t, -f indicates an input file of likes!$(usage)" ]
}

@test "CHECK: check_var(): wrong option with -r -f like.js" {
    _TWEETS_LIKES="likes"
    _DELETE_TWEET_RT=true
    run check_var
    [ "$status" -eq 0 ]
    [ "$output" = "Wrong option -r, -f indicates an input file of likes!$(usage)" ]
}

@test "CHECK: check_var(): wrong option with -l -f tweet.js" {
    _TWEETS_LIKES="tweets"
    _DELETE_LIKE=true
    run check_var
    [ "$status" -eq 0 ]
    [ "$output" = "Wrong option -l, -f indicates an input file of tweets!$(usage)" ]
}

@test "CHECK: check_var(): correct option with -t -f tweet.js" {
    _TWEETS_LIKES="tweets"
    _DELETE_TWEET=true
    run check_var
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "CHECK: check_var(): correct option with -r -f tweet.js" {
    _TWEETS_LIKES="tweets"
    _DELETE_TWEET_RT=true
    run check_var
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "CHECK: check_var(): correct option with -l -f like.js" {
    _TWEETS_LIKES="likes"
    _DELETE_LIKE=true
    run check_var
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "CHECK: cleanup(): no token" {
    _COOKIE="cookie"
    run cleanup
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "CHECK: cleanup(): no cookie" {
    _AUTH_TOKEN="token"
    _CSRF_TOKEN="token"
    run cleanup
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "CHECK: cleanup(): logout" {
    logout_twitter() {
        echo "logout"
    }
    _CSRF_TOKEN="token"
    _AUTH_TOKEN="token"
    _COOKIE="cookie"
    run cleanup
    [ "$status" -eq 0 ]
    [ "$output" = "logout" ]
}

@test "CHECK: get_tweet_id_from_file(): input file doesn't exist" {
    _TWEETS_LIKES="likes"
    run get_tweet_id_from_file "testfile"
    [ "$status" -eq 0 ]
    [ "$output" = "sed: can't read testfile: No such file or directory" ]
}

@test "CHECK: get_tweet_id_from_file(): input file is directory" {
    _TWEETS_LIKES="likes"
    run get_tweet_id_from_file "test"
    [ "$status" -eq 0 ]
    [ "$output" = "sed: read error on test: Is a directory" ]
}

@test "CHECK: get_tweet_id_from_file(): no \$_TWEETS_LIKES" {
    _TWEETS_LIKES="nope"
    run get_tweet_id_from_file
    [ "$status" -eq 1 ]
    [ "$output" = "Cannot figure out input file data format!" ]
}

@test "CHECK: get_tweet_id_from_file(): likes" {
    _TWEETS_LIKES="likes"
    run get_tweet_id_from_file "$_LIKE_FILE"
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "11223344550001" ]
    [ "${lines[1]}" = "11223344550002" ]
    [ "${lines[2]}" = "11223344550003" ]
}

@test "CHECK: get_tweet_id_from_file(): tweets only" {
    _TWEETS_LIKES="tweets"
    run get_tweet_id_from_file "$_TWEET_FILE" false
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "11223344550001" ]
    [ "${lines[1]}" = "11223344550003" ]
}

@test "CHECK: get_tweet_id_from_file(): tweets and RTs" {
    _TWEETS_LIKES="tweets"
    run get_tweet_id_from_file "$_TWEET_FILE" true
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "11223344550001" ]
    [ "${lines[1]}" = "11223344550002" ]
    [ "${lines[2]}" = "11223344550003" ]
}

@test "CHECK: fetch_tweet_ids(): no \$_INPUT_FILE tweet_and_rt" {
    call_user_timeline() {
        i=$((1 + RANDOM % 5))
        sed $i'!d' "$_TWEET_IDS" | tee -a "$_LOG_FILE"
    }

    _TIMESTAMP="$(date +%s)"
    _LOG_FILE="${_LOG_DIR}/${_TIMESTAMP}-test.output"
    true > "$_LOG_FILE"
    run fetch_tweet_ids "tweet_and_rt"
    [ "$status" -eq 0 ]
    [ "$output" = "$(cat "$_LOG_FILE" | $_JQ -r '.[].id_str' | sed -E '$ d' | sort -n)" ]
}

@test "CHECK: fetch_tweet_ids(): no \$_INPUT_FILE tweet" {
    call_user_timeline() {
        i=$((1 + RANDOM % 5))
        sed $i'!d' "$_TWEET_IDS" | tee -a "$_LOG_FILE"
    }

    _TIMESTAMP="$(date +%s)"
    _LOG_FILE="${_LOG_DIR}/${_TIMESTAMP}-test.output"
    true > "$_LOG_FILE"
    run fetch_tweet_ids "tweet"
    [ "$status" -eq 0 ]
    [ "$output" = "$(cat "$_LOG_FILE" | $_JQ -r '.[].id_str' | sed -E '$ d' | sort -n)" ]
}

@test "CHECK: fetch_tweet_ids(): no \$_INPUT_FILE fav" {
    call_favorites_list() {
        i=$((1 + RANDOM % 5))
        sed $i'!d' "$_TWEET_IDS" | tee -a "$_LOG_FILE"
    }

    _TIMESTAMP="$(date +%s)"
    _LOG_FILE="${_LOG_DIR}/${_TIMESTAMP}-test.output"
    true > "$_LOG_FILE"
    run fetch_tweet_ids "fav"
    [ "$status" -eq 0 ]
    [ "$output" = "$(cat "$_LOG_FILE" | $_JQ -r '.[].id_str' | sed -E '$ d' | sort -n)" ]
}

@test "CHECK: fetch_tweet_ids(): no \$_INPUT_FILE nothing to fetch" {
    run fetch_tweet_ids
    [ "$status" -eq 1 ]
    [ "$output" = "Nothing to fetch!" ]
}

@test "CHECK: fetch_tweet_ids(): \$_INPUT_FILE fav" {
    _TIMESTAMP="$(date +%s)"
    _INPUT_FILE="$_LIKE_FILE"
    _TWEETS_LIKES="likes"
    run fetch_tweet_ids "fav"
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "11223344550001" ]
    [ "${lines[1]}" = "11223344550002" ]
    [ "${lines[2]}" = "11223344550003" ]
}

@test "CHECK: fetch_tweet_ids(): \$_INPUT_FILE tweet_and_rt" {
    _TIMESTAMP="$(date +%s)"
    _INPUT_FILE="$_TWEET_FILE"
    _TWEETS_LIKES="tweets"
    run fetch_tweet_ids "tweet_and_rt"
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "11223344550001" ]
    [ "${lines[1]}" = "11223344550002" ]
    [ "${lines[2]}" = "11223344550003" ]
}

@test "CHECK: fetch_tweet_ids(): \$_INPUT_FILE tweet" {
    _TIMESTAMP="$(date +%s)"
    _INPUT_FILE="$_TWEET_FILE"
    _TWEETS_LIKES="tweets"
    run fetch_tweet_ids "tweet"
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "11223344550001" ]
    [ "${lines[1]}" = "11223344550003" ]
}

@test "CHECK: fetch_tweet_ids(): \$_INPUT_FILE nothing to fetch" {
    _INPUT_FILE="$_TWEET_FILE"
    run fetch_tweet_ids
    [ "$status" -eq 1 ]
    [ "$output" = "Nothing to fetch!" ]
}
