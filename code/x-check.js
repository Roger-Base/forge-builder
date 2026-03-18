const { chromium } = require('playwright');

(async () => {
  try {
    // Connect to existing Chrome via CDP
    const browser = await chromium.connectOverCDP('http://localhost:9222');
    
    const context = browser.contexts()[0];
    const page = context.pages()[0] || await context.newPage();
    
    console.log('Aktuelle Seite:', await page.title());
    
    // Navigate to x.com
    await page.goto('https://x.com');
    await page.waitForTimeout(5000);
    
    // Check if logged in
    const cookies = await context.cookies();
    const authToken = cookies.find(c => c.name === 'auth_token');
    const ct0 = cookies.find(c => c.name === 'ct0');
    
    console.log('\n=== Cookies ===');
    if (authToken) {
      console.log('auth_token:', authToken.value.substring(0, 40) + '...');
    }
    if (ct0) {
      console.log('ct0:', ct0.value.substring(0, 40) + '...');
    }
    if (!authToken && !ct0) {
      console.log('Nicht eingeloggt - bitte manuell einloggen');
      console.log('Drücke Enter wenn eingeloggt...');
    }
    
    await browser.close();
  } catch (e) {
    console.error('Error:', e.message);
  }
})();
