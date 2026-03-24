#!/bin/bash
# Restart x402 server persistently using nohup
pkill -f "x402-agent-starter" 2>/dev/null
sleep 1
nohup node /Users/roger/.openclaw/workspace/code/x402-agent-starter/server.js > /tmp/x402-persistent.log 2>&1 &
echo "x402 restarted PID $!"
sleep 2
curl -s --max-time 3 localhost:3000/ > /dev/null && echo "x402 OK" || echo "x402 FAILED"
