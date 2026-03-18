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
    await page.waitForTimeout(2000);
    
    // Check if login button exists - if so, click it
    const loginButton = await page.$('text=Anmelden');
    if (loginButton) {
      console.log('Klicke Anmelden...');
      await loginButton.click();
      await page.waitForTimeout(2000);
      
      // Click Google login
      const googleButton = await page.$('text=Google');
      if (googleButton) {
        console.log('Klicke Google...');
        await googleButton.click();
      }
    }
    
    console.log('\n=== Bitte jetzt einloggen ===');
    console.log('Warte 90 Sekunden für Login...');
    
    // Wait for user to login
    await page.waitForTimeout(90000);
    
    // Get cookies after login
    const cookies = await context.cookies();
    const authToken = cookies.find(c => c.name === 'auth_token');
    const ct0 = cookies.find(c => c.name === 'ct0');
    
    console.log('\n=== Cookies nach Login ===');
    if (authToken) {
      console.log('auth_token:', authToken.value);
      console.log('\nFühre aus:');
      console.log('bird config set auth_token "' + authToken.value + '"');
    }
    if (ct0) {
      console.log('ct0:', ct0.value);
      console.log('bird config set ct0 "' + ct0.value + '"');
    }
    if (!authToken && !ct0) {
      console.log('Immer noch nicht eingeloggt');
    }
    
    await browser.close();
  } catch (e) {
    console.error('Error:', e.message);
  }
})();
