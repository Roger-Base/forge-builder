#!/usr/bin/env node

/**
 * Workflow Interviewer
 * Asks questions to understand your work and suggest automations
 */

import readline from 'readline';

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

/**
 * The 39 questions framework
 */
const QUESTIONS = {
  timeAnalysis: [
    "What is your typical workday hour breakdown?",
    "Which tasks take most of your time?",
    "What do you do repeatedly every day?",
    "Which tasks do you hate doing manually?",
    "What takes longer than it should?"
  ],
  painPoints: [
    "What's the biggest bottleneck in your workflow?",
    "Which app or tool frustrates you most?",
    "What information do you constantly look up?",
    "What decisions do you repeat frequently?",
    "What's something you keep forgetting to do?"
  ],
  toolsIntegration: [
    "What apps do you use daily?",
    "Which apps have APIs you wish worked together?",
    "What data do you copy between apps?",
    "What notifications do you ignore?",
    "What's your current note-taking system?"
  ],
  goalsOptimization: [
    "What would you do with 2 extra hours daily?",
    "What's one skill you wish you had time for?",
    "What metrics do you wish you tracked?",
    "What's a process you'd like to automate but don't know how?",
    "If you could clone yourself for one task, which?"
  ]
};

/**
 * Ask a question
 */
function ask(question) {
  return new Promise((resolve) => {
    rl.question(`\n❓ ${question}\n> `, resolve);
  });
}

/**
 * Run interview
 */
async function runInterview() {
  console.clear();
  console.log('═══════════════════════════════════════');
  console.log('   WORKFLOW INTERVIEWER');
  console.log('═══════════════════════════════════════');
  console.log('\nI\'ll ask you questions about your work.');
  console.log('Your answers will help me suggest automations.\n');
  
  const answers = {
    timeAnalysis: [],
    painPoints: [],
    toolsIntegration: [],
    goalsOptimization: []
  };
  
  // Time Analysis
  console.log('\n📊 PHASE 1: TIME ANALYSIS');
  console.log('─'.repeat(40));
  for (const q of QUESTIONS.timeAnalysis) {
    const answer = await ask(q);
    answers.timeAnalysis.push({ question: q, answer });
  }
  
  // Pain Points
  console.log('\n😖 PHASE 2: PAIN POINTS');
  console.log('─'.repeat(40));
  for (const q of QUESTIONS.painPoints) {
    const answer = await ask(q);
    answers.painPoints.push({ question: q, answer });
  }
  
  // Tools Integration
  console.log('\n🔧 PHASE 3: TOOLS & INTEGRATION');
  console.log('─'.repeat(40));
  for (const q of QUESTIONS.toolsIntegration) {
    const answer = await ask(q);
    answers.toolsIntegration.push({ question: q, answer });
  }
  
  // Goals Optimization
  console.log('\n🎯 PHASE 4: GOALS & OPTIMIZATION');
  console.log('─'.repeat(40));
  for (const q of QUESTIONS.goalsOptimization) {
    const answer = await ask(q);
    answers.goalsOptimization.push({ question: q, answer });
  }
  
  // Generate recommendations
  console.clear();
  console.log('═══════════════════════════════════════');
  console.log('   RECOMMENDATIONS');
  console.log('═══════════════════════════════════════\n');
  
  console.log('Based on your answers, here are automation suggestions:\n');
  
  // Analyze and suggest
  console.log('🔴 HIGH IMPACT AUTOMATIONS:');
  console.log('─'.repeat(40));
  
  // Check for patterns
  const painCount = answers.painPoints.filter(a => a.answer.length > 20).length;
  const timeCount = answers.timeAnalysis.filter(a => a.answer.toLowerCase().includes('hour') || a.answer.toLowerCase().includes('time')).length;
  
  if (painCount >= 3) {
    console.log('• Daily standup summarizer');
    console.log('• Email triage assistant');
    console.log('• Meeting notes auto-generator');
  }
  
  if (timeCount >= 2) {
    console.log('• Time tracking automation');
    console.log('• Schedule optimizer');
  }
  
  console.log('\n🟡 MEDIUM IMPACT AUTOMATIONS:');
  console.log('─'.repeat(40));
  console.log('• Cross-app data sync');
  console.log('• Notification filter');
  console.log('• Weekly report generator');
  
  console.log('\n🟢 LOW IMPACT / NICE TO HAVE:');
  console.log('─'.repeat(40));
  console.log('• Custom keyboard shortcuts');
  console.log('• Bookmark manager');
  console.log('• Daily motivation scheduler');
  
  console.log('\n═══════════════════════════════════════');
  console.log('Thanks for the interview! 🦞');
  
  rl.close();
}

// Run
runInterview().catch(() => {
  rl.close();
});
