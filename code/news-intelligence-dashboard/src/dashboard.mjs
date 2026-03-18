#!/usr/bin/env node

/**
 * News Intelligence Dashboard
 * Real-time monitoring for AI/crypto/Base news
 */

import https from 'https';
import http from 'http';

const SEARCH_TERMS = process.env.SEARCH_TERMS || 'AI agents,Base blockchain,crypto';
const UPDATE_INTERVAL = parseInt(process.env.UPDATE_INTERVAL || '3600000'); // 1 hour

/**
 * Fetch data from web
 */
function fetchUrl(url) {
  return new Promise((resolve, reject) => {
    const client = url.startsWith('https') ? https : http;
    client.get(url, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve(data));
    }).on('error', reject);
  });
}

/**
 * Search using Brave API (if available)
 */
async function searchBrave(query) {
  const apiKey = process.env.BRAVE_API_KEY;
  if (!apiKey) {
    return { error: 'BRAVE_API_KEY not set' };
  }
  
  const url = `https://api.search.brave.com/res/v1/web/search?q=${encodeURIComponent(query)}&count=10`;
  
  try {
    const data = await fetchUrl(url);
    return JSON.parse(data);
  } catch (e) {
    return { error: e.message };
  }
}

/**
 * Get trending from news APIs
 */
async function getNews() {
  const results = {
    timestamp: new Date().toISOString(),
    searches: {}
  };
  
  // Search terms
  const terms = SEARCH_TERMS.split(',').map(t => t.trim());
  
  for (const term of terms) {
    console.log(`🔍 Searching: ${term}`);
    const searchResults = await searchBrave(term);
    results.searches[term] = searchResults;
  }
  
  return results;
}

/**
 * Format as dashboard
 */
function formatDashboard(results) {
  let output = `# 📰 News Intelligence Dashboard\n`;
  output += `## Last Updated: ${results.timestamp}\n\n`;
  
  output += `### Search Terms: ${SEARCH_TERMS}\n\n`;
  
  for (const [term, data] of Object.entries(results.searches)) {
    output += `## 🔍 ${term}\n`;
    
    if (data.error) {
      output += `❌ Error: ${data.error}\n\n`;
      continue;
    }
    
    if (data.web && data.web.results) {
      const articles = data.web.results.slice(0, 5);
      articles.forEach((article, i) => {
        output += `${i + 1}. [${article.title}](${article.url})\n`;
        if (article.description) {
          output += `   ${article.description.slice(0, 100)}...\n`;
        }
        output += `\n`;
      });
    }
  }
  
  return output;
}

/**
 * Main
 */
async function main() {
  console.log('📰 News Intelligence Dashboard');
  console.log('================================\n');
  
  const results = await getNews();
  
  console.log('\n' + formatDashboard(results));
  
  // Save to file
  const fs = await import('fs');
  fs.writeFileSync('news-dashboard.md', formatDashboard(results));
  console.log('\n✅ Saved to news-dashboard.md');
}

main().catch(console.error);
