#!/usr/bin/env node

/**
 * AI Command Center - Discord Bot
 * Manages multiple AI agents through Discord channels
 */

import { Client, GatewayIntentBits, ChannelType, PermissionsBitField, Guild } from 'discord.js';
import dotenv from 'dotenv';

dotenv.config();

const TOKEN = process.env.DISCORD_BOT_TOKEN;
const GUILD_ID = process.env.DISCORD_GUILD_ID;

const client = new Client({
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMessages,
    GatewayIntentBits.MessageContent
  ]
});

// Channel categories
const CATEGORIES = {
  AGENTS: 'Agents',
  REPORTS: 'Reports',
  RESEARCH: 'Research',
  OPERATIONS: 'Operations'
};

// Agent registry
const agents = new Map();

/**
 * Create channel structure for a new agent
 */
async function createAgentChannels(guild, agentName) {
  const categoryName = CATEGORIES.AGENTS;
  
  // Find or create Agents category
  let category = guild.channels.cache.find(
    c => c.type === ChannelType.GuildCategory && c.name === categoryName
  );
  
  if (!category) {
    category = await guild.channels.create({
      name: categoryName,
      type: ChannelType.GuildCategory
    });
  }
  
  // Create agent channel
  const channel = await guild.channels.create({
    name: `agent-${agentName.toLowerCase().replace(/\s+/g, '-')}`,
    type: ChannelType.GuildText,
    parent: category,
    topic: `Communication channel for ${agentName}`
  });
  
  // Store agent
  agents.set(agentName, {
    channelId: channel.id,
    createdAt: new Date()
  });
  
  return channel;
}

/**
 * Create report channel
 */
async function createReportChannel(guild, reportType) {
  let category = guild.channels.cache.find(
    c => c.type === ChannelType.GuildCategory && c.name === CATEGORIES.REPORTS
  );
  
  if (!category) {
    category = await guild.channels.create({
      name: CATEGORIES.REPORTS,
      type: ChannelType.GuildCategory
    });
  }
  
  const channel = await guild.channels.create({
    name: reportType.toLowerCase().replace(/\s+/g, '-'),
    type: ChannelType.GuildText,
    parent: category,
    topic: `${reportType} reports`
  });
  
  return channel;
}

/**
 * Setup full server structure
 */
async function setupServer(guild) {
  console.log(`\n📀 Setting up server: ${guild.name}`);
  
  // Create categories
  for (const [key, name] of Object.entries(CATEGORIES)) {
    const existing = guild.channels.cache.find(
      c => c.type === ChannelType.GuildCategory && c.name === name
    );
    
    if (!existing) {
      await guild.channels.create({
        name: name,
        type: ChannelType.GuildCategory
      });
      console.log(`  ✅ Created category: ${name}`);
    }
  }
  
  // Create default channels
  const defaultReports = ['daily-brief', 'alerts', 'logs'];
  for (const report of defaultReports) {
    await createReportChannel(guild, report);
    console.log(`  ✅ Created channel: ${report}`);
  }
  
  console.log('\n✅ Server setup complete!');
  console.log('\nAvailable commands:');
  console.log('  !agent add <name>   - Add new agent');
  console.log('  !agent list         - List all agents');
  console.log('  !report <type>      - Generate report');
  console.log('  !status             - Show system status');
}

/**
 * Message handler
 */
client.on('messageCreate', async (message) => {
  if (message.author.bot) return;
  if (!message.content.startsWith('!')) return;
  
  const args = message.content.slice(1).split(' ');
  const command = args.shift().toLowerCase();
  
  const guild = message.guild;
  
  switch (command) {
    case 'agent':
      if (args[0] === 'add' && args[1]) {
        const agentName = args.slice(1).join(' ');
        const channel = await createAgentChannels(guild, agentName);
        message.reply(`✅ Created channel for agent: ${agentName}`);
      } else if (args[0] === 'list') {
        const agentList = Array.from(agents.keys()).join(', ') || 'No agents';
        message.reply(`🤖 Active agents: ${agentList}`);
      }
      break;
      
    case 'report':
      if (args[0]) {
        const channel = await createReportChannel(guild, args.join(' '));
        message.reply(`✅ Created report channel: ${args.join(' ')}`);
      }
      break;
      
    case 'status':
      message.reply(`
📊 AI Command Center Status

Agents: ${agents.size}
Categories: ${Object.keys(CATEGORIES).length}
Guild: ${guild.name}
      `);
      break;
      
    case 'setup':
      await setupServer(guild);
      message.reply('✅ Server configured!');
      break;
  }
});

/**
 * Ready handler
 */
client.on('ready', () => {
  console.log(`\n🤖 AI Command Center online!`);
  console.log(`Logged in as: ${client.user.tag}`);
  
  // Setup first guild
  if (client.guilds.cache.size > 0) {
    const guild = client.guilds.cache.first();
    console.log(`Server: ${guild.name}`);
  }
});

// Start bot
if (!TOKEN) {
  console.error('❌ DISCORD_BOT_TOKEN not set in .env');
  console.log('\nTo run:');
  console.log('1. Create .env file with DISCORD_BOT_TOKEN=your_token');
  console.log('2. Run: node src/discord-bot.mjs');
  console.log('3. Invite bot to your server');
  process.exit(1);
}

client.login(TOKEN);
