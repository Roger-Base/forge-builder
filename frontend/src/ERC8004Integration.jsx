import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import './ERC8004Integration.css';

// Contract addresses (update after deploy to Base Sepolia)
const CONTRACTS = {
  identityRegistry: '0x0000000000000000000000000000000000000000', // TBD
  reputationRegistry: '0x0000000000000000000000000000000000000000', // TBD
  validationRegistry: '0x0000000000000000000000000000000000000000' // TBD
};

// Minimal ABI for reading data
const IDENTITY_ABI = [
  'function getTotalAgents() external view returns (uint256)',
  'function ownerOf(uint256 tokenId) external view returns (address)',
  'function tokenURI(uint256 tokenId) external view returns (string memory)'
];

const REPUTATION_ABI = [
  'function getSummary(uint256 agentId, address[] calldata clients) external view returns (uint256, int128)',
  'function readFeedback(uint256 agentId, address client, uint256 idx) external view returns (int128, uint8, string memory, string memory, bool)'
];

function ERC8004Integration() {
  const [provider, setProvider] = useState(null);
  const [totalAgents, setTotalAgents] = useState(0);
  const [agents, setAgents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [status, setStatus] = useState('');

  // Connect to Base Sepolia
  useEffect(() => {
    if (window.ethereum) {
      const provider = new ethers.BrowserProvider(window.ethereum);
      setProvider(provider);
      
      // Switch to Base Sepolia
      try {
        window.ethereum.request({
          method: 'wallet_switchEthereumChain',
          params: [{ chainId: '0x14a34' }], // 84532 in hex
        });
      } catch (err) {
        console.log('Chain switch error:', err);
      }
      
      fetchTotalAgents(provider);
    } else {
      setStatus('Please install MetaMask');
      setLoading(false);
    }
  }, []);

  const fetchTotalAgents = async (provider) => {
    if (!provider) return;
    try {
      const contract = new ethers.Contract(CONTRACTS.identityRegistry, IDENTITY_ABI, provider);
      const total = await contract.getTotalAgents();
      setTotalAgents(Number(total));
      setStatus(`Connected to Base Sepolia - ${total} agents registered`);
    } catch (error) {
      setStatus('Contract not deployed yet (update addresses after deploy)');
    } finally {
      setLoading(false);
    }
  };

  const fetchAgent = async (agentId) => {
    if (!provider) return null;
    try {
      const contract = new ethers.Contract(CONTRACTS.identityRegistry, IDENTITY_ABI, provider);
      const owner = await contract.ownerOf(agentId);
      const uri = await contract.tokenURI(agentId);
      return { id: agentId, owner, uri };
    } catch (error) {
      return null;
    }
  };

  const getReputation = async (agentId) => {
    if (!provider) return null;
    try {
      const contract = new ethers.Contract(CONTRACTS.reputationRegistry, REPUTATION_ABI, provider);
      const clients = [await provider.getSigner().getAddress()];
      const [count, avg] = await contract.getSummary(agentId, clients);
      return { count: Number(count), avg: Number(avg) };
    } catch (error) {
      return null;
    }
  };

  return (
    <div className="erc8004-integration">
      <h2>Onchain Agent Registry</h2>
      <p>ERC-8004 compliant identity + reputation on Base</p>
      
      <div className="connection-status">
        {loading ? (
          <span>Connecting to Base Sepolia...</span>
        ) : (
          <span className="connected">{status}</span>
        )}
      </div>

      <div className="stats">
        <div className="stat">
          <span className="stat-value">{totalAgents}</span>
          <span className="stat-label">Total Agents</span>
        </div>
        <div className="stat">
          <span className="stat-value">Base Sepolia</span>
          <span className="stat-label">Network</span>
        </div>
        <div className="stat">
          <span className="stat-value">ERC-8004</span>
          <span className="stat-label">Standard</span>
        </div>
      </div>

      <div className="deployment-notice">
        <h3>Deploy Status</h3>
        <p>Contracts ready, awaiting deployment:</p>
        <ul>
          <li>IdentityRegistry.sol - Deploy pending (DEPLOYER_KEY)</li>
          <li>ReputationRegistry.sol - Deploy pending (DEPLOYER_KEY)</li>
          <li>ValidationRegistry.sol - Deploy pending (DEPLOYER_KEY)</li>
        </ul>
        <p className="notice">Update contract addresses above after deploy to see live data</p>
      </div>

      <div className="next-steps">
        <h3>Next Steps (Phase 1.5)</h3>
        <ol>
          <li>Deploy contracts to Base Sepolia</li>
          <li>Register first agent (Roger identity)</li>
          <li>Submit feedback (test reputation system)</li>
          <li>Request validation (test validation system)</li>
          <li>Integrate with Yield Dashboard</li>
        </ol>
      </div>
    </div>
  );
}

export default ERC8004Integration;
