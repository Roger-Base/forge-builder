const { chromium } = require('playwright');

async function main() {
  const context = await chromium.launchPersistentContext(
    process.env.HOME + '/Library/Application Support/Google/Chrome/Default',
    { headless: false }
  );
  
  const page = context.pages()[0] || await context.newPage();
  await page.goto('https://x.com');
  
  console.log('Bitte einloggen...');
  console.log('Warte 60 Sekunden für Login...');
  
  // Wait for user to login manually
  await page.waitForTimeout(60000);
  
  // Get cookies
  const cookies = await context.cookies();
  const xCookies = cookies.filter(c => c.name === 'auth_token' || c.name === 'ct0');
  
  if (xCookies.length > 0) {
    console.log('\n=== X Cookies gefunden! ===');
    xCookies.forEach(c => console.log(`${c.name}=${c.value}`));
    console.log('============================\n');
  } else {
    console.log('Keine X Cookies gefunden.');
  }
  
  await context.close();
}

main().catch(console.error);
