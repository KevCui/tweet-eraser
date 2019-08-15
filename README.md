tweet-eraser
============

For some reason, after a bad dream, suddenly you want to reduce your digital footprint. Now you start to search for a way to erase only tweets, or only tweets and RTs, or only likes. And you don't trust other 3rd-part service to do that for you probably because of your bad dream. And you still want to keep your Twitter account active...

## Dependency

- [Puppeteer](https://github.com/GoogleChrome/puppeteer)

- [jq](https://stedolan.github.io/jq/download/)

## Scripts

- login-twitter.js: fetch Twitter tokens

- tweet-eraser.sh: main script to call Twitter APIs

## Preparation

- Install Puppeteer without installing additional Chrome:

```
npm -i puppeteer-core
```

OR

- Install Puppeteer with Chrome:

```
npm -i puppeteer
```

## How to use

- tweet-eraser.sh

```
Usage:
  ./tweet-eraser.sh [-t|-f <file>] [-r|-f <file>] [-l|-f <file>] [-p]

Options:
  -t               Optional, remove tweets
                   -f <file> to use resource file tweet.js
  -r               Optional, remove tweets and RTs
                   -f <file> to use resource file tweet.js
  -l               Optional, remove likes
                   -f <file> to use resource file like.js
  -p               Optional, hide browser (use headless mode) and login from terminal
  -h | --help      Display this help message
```

- login-tweet.js

```
Usage:
  ./login-twitter.js <chrome_path> <no_browser_boolean> <username> <password>

  chrome_path:        path to chrome/chromium binary
  no_browser_boolean: 1 true, headless mode; 0 false, open browser
  username:           twitter account email address or phone nubmer
  password:           twitter credential
```

## Examples

- Erase most recent tweets (< 3200):

```
~$ ./tweet-eraser.sh -t
```

- Erase most recent tweets and RTs (< 3200):

```
~$ ./tweet-eraser.sh -r
```

- Erase likes:

```
~$ ./tweet-eraser.sh -l
```

- Erase tweets (> 3200) with local input file:

```
~$ ./tweet-eraser.sh -t -f tweet.js
```

- Erase likes, using headless mode:

```
~$ ./tweet-eraser.sh -l -p
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

- Why not use official Twitter Authentication API in this script?

To use Twitter Authentication API, it requires to create a Twitter app in order to get `oauth_consumer_key` and `oauth_token`. A bit too much for a script to earse tweets...

- Why not provide an option to remove RTs only?

I know, but [GET retweets_of_me API](https://developer.twitter.com/en/docs/tweets/post-and-engage/api-reference/get-statuses-retweets_of_me#) is broken (or only working with oauth_token? I doubt): it always returns empty response without any data of RTs.

- How fast this script can erase tweets?

It took 15 minutes to erase 2400 tweets. Not great, not terrible.

- Can I erase some old tweets but keep some recent ones?

Yes, it's possible. Change `_MAX_ID` variable in `tweet-eraser.sh`. Put a Twitter ID number which is greater than old tweets IDs but less than recent ones IDs.

- Can I erase my tweet data on other 3rd-part servers using this script?

No.
