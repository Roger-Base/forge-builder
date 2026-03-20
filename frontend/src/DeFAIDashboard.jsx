import { useState, useEffect } from 'react';
import './DeFAIDashboard.css';

const YIELD_DATA_URL = '/api/yield-data'; // Placeholder for API integration

function DeFAIDashboard() {
  const [yieldData, setYieldData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedProtocol, setSelectedProtocol] = useState('all');
  const [selectedChain, setSelectedChain] = useState('all');
  const [sortBy, setSortBy] = useState('apy'); // apy, tvl, risk

  useEffect(() => {
    // Mock data for Phase 1 (replace with real API in Phase 1.5)
    const mockData = [
      { protocol: 'aave', chain: 'base', name: 'USDC', apy: 4.23, tvl: 45670000, risk: 15 },
      { protocol: 'aave', chain: 'base', name: 'WETH', apy: 2.89, tvl: 23450000, risk: 15 },
      { protocol: 'compound', chain: 'ethereum', name: 'USDC', apy: 3.45, tvl: 89230000, risk: 15 },
      { protocol: 'curve', chain: 'ethereum', name: '3pool', apy: 5.67, tvl: 156780000, risk: 20 },
      { protocol: 'yearn', chain: 'ethereum', name: 'yvUSDC', apy: 6.12, tvl: 67890000, risk: 25 },
      { protocol: 'uniswap', chain: 'arbitrum', name: 'ETH/USDC 0.05%', apy: 12.34, tvl: 34560000, risk: 35 },
    ];
    
    setYieldData(mockData);
    setLoading(false);
  }, []);

  const filteredData = yieldData.filter(item => {
    const protocolMatch = selectedProtocol === 'all' || item.protocol === selectedProtocol;
    const chainMatch = selectedChain === 'all' || item.chain === selectedChain;
    return protocolMatch && chainMatch;
  });

  const sortedData = [...filteredData].sort((a, b) => {
    if (sortBy === 'apy') return b.apy - a.apy;
    if (sortBy === 'tvl') return b.tvl - a.tvl;
    if (sortBy === 'risk') return a.risk - b.risk; // Lower risk first
    return 0;
  });

  const protocols = ['all', 'aave', 'compound', 'curve', 'yearn', 'uniswap'];
  const chains = ['all', 'ethereum', 'polygon', 'arbitrum', 'optimism', 'base'];

  const getRiskLevel = (risk) => {
    if (risk < 20) return 'Low';
    if (risk < 40) return 'Medium';
    return 'High';
  };

  const getRiskColor = (risk) => {
    if (risk < 20) return '#4caf50';
    if (risk < 40) return '#ff9800';
    return '#f44336';
  };

  if (loading) {
    return <div className="defai-dashboard loading">Loading yield data...</div>;
  }

  return (
    <div className="defai-dashboard">
      <header className="dashboard-header">
        <h1>DeFAI Yield Dashboard</h1>
        <p>Autonomous DeFi yield optimization across protocols</p>
      </header>

      <div className="controls">
        <div className="filter-group">
          <label>Protocol:</label>
          <select value={selectedProtocol} onChange={(e) => setSelectedProtocol(e.target.value)}>
            {protocols.map(p => (
              <option key={p} value={p}>{p === 'all' ? 'All Protocols' : p.toUpperCase()}</option>
            ))}
          </select>
        </div>

        <div className="filter-group">
          <label>Chain:</label>
          <select value={selectedChain} onChange={(e) => setSelectedChain(e.target.value)}>
            {chains.map(c => (
              <option key={c} value={c}>{c === 'all' ? 'All Chains' : c.charAt(0).toUpperCase() + c.slice(1)}</option>
            ))}
          </select>
        </div>

        <div className="filter-group">
          <label>Sort by:</label>
          <select value={sortBy} onChange={(e) => setSortBy(e.target.value)}>
            <option value="apy">Highest APY</option>
            <option value="tvl">Highest TVL</option>
            <option value="risk">Lowest Risk</option>
          </select>
        </div>
      </div>

      <div className="yield-table">
        <table>
          <thead>
            <tr>
              <th>Protocol</th>
              <th>Chain</th>
              <th>Pool/Asset</th>
              <th>APY</th>
              <th>TVL</th>
              <th>Risk</th>
            </tr>
          </thead>
          <tbody>
            {sortedData.map((item, idx) => (
              <tr key={idx}>
                <td>{item.protocol.toUpperCase()}</td>
                <td>{item.chain.charAt(0).toUpperCase() + item.chain.slice(1)}</td>
                <td>{item.name}</td>
                <td className="apy">{item.apy.toFixed(2)}%</td>
                <td>${(item.tvl / 1e6).toFixed(2)}M</td>
                <td>
                  <span className="risk-badge" style={{ backgroundColor: getRiskColor(item.risk) }}>
                    {item.risk}/100 ({getRiskLevel(item.risk)})
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {sortedData.length === 0 && (
        <div className="no-results">
          <p>No yield opportunities found for selected filters</p>
        </div>
      )}

      <footer className="dashboard-footer">
        <p>Phase 1: Yield Scanner CLI | Phase 1.5: ERC-8004 Integration | Phase 2: Autonomous Rebalancing</p>
      </footer>
    </div>
  );
}

export default DeFAIDashboard;
