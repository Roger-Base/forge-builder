import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import '@testing-library/jest-dom';
import ERC8004Registry from '../src/ERC8004Registry';

// Mock ethers
jest.mock('ethers', () => ({
  BrowserProvider: jest.fn().mockImplementation(() => ({
    getSigner: jest.fn().mockResolvedValue({
      getAddress: jest.fn().mockResolvedValue('0xTestAddress')
    })
  })),
  Contract: jest.fn().mockImplementation(() => ({
    register: jest.fn().mockResolvedValue({
      hash: '0xTestTx',
      wait: jest.fn().mockResolvedValue({
        logs: [{ fragment: { name: 'Registered' }, args: { agentId: BigInt(1) } }]
      })
    }),
    getTotalAgents: jest.fn().mockResolvedValue(BigInt(3)),
    giveFeedback: jest.fn().mockResolvedValue({
      wait: jest.fn().mockResolvedValue({})
    }),
    validationRequest: jest.fn().mockResolvedValue({
      wait: jest.fn().mockResolvedValue({})
    })
  }))
}));

// Mock window.ethereum
const mockEthProvider = {
  request: jest.fn().mockResolvedValue(undefined)
};

beforeEach(() => {
  global.window = {
    ethereum: mockEthProvider
  };
});

describe('ERC8004Registry Component', () => {
  test('renders connect wallet button initially', () => {
    render(<ERC8004Registry />);
    
    expect(screen.getByText('Connect Wallet')).toBeInTheDocument();
    expect(screen.getByText('Total Agents Registered: 0')).toBeInTheDocument();
  });

  test('connects wallet successfully', async () => {
    render(<ERC8004Registry />);
    
    fireEvent.click(screen.getByText('Connect Wallet'));
    
    await waitFor(() => {
      expect(screen.getByText('Connected')).toBeInTheDocument();
      expect(screen.getByText('Account: 0xTestAddress')).toBeInTheDocument();
    });
  });

  test('displays total agents after connection', async () => {
    render(<ERC8004Registry />);
    
    fireEvent.click(screen.getByText('Connect Wallet'));
    
    await waitFor(() => {
      expect(screen.getByText('Total Agents Registered: 3')).toBeInTheDocument();
    });
  });

  test('registers agent with valid URI', async () => {
    render(<ERC8004Registry />);
    
    // Connect wallet first
    fireEvent.click(screen.getByText('Connect Wallet'));
    
    // Enter agent URI
    const uriInput = screen.getByPlaceholderText('Agent URI (e.g., ipfs://Qm...)');
    fireEvent.change(uriInput, { target: { value: 'ipfs://QmTest123' } });
    
    // Click register
    fireEvent.click(screen.getByText('Register'));
    
    await waitFor(() => {
      expect(screen.getByText('Agent registered successfully!')).toBeInTheDocument();
    });
  });

  test('shows error when wallet not connected', async () => {
    render(<ERC8004Registry />);
    
    const uriInput = screen.getByPlaceholderText('Agent URI (e.g., ipfs://Qm...)');
    fireEvent.change(uriInput, { target: { value: 'ipfs://QmTest123' } });
    
    fireEvent.click(screen.getByText('Register'));
    
    await waitFor(() => {
      expect(screen.getByText('Please connect wallet first')).toBeInTheDocument();
    });
  });

  test('submits feedback successfully', async () => {
    render(<ERC8004Registry />);
    
    // Connect wallet
    fireEvent.click(screen.getByText('Connect Wallet'));
    
    // Fill feedback form
    fireEvent.change(screen.getByPlaceholderText('Agent ID'), { target: { value: '1' } });
    fireEvent.change(screen.getByPlaceholderText('Value (-100 to 100)'), { target: { value: '80' } });
    fireEvent.change(screen.getByPlaceholderText('Tag (e.g., quality)'), { target: { value: 'quality' } });
    
    // Submit
    fireEvent.click(screen.getByText('Submit Feedback'));
    
    await waitFor(() => {
      expect(screen.getByText('Feedback recorded!')).toBeInTheDocument();
    });
  });

  test('requests validation successfully', async () => {
    render(<ERC8004Registry />);
    
    // Connect wallet
    fireEvent.click(screen.getByText('Connect Wallet'));
    
    // Fill validation form
    fireEvent.change(screen.getByPlaceholderText('Validator Address'), { target: { value: '0xValidator' } });
    fireEvent.change(screen.getByPlaceholderText('Agent ID'), { target: { value: '1' } });
    fireEvent.change(screen.getByPlaceholderText('Request URI'), { target: { value: 'ipfs://QmValidation' } });
    
    // Submit
    fireEvent.click(screen.getByText('Request Validation'));
    
    await waitFor(() => {
      expect(screen.getByText('Validation request sent!')).toBeInTheDocument();
    });
  });

  test('handles MetaMask not installed', async () => {
    global.window = { ethereum: undefined };
    
    render(<ERC8004Registry />);
    
    fireEvent.click(screen.getByText('Connect Wallet'));
    
    await waitFor(() => {
      expect(screen.getByText('Please install MetaMask')).toBeInTheDocument();
    });
  });

  test('displays loading state during transaction', async () => {
    render(<ERC8004Registry />);
    
    // Connect wallet
    fireEvent.click(screen.getByText('Connect Wallet'));
    
    await waitFor(() => {
      expect(screen.getByText('Connected')).toBeInTheDocument();
    });
    
    // Enter URI and click register
    const uriInput = screen.getByPlaceholderText('Agent URI (e.g., ipfs://Qm...)');
    fireEvent.change(uriInput, { target: { value: 'ipfs://QmTest123' } });
    
    fireEvent.click(screen.getByText('Register'));
    
    // Check loading state
    expect(screen.getByText('Processing...')).toBeInTheDocument();
  });
});
