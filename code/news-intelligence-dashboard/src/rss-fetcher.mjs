#!/usr/bin/env node

/**
 * Simple News Fetcher
 * Uses RSS feeds for news aggregation
 */

import https from 'https';
import http from 'http';

// RSS Feed URLs
const RSS_FEEDS = {
  'CoinDesk': 'https://www.coindesk.com/feed',
  'The Block': 'https://www.theblock.co/feed',
  'Decrypt': 'https://decrypt.co/feed',
  'TechCrunch': 'https://techcrunch.com/feed'
};

/**
 * Fetch RSS feed
 */
function fetchFeed(name, url) {
  return new Promise((resolve) => {
    const client = url.startsWith('https') ? https : http;
    
    client.get(url, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        // Simple RSS parsing
        const items = [];
        const itemMatches = data.matchAll(/<item[^>]*>([\s\S]*?)<\/item>/gi);
        
        let count = 0;
        for (const match of itemMatches) {
          if (count >= 5) break;
          
          const item = match[1];
          const titleMatch = item.match(/<title[^>]*><!\[CDATA\[(.*?)\]\]><\/title>|<title[^>]*>(.*?)<\/title>/);
          const linkMatch = item.match(/<link[^>]*>(.*?)<\/link>/);
          const descMatch = item.match(/<description[^>]*><!\[CDATA\[(.*?)\]\]><\/description>|<description[^>]*>(.*?)<\/description>/);
          
          if (titleMatch) {
            items.push({
              title: (titleMatch[1] || titleMatch[2] || '').trim(),
              link: linkMatch ? linkMatch[1].trim() : '',
              description: descMatch ? (descMatch[1] || descMatch[2] || '').trim().slice(0, 150) : ''
            });
            count++;
          }
        }
        
        resolve({ name, items, count: items.length });
      });
    }).on('error', () => {
      resolve({ name, items: [], error: true });
    });
  });
}

/**
 * Main
 */
async function main() {
  console.log('📰 Fetching news from RSS feeds...\n');
  
  const results = await Promise.all(
    Object.entries(RSS_FEEDS).map(([name, url]) => fetchFeed(name, url))
  );
  
  // Format output
  console.log('═══════════════════════════════════════');
  console.log('       LATEST NEWS');
  console.log('═══════════════════════════════════════\n');
  
  results.forEach(feed => {
    console.log(`📡 ${feed.name}`);
    console.log('─'.repeat(40));
    
    if (feed.error) {
      console.log('  ❌ Error fetching\n');
      return;
    }
    
    feed.items.forEach((item, i) => {
      const title = item.title.slice(0, 60);
      console.log(`  ${i + 1}. ${title}${title.length >= 60 ? '...' : ''}`);
    });
    console.log('');
  });
  
  // Save to markdown
  const fs = await import('fs');
  let md = '# News Feed\n\n';
  
  results.forEach(feed => {
    md += `## ${feed.name}\n\n`;
    if (feed.error) {
      md += '*Error fetching*\n\n';
      return;
    }
    feed.items.forEach(item => {
      md += `- [${item.title}](${item.link})\n`;
    });
    md += '\n';
  });
  
  fs.writeFileSync('news-feed.md', md);
  console.log('✅ Saved to news-feed.md');
}

main().catch(console.error);
