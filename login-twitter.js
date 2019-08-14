const puppeteer = require('puppeteer');

(async() => {
    const contentLogin = process.argv[2];
    const contentPassword = process.argv[3];
    const chrome = process.argv[4];
    const isheadless = true;

    const loginUrl='https://twitter.com/login';
    const inputLogin = '.js-username-field';
    const inputPassword = '.js-password-field';
    const sumbitButton = '.submit';
    const homeButton = '.css-1dbjc4n.r-dnmrzs.r-1vvnge1';

    const browser = await puppeteer.launch({executablePath: chrome, headless: isheadless});
    const context = await browser.createIncognitoBrowserContext();
    const page = await context.newPage();

    await page.goto(loginUrl, {timeout: 20000, waitUntil: 'domcontentloaded'});

    await page.waitFor(sumbitButton)
    await page.click(inputLogin)
    await page.type(inputLogin, contentLogin);
    await page.click(inputPassword)
    await page.type(inputPassword, contentPassword);
    const elementHandle = await page.$(sumbitButton);
    await elementHandle.press('Enter');

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
