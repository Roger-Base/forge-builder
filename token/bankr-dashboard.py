#!/usr/bin/env python3
"""
Roger's Bankr Dashboard
Real-time wallet + market overview 🟦
"""

import json
import subprocess
import sys
from datetime import datetime
from pathlib import Path

# Config
CONFIG = {
    "evm_wallet": "0x984d6741e2c6559b1e655b6dbb3a38662fe2c123",
    "solana_wallet": "AeyePdw7yk3QdfJP3EzNpyy4EF5hgtxkcxPCMKHAYp2y",
    "api_key": "bk_5PJP2VFGZ7LFDDZ753X734YV2H8RR23L",
    "api_url": "https://api.bankr.bot"
}

def get_bankr_balance():
    """Get wallet balance via Bankr API"""
    try:
        cmd = [
            "curl", "-s", "-X", "POST",
            f"{CONFIG['api_url']}/agent/prompt",
            "-H", f"X-API-Key: {CONFIG['api_key']}",
            "-H", "Content-Type: application/json",
            "-d", '{"prompt": "What is my ETH and USDC balance on Base? List all tokens with USD values"}'
        ]
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        data = json.loads(result.stdout)
        return data.get("jobId"), data.get("status")
    except Exception as e:
        return None, f"Error: {e}"

def show_dashboard():
    """Display Bankr Dashboard"""
    print("╔══════════════════════════════════════════════════════════╗")
    print("║              ROGER'S BANKR DASHBOARD 🟦                  ║")
    print("╚══════════════════════════════════════════════════════════╝")
    print()
    print(f"📅 {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    # Wallets
    print("💼 WALLETS")
    print(f"   EVM:    {CONFIG['evm_wallet'][:20]}...")
    print(f"   Solana: {CONFIG['solana_wallet'][:20]}...")
    print()
    
    # Submit balance check
    print("📊 BALANCE CHECK")
    job_id, status = get_bankr_balance()
    if job_id:
        print(f"   Job submitted: {job_id}")
        print(f"   Status: {status}")
        print(f"   Check: bankr-status {job_id}")
    else:
        print(f"   {status}")
    print()
    
    # Quick Actions
    print("⚡ QUICK ACTIONS")
    print("   1. Check Balance    → bankr-balance.sh")
    print("   2. Post to X        → x_post.py 'text'")
    print("   3. View Dashboard   → roger-dashboard.sh")
    print("   4. Git Status       → git log --oneline -5")
    print()
    
    # Token Watchlist
    print("📈 WATCHLIST (manual update)")
    print("   ETH    → $... (check: 'What's ETH price?')")
    print("   USDC   → $1.00 (stable)")
    print("   BNKR   → $... (check: 'What's BNKR price?')")
    print()
    
    # Today's Goal
    print("🎯 TODAY'S GOAL")
    print("   [ ] Deploy ROGER token on Base")
    print("   [ ] Post 3x on X")
    print("   [ ] Check ClawTasks for bounties")
    print()
    
    print("╚══════════════════════════════════════════════════════════╝")

if __name__ == "__main__":
    show_dashboard()
