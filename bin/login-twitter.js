// ~$ ./login-twitter <chrome_path> <no_browser_boolean> <username> <password>
//
//   chrome_path:        path to chrome/chromium binary
//   no_browser_boolean: 1 true, headless mode; 0 false, open browser
//   username:           twitter account email address or phone nubmer
//   password:           twitter credential

const puppeteer = require('puppeteer');

(async() => {
    const chrome = process.argv[2];
    const isheadless = Number(process.argv[3]);
    const contentLogin = process.argv[4];
    const contentPassword = process.argv[5];

    const loginUrl='https://twitter.com/login';
    const inputLogin = '.js-username-field';
    const inputPassword = '.js-password-field';
    const sumbitButton = '.submit';
    const homeButton = '.css-1dbjc4n.r-dnmrzs.r-1vvnge1';

    const browser = await puppeteer.launch({executablePath: chrome, headless: isheadless});
    const page = await browser.newPage();
    await page.goto(loginUrl, {timeout: 30000, waitUntil: 'domcontentloaded'});

    await page.waitFor(sumbitButton)
    if (contentPassword)  {
        await page.click(inputLogin)
        await page.type(inputLogin, contentLogin, {delay: 50});
        await page.click(inputPassword)
        await page.type(inputPassword, contentPassword, {delay: 80});
        const elementHandle = await page.$(sumbitButton);
        await elementHandle.press('Enter');
    }

    await page.waitFor(homeButton);
    await page.click(homeButton);

    const cookie = await page.cookies();
    console.log(JSON.stringify(cookie));

    await page.setRequestInterception(true);
    page.on('request', request => {
    if (request.url().indexOf('client_event.json') > -1) {
        const headers = request.headers();
        if ('access-control-request-headers' in headers) {
            request.continue();
        } else {
            request.abort();
            console.log(JSON.stringify(request.headers()));
            browser.close();
        }
    } else {
        request.continue();
    }});
})();
