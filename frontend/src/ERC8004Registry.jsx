import { useState, useEffect } from 'react';
import { ethers } from 'ethers';

// Contract ABIs (simplified - full ABI from artifacts)
const IDENTITY_REGISTRY_ABI = [
  "function register(string memory agentURI) external returns (uint256)",
  "function ownerOf(uint256 tokenId) external view returns (address)",
  "function tokenURI(uint256 tokenId) external view returns (string memory)",
  "function getTotalAgents() external view returns (uint256)",
  "function setAgentWallet(uint256 agentId, address newWallet, uint256 deadline, bytes calldata signature) external",
  "event Registered(uint256 indexed agentId, string agentURI, address indexed owner)"
];

const REPUTATION_REGISTRY_ABI = [
  "function giveFeedback(uint256 agentId, int128 value, string calldata tag1) external",
  "function getSummary(uint256 agentId, address[] calldata clients) external view returns (uint256, int128)",
  "function readFeedback(uint256 agentId, address client, uint256 idx) external view returns (int128, uint8, string memory, string memory, bool)",
  "event NewFeedback(uint256 indexed agentId, address indexed client, uint256 feedbackIndex, int128 value, string indexed tag1)"
];

const VALIDATION_REGISTRY_ABI = [
  "function validationRequest(address validator, uint256 agentId, string calldata requestURI, bytes32 requestHash) external",
  "function getValidationStatus(bytes32 requestHash) external view returns (address, uint256, uint8, bytes32, string memory, uint256)",
  "event ValidationRequested(address indexed validator, uint256 indexed agentId, string requestURI, bytes32 indexed requestHash)"
];

// Contract addresses (update after deploy)
const CONTRACTS = {
  identityRegistry: '0x0000000000000000000000000000000000000000', // TBD after deploy
  reputationRegistry: '0x0000000000000000000000000000000000000000', // TBD
  validationRegistry: '0x0000000000000000000000000000000000000000' // TBD
};

const RPC_URL = 'https://sepolia.base.org';

function ERC8004Registry() {
  const [provider, setProvider] = useState(null);
  const [signer, setSigner] = useState(null);
  const [account, setAccount] = useState(null);
  const [totalAgents, setTotalAgents] = useState(0);
  const [loading, setLoading] = useState(false);
  const [status, setStatus] = useState('');

  // Connect wallet
  const connectWallet = async () => {
    if (window.ethereum) {
      try {
        const provider = new ethers.BrowserProvider(window.ethereum);
        const signer = await provider.getSigner();
        const account = await signer.getAddress();
        
        setProvider(provider);
        setSigner(signer);
        setAccount(account);
        setStatus('Wallet connected: ' + account);
      } catch (error) {
        setStatus('Error: ' + error.message);
      }
    } else {
      setStatus('Please install MetaMask');
    }
  };

  // Fetch total agents
  const fetchTotalAgents = async () => {
    if (!provider) return;
    try {
      const contract = new ethers.Contract(CONTRACTS.identityRegistry, IDENTITY_REGISTRY_ABI, provider);
      const total = await contract.getTotalAgents();
      setTotalAgents(Number(total));
    } catch (error) {
      console.error('Error fetching total agents:', error);
    }
  };

  useEffect(() => {
    if (provider) {
      fetchTotalAgents();
    }
  }, [provider]);

  // Register agent
  const registerAgent = async (agentURI) => {
    if (!signer) {
      setStatus('Please connect wallet first');
      return;
    }
    
    setLoading(true);
    try {
      const contract = new ethers.Contract(CONTRACTS.identityRegistry, IDENTITY_REGISTRY_ABI, signer);
      const tx = await contract.register(agentURI);
      setStatus('Transaction sent: ' + tx.hash);
      await tx.wait();
      setStatus('Agent registered successfully!');
      fetchTotalAgents();
    } catch (error) {
      setStatus('Error: ' + error.message);
    } finally {
      setLoading(false);
    }
  };

  // Give feedback
  const giveFeedback = async (agentId, value, tag1) => {
    if (!signer) {
      setStatus('Please connect wallet first');
      return;
    }
    
    setLoading(true);
    try {
      const contract = new ethers.Contract(CONTRACTS.reputationRegistry, REPUTATION_REGISTRY_ABI, signer);
      const tx = await contract.giveFeedback(agentId, value, tag1);
      setStatus('Feedback submitted: ' + tx.hash);
      await tx.wait();
      setStatus('Feedback recorded!');
    } catch (error) {
      setStatus('Error: ' + error.message);
    } finally {
      setLoading(false);
    }
  };

  // Request validation
  const requestValidation = async (validator, agentId, requestURI) => {
    if (!signer) {
      setStatus('Please connect wallet first');
      return;
    }
    
    setLoading(true);
    try {
      const contract = new ethers.Contract(CONTRACTS.validationRegistry, VALIDATION_REGISTRY_ABI, signer);
      const requestHash = ethers.keccak256(ethers.toUtf8Bytes(requestURI));
      const tx = await contract.validationRequest(validator, agentId, requestURI, requestHash);
      setStatus('Validation requested: ' + tx.hash);
      await tx.wait();
      setStatus('Validation request sent!');
    } catch (error) {
      setStatus('Error: ' + error.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="erc8004-registry">
      <h2>ERC-8004 Agent Registry</h2>
      
      <div className="wallet-section">
        <button onClick={connectWallet} disabled={account}>
          {account ? 'Connected' : 'Connect Wallet'}
        </button>
        {account && <span className="account">Account: {account}</span>}
      </div>

      <div className="stats">
        <p>Total Agents Registered: {totalAgents}</p>
      </div>

      <div className="actions">
        <h3>Register Agent</h3>
        <input 
          type="text" 
          placeholder="Agent URI (e.g., ipfs://Qm...)" 
          id="agentURI"
        />
        <button onClick={() => {
          const uri = document.getElementById('agentURI').value;
          registerAgent(uri);
        }} disabled={loading}>
          {loading ? 'Processing...' : 'Register'}
        </button>
      </div>

      <div className="actions">
        <h3>Give Feedback</h3>
        <input type="number" placeholder="Agent ID" id="feedbackAgentId" />
        <input type="number" placeholder="Value (-100 to 100)" id="feedbackValue" />
        <input type="text" placeholder="Tag (e.g., quality)" id="feedbackTag" />
        <button onClick={() => {
          const agentId = parseInt(document.getElementById('feedbackAgentId').value);
          const value = parseInt(document.getElementById('feedbackValue').value);
          const tag = document.getElementById('feedbackTag').value;
          giveFeedback(agentId, value, tag);
        }} disabled={loading}>
          {loading ? 'Processing...' : 'Submit Feedback'}
        </button>
      </div>

      <div className="actions">
        <h3>Request Validation</h3>
        <input type="text" placeholder="Validator Address" id="validatorAddress" />
        <input type="number" placeholder="Agent ID" id="validationAgentId" />
        <input type="text" placeholder="Request URI" id="requestURI" />
        <button onClick={() => {
          const validator = document.getElementById('validatorAddress').value;
          const agentId = parseInt(document.getElementById('validationAgentId').value);
          const uri = document.getElementById('requestURI').value;
          requestValidation(validator, agentId, uri);
        }} disabled={loading}>
          {loading ? 'Processing...' : 'Request Validation'}
        </button>
      </div>

      {status && <div className="status">{status}</div>}
    </div>
  );
}

export default ERC8004Registry;
