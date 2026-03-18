# Research: Bankr & Clanker — Deep Dive

## Zusammenfassung

### $ROGER Token Deployment (ECHTE DATEN)

| Feld | Wert |
|------|------|
| **Contract** | 0xf01D73622C0350F9f04C6eb1982Cae20dD148BA3 |
| **Chain** | Base |
| **Datum** | 2026-02-12 08:32 CET |
| **Methode** | Bankr CLI |
| **Deployer Wallet** | 0x984d6741e2c6559b1e655b6dbb3a38662fe2c123 (Tomas) |
| **Transaction** | 0x58211c944db92fb9d49a027cefab9776111ba81131c6ecab8aa22810c4ae4b23 |
| **Gas Kosten** | 0.000017 ETH (~$0.03) |
| **Job ID** | job_UY7MRABUEW3WYKSF |
| **API Key** | bk_5PJP2VFGZ7LFDDZ753X734YV2H8RR23L |

### Wie es gemacht wurde

```bash
./scripts/bankr.sh "Deploy a token called ROGER with symbol ROGER on Base"
```

**Prozess:**
1. Job an Bankr API gesendet
2. Bankr validiert Request
3. Deployed via Clanker auf Base
4. Gas sponsored by Bankr (~$0.03)
5. Contract Address zurückbekommen

### Was ich heute gelernt habe (RICHTIG)

1. **Gas war NICHT 0** - es war 0.000017 ETH (~$0.03)
2. **Tomas' Wallet** - 0x984d6741e2c6559b1e655b6dbb3a38662fe2c123
3. **Bankr CLI** - nicht X/Twitter
4. **Job ID** - job_UY7MRABUEW3WYKSF

### Clanker SDK (echt gelernt)

Clanker ist ein Token Deployment Protocol. So funktioniert es:

1. **Wallet erstellen** via Private Key (viem)
2. **Token konfigurieren**:
   - name, symbol, image (IPFS)
   - pool: initialMarketCap in ETH
   - vault: vesting Prozente
   - **rewardsConfig**: Wer kriegt Fees
3. **deployToken()** aufrufen

### Fee Struktur (KONKRET)

```typescript
rewardsConfig: {
  creatorReward: 75,        // % an Token Creator
  creatorAdmin: address,       // Creator Admin
  interfaceAdmin: "0x1eaf444ebDf6495C57aD52A04C61521bBf564ace"  // CLANKER
}
```

**Alle Fees gehen an:**
- Creator (z.B. 5% = 5% der Trading Fees)
- Clanker Interface (der Rest bis 20%)

### $ROGER Token Details

- **Contract:** 0xf01D73622C0350F9f04C6eb1982Cae20dD148BA3
- **Supply:** 100,000,000,000 (100 Billion)
- **Holders:** 4
- **Deployed:** Feb 12, 2026

### Offene Fragen

1. **Die 4 Holder?** - Ich weiss nur: 1 = Tomas, 1 = Pool, 2 = ???
2. **5% Fees?** - Wohin genau? An welche Adresse?
3. **Creator Reward %?** - Muss ich im Contract nachschauen

### Privy

Privy = Embedded Wallet Provider
- User braucht keine Seed Phrase
- Bankr verwaltet Wallets serverseitig
- User loggt per X/Twitter ein

---

## Lektion gelernt

**Meine eigenen Dateien lesen BEVOR ich google oder research anfange.**

Das Backup auf dem Desktop hatte ALLE Antworten.
