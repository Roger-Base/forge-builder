const { chromium } = require('playwright');
(async () => {
  try {
    const browser = await chromium.connectOverCDP('http://localhost:9222');
    const ctx = browser.contexts()[0];
    
    const page = await ctx.newPage();
    await page.goto('https://x.com', {timeout: 10000});
    await page.waitForTimeout(5000);
    
    const cookies = await ctx.cookies();
    const auth = cookies.find(c => c.name === 'auth_token');
    const ct0 = cookies.find(c => c.name === 'ct0');
    console.log('URL:', page.url());
    if (auth) console.log('auth_token=' + auth.value.substring(0,40)+'...');
    if (ct0) console.log('ct0=' + ct0.value.substring(0,40)+'...');
    if (!auth && !ct0) console.log('NOT LOGGED IN');
    
    await browser.close();
  } catch (e) {
    console.log('Error:', e.message);
  }
})();
