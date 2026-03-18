const { chromium } = require('playwright');

(async () => {
  const context = await chromium.launchPersistentContext(
    process.env.HOME + '/Library/Application Support/Google/Chrome/Default',
    { headless: false, channel: 'chrome' }
  );
  
  const page = context.pages()[0] || await context.newPage();
  
  console.log('Öffne x.com...');
  await page.goto('https://x.com');
  await page.waitForTimeout(3000);
  
  // Check if we need to login
  const pageContent = await page.content();
  
  if (pageContent.includes('Anmelden') || pageContent.includes('Sign in')) {
    console.log('Need to login...');
    
    // Click login button or navigate to login
    try {
      await page.click('text=Anmelden', { timeout: 5000 });
    } catch {
      await page.goto('https://x.com/i/flow/login');
      await page.waitForTimeout(2000);
    }
    
    // Look for Google login
    console.log('Suche Google Login...');
    try {
      await page.click('text=Google', { timeout: 5000 });
    } catch {
      console.log('Google button not found, trying direct URL...');
    }
    
    // Wait for user to complete login
    console.log('Warte auf Login (60 Sekunden)...');
    await page.waitForTimeout(60000);
  }
  
  // Get cookies after potential login
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
    console.log('Keine X Cookies gefunden');
  }
  
  await context.close();
})();
