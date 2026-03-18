const { chromium } = require('playwright');

(async () => {
  try {
    // Use existing Chrome profile with debugging
    const browser = await chromium.launch({
      headless: false,
      channel: 'chrome',
      args: ['--remote-debugging-port=9222']
    });
    
    // Connect to existing Chrome via CDP
    const wsEndpoint = 'http://localhost:9222';
    
    const browser2 = await chromium.connectOverCDP(wsEndpoint);
    
    const context = browser2.contexts()[0];
    const page = context.pages()[0];
    
    await page.goto('https://x.com');
    await page.waitForTimeout(3000);
    
    const cookies = await context.cookies();
    const authToken = cookies.find(c => c.name === 'auth_token');
    const ct0 = cookies.find(c => c.name === 'ct0');
    
    console.log('=== X Cookies ===');
    if (authToken) console.log('auth_token:', authToken.value.substring(0, 30) + '...');
    if (ct0) console.log('ct0:', ct0.value.substring(0, 30) + '...');
    if (!authToken && !ct0) console.log('No X cookies found - not logged in');
    
    await browser.close();
    await browser2.close();
  } catch (e) {
    console.error('Error:', e.message);
  }
})();
