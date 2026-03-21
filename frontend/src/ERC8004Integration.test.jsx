import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import '@testing-library/jest-dom';
import ERC8004Integration from '../src/ERC8004Integration';

// Mock ethers
jest.mock('ethers', () => ({
  BrowserProvider: jest.fn().mockImplementation(() => ({
    getSigner: jest.fn().mockResolvedValue({
      getAddress: jest.fn().mockResolvedValue('0xTestAddress')
    })
  })),
  Contract: jest.fn().mockImplementation(() => ({
    getTotalAgents: jest.fn().mockResolvedValue(BigInt(5)),
    ownerOf: jest.fn().mockResolvedValue('0xOwnerAddress'),
    tokenURI: jest.fn().mockResolvedValue('ipfs://QmTest')
  }))
}));

// Mock window.ethereum
const mockEthProvider = {
  request: jest.fn().mockResolvedValue(undefined),
  isMetaMask: true
};

beforeEach(() => {
  global.window = {
    ethereum: mockEthProvider
  };
});

describe('ERC8004Integration Component', () => {
  test('renders loading state initially', () => {
    render(<ERC8004Integration />);
    
    expect(screen.getByText('Connecting to Base Sepolia...')).toBeInTheDocument();
  });

  test('renders header and description', async () => {
    render(<ERC8004Integration />);
    
    await waitFor(() => {
      expect(screen.getByText('Onchain Agent Registry')).toBeInTheDocument();
      expect(screen.getByText('ERC-8004 compliant identity + reputation on Base')).toBeInTheDocument();
    });
  });

  test('displays stats section', async () => {
    render(<ERC8004Integration />);
    
    await waitFor(() => {
      expect(screen.getByText('Total Agents')).toBeInTheDocument();
      expect(screen.getByText('Network')).toBeInTheDocument();
      expect(screen.getByText('Standard')).toBeInTheDocument();
    });
  });

  test('shows Base Sepolia network stat', async () => {
    render(<ERC8004Integration />);
    
    await waitFor(() => {
      expect(screen.getByText('Base Sepolia')).toBeInTheDocument();
    });
  });

  test('shows ERC-8004 standard stat', async () => {
    render(<ERC8004Integration />);
    
    await waitFor(() => {
      expect(screen.getByText('ERC-8004')).toBeInTheDocument();
    });
  });

  test('displays deployment notice', async () => {
    render(<ERC8004Integration />);
    
    await waitFor(() => {
      expect(screen.getByText('Deploy Status')).toBeInTheDocument();
      expect(screen.getByText('Contracts ready, awaiting deployment:')).toBeInTheDocument();
    });
  });

  test('lists pending contracts', async () => {
    render(<ERC8004Integration />);
    
    await waitFor(() => {
      expect(screen.getByText('IdentityRegistry.sol - Deploy pending (DEPLOYER_KEY)')).toBeInTheDocument();
      expect(screen.getByText('ReputationRegistry.sol - Deploy pending (DEPLOYER_KEY)')).toBeInTheDocument();
      expect(screen.getByText('ValidationRegistry.sol - Deploy pending (DEPLOYER_KEY)')).toBeInTheDocument();
    });
  });

  test('shows notice to update addresses', async () => {
    render(<ERC8004Integration />);
    
    await waitFor(() => {
      expect(screen.getByText('Update contract addresses above after deploy to see live data')).toBeInTheDocument();
    });
  });

  test('displays next steps section', async () => {
    render(<ERC8004Integration />);
    
    await waitFor(() => {
      expect(screen.getByText('Next Steps (Phase 1.5)')).toBeInTheDocument();
    });
  });

  test('lists 5 next steps', async () => {
    render(<ERC8004Integration />);
    
    await waitFor(() => {
      expect(screen.getByText('Deploy contracts to Base Sepolia')).toBeInTheDocument();
      expect(screen.getByText('Register first agent (Roger identity)')).toBeInTheDocument();
      expect(screen.getByText('Submit feedback (test reputation system)')).toBeInTheDocument();
      expect(screen.getByText('Request validation (test validation system)')).toBeInTheDocument();
      expect(screen.getByText('Integrate with Yield Dashboard')).toBeInTheDocument();
    });
  });

  test('shows MetaMask installation message when not available', async () => {
    global.window = { ethereum: undefined };
    
    render(<ERC8004Integration />);
    
    await waitFor(() => {
      expect(screen.getByText('Please install MetaMask')).toBeInTheDocument();
    });
  });

  test('displays connected status when wallet connects', async () => {
    render(<ERC8004Integration />);
    
    // Simulate connection complete
    await waitFor(() => {
      expect(screen.getByText('Connected to Base Sepolia - 5 agents registered')).toBeInTheDocument();
    });
  });

  test('shows total agents count', async () => {
    render(<ERC8004Integration />);
    
    await waitFor(() => {
      expect(screen.getByText('5')).toBeInTheDocument();
    });
  });
});
