# tweet-eraser ![CI](https://github.com/KevCui/tweet-eraser/workflows/CI/badge.svg)

> Erase tweets, likes...

For some reason, after a bad dream, suddenly you want to reduce your digital footprint. Now you start to search for a way to erase tweets, RTs and likes. And you don't trust other 3rd-part service to do that for you, probably because of your bad dream. And you still want to keep your Twitter account active...

# Table of Contents

- [Dependency](#dependency)
- [Scripts](#scripts)
- [Preparation](#preparation)
- [How to use](#how-to-use)
- [Examples](#examples)
- [Run tests](#run-tests)
- [Limitation](#limitation)
- [FAQ](#faq)
  - [Why not use official Twitter Authentication API in this script?](#why-not-use-official-twitter-authentication-api-in-this-script)
  - [Why not provide an option to remove RTs only?](#why-not-provide-an-option-to-remove-rts-only)
  - [How fast this script can erase tweets?](#how-fast-this-script-can-erase-tweets)
  - [Can I erase some old tweets but keep some recent ones?](#can-i-erase-some-old-tweets-but-keep-some-recent-ones)
  - [Can I erase my tweet data stored on other 3rd-part servers using this script?](#can-i-erase-my-tweet-data-stored-on-other-3rd-part-servers-using-this-script)

## Dependency

- [Puppeteer](https://github.com/GoogleChrome/puppeteer)

- [jq](https://stedolan.github.io/jq/download/)

## Scripts

- bin/login-twitter.js: fetch Twitter tokens

- tweets-eraser.sh: main script to call Twitter APIs

- likes-downloader.sh: additional script to download Twitter likes to a markdown file as a quick backup

- tweets-downloader.sh: additional script to download tweets and RTs as a quick backup

## Preparation

- Install Puppeteer without installing additional Chrome:

```bash
npm i puppeteer-core
```

OR

- Install Puppeteer with Chrome:

```bash
npm i puppeteer
```

## How to use

- tweet-eraser.sh

```
Usage:
  ./tweet-eraser.sh [-t|-f <file>] [-r|-f <file>] [-l|-f <file>] [-p] [-k]

Options:
  -t               Optional, remove tweets
                   -f <file> to use resource file tweet.js
  -r               Optional, remove tweets and RTs
                   -f <file> to use resource file tweet.js
  -l               Optional, remove likes
                   -f <file> to use resource file like.js
  -p               Optional, hide browser (use headless mode) and login from terminal
  -k               Optional, keep login tokens, by default no
  -h | --help      Display this help message
```

- login-tweet.js

```
Usage:
  node login-twitter.js <chrome_path> <no_browser_boolean> <username> <password>

  chrome_path:        path to chrome/chromium binary
  no_browser_boolean: 1 true, headless mode; 0 false, open browser
  username:           twitter account email address or phone nubmer
  password:           twitter credential
```

- likes-downloader.sh

```
Usage:
  ./likes-downloader.sh [-p] [-k]

Options:
  -p               Optional, hide browser (use headless mode) and login from terminal
                   This option doesn't support 2FA
  -k               Optional, keep login tokens, by default no
  -h | --help      Display this help message
```

- tweets-downloader.sh

```
Usage:
  ./tweets-downloader.sh [-p] [-k]

Options:
  -p               Optional, hide browser (use headless mode) and login from terminal
                   This option doesn't support 2FA
  -k               Optional, keep login tokens, by default no
  -h | --help      Display this help message
```

## Examples

- Erase most recent tweets (< 3200):

```bash
~$ ./tweet-eraser.sh -t
```

- Erase most recent tweets and RTs (< 3200):

```bash
~$ ./tweet-eraser.sh -r
```

- Erase likes:

```bash
~$ ./tweet-eraser.sh -l
```

- Erase tweets (> 3200) with local input file:

```bash
~$ ./tweet-eraser.sh -t -f tweet.js
```

- Erase likes, using headless mode:

```bash
~$ ./tweet-eraser.sh -l -p
```

## Run tests

```bash
~$ bats test/tweet-eraser.bats
```

## Limitation

Be aware that using this script without additional input file can only erase about 3200 most recent tweets/RTs. It's [a limitation of Twitter API](https://developer.twitter.com/en/docs/tweets/timelines/api-reference/get-statuses-user_timeline.html): `This method can only return up to 3,200 of a user's most recent Tweets. Native retweets of other statuses by the user is included in this total...`

If it needs to erase >3200 tweets, the additional file is required from [Twitter archive](https://help.twitter.com/en/managing-your-account/how-to-download-your-twitter-archive):

- Download Twitter archive

- Unzip it

- Use `tweet.js` (data for tweets and RTs): `-f tweets.js`

OR

- Use `like.js` (data for likes): `-f like.js`

## FAQ

### Why not use official Twitter Authentication API in this script?

To use Twitter Authentication API, it requires to create a Twitter app in order to get `oauth_consumer_key` and `oauth_token`. A bit too much for a script to earse tweets...

### Why not provide an option to remove RTs only?

I know, but [GET retweets_of_me API](https://developer.twitter.com/en/docs/tweets/post-and-engage/api-reference/get-statuses-retweets_of_me#) is broken (or only working with oauth_token? I doubt): it always returns empty response without any data of RTs.

### How fast this script can erase tweets?

It took 15 minutes to erase 2400 tweets. Not great, not terrible.

### Can I erase some old tweets but keep some recent ones?

Yes, it's possible. Change `_MAX_ID` variable in `tweet-eraser.sh`. Put a tweet ID number which is greater than old tweets IDs but less than recent ones IDs.

### Can I erase my tweet data stored on other 3rd-part servers using this script?

No.
