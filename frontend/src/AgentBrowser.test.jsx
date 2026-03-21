import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import '@testing-library/jest-dom';
import AgentBrowser from '../src/AgentBrowser';

// Mock fetch for agents data
global.fetch = jest.fn().mockResolvedValue({
  json: jest.fn().mockResolvedValue({
    agents: [
      { id: 1, name: 'Agent One', description: 'First agent', category: 'DeFi', capabilities: ['trading', 'yield'], status: 'Active' },
      { id: 2, name: 'Agent Two', description: 'Second agent', category: 'NFT', capabilities: ['minting'], status: 'Active' },
      { id: 3, name: 'Agent Three', description: 'Third agent', category: 'DeFi', capabilities: ['lending'], status: 'Active' },
      { id: 4, name: 'Agent Four', description: 'Fourth agent', category: 'Gaming', capabilities: ['gaming', 'NFT'], status: 'Active' }
    ]
  })
});

beforeEach(() => {
  jest.clearAllMocks();
});

describe('AgentBrowser Component', () => {
  test('renders loading state initially', () => {
    render(<AgentBrowser />);
    
    expect(screen.getByText('Loading agents...')).toBeInTheDocument();
  });

  test('renders stats bar after loading', async () => {
    render(<AgentBrowser />);
    
    await waitFor(() => {
      expect(screen.getByText('Total Agents')).toBeInTheDocument();
    });
    
    expect(screen.getByText('4')).toBeInTheDocument();
  });

  test('renders category stats', async () => {
    render(<AgentBrowser />);
    
    await waitFor(() => {
      expect(screen.getByText('DeFi')).toBeInTheDocument();
      expect(screen.getByText('NFT')).toBeInTheDocument();
      expect(screen.getByText('Gaming')).toBeInTheDocument();
    });
  });

  test('renders search input', async () => {
    render(<AgentBrowser />);
    
    await waitFor(() => {
      expect(screen.getByPlaceholderText('Search by name, description, or capability...')).toBeInTheDocument();
    });
  });

  test('renders category filter buttons', async () => {
    render(<AgentBrowser />);
    
    await waitFor(() => {
      expect(screen.getByText('All')).toBeInTheDocument();
      expect(screen.getByText('DeFi')).toBeInTheDocument();
      expect(screen.getByText('NFT')).toBeInTheDocument();
      expect(screen.getByText('Gaming')).toBeInTheDocument();
    });
  });

  test('displays agent cards', async () => {
    render(<AgentBrowser />);
    
    await waitFor(() => {
      expect(screen.getByText('Agent One')).toBeInTheDocument();
      expect(screen.getByText('Agent Two')).toBeInTheDocument();
      expect(screen.getByText('Agent Three')).toBeInTheDocument();
      expect(screen.getByText('Agent Four')).toBeInTheDocument();
    });
  });

  test('displays agent descriptions', async () => {
    render(<AgentBrowser />);
    
    await waitFor(() => {
      expect(screen.getByText('First agent')).toBeInTheDocument();
      expect(screen.getByText('Second agent')).toBeInTheDocument();
    });
  });

  test('displays capability tags', async () => {
    render(<AgentBrowser />);
    
    await waitFor(() => {
      expect(screen.getByText('trading')).toBeInTheDocument();
      expect(screen.getByText('yield')).toBeInTheDocument();
      expect(screen.getByText('minting')).toBeInTheDocument();
    });
  });

  test('displays agent status', async () => {
    render(<AgentBrowser />);
    
    await waitFor(() => {
      expect(screen.getByText('Active')).toBeInTheDocument();
    });
  });

  test('displays view profile links', async () => {
    render(<AgentBrowser />);
    
    await waitFor(() => {
      expect(screen.getByText('View Profile')).toBeInTheDocument();
    });
  });

  test('filters by category', async () => {
    render(<AgentBrowser />);
    
    await waitFor(() => {
      const defiButton = screen.getByText('DeFi');
      fireEvent.click(defiButton);
    });
    
    await waitFor(() => {
      expect(screen.getByText('Agent One')).toBeInTheDocument();
      expect(screen.getByText('Agent Three')).toBeInTheDocument();
      expect(screen.queryByText('Agent Two')).not.toBeInTheDocument();
      expect(screen.queryByText('Agent Four')).not.toBeInTheDocument();
    });
  });

  test('filters by search term', async () => {
    render(<AgentBrowser />);
    
    await waitFor(() => {
      const searchInput = screen.getByPlaceholderText('Search by name, description, or capability...');
      fireEvent.change(searchInput, { target: { value: 'trading' } });
    });
    
    await waitFor(() => {
      expect(screen.getByText('Agent One')).toBeInTheDocument();
      expect(screen.queryByText('Agent Two')).not.toBeInTheDocument();
    });
  });

  test('shows no results when filter matches nothing', async () => {
    render(<AgentBrowser />);
    
    await waitFor(() => {
      const searchInput = screen.getByPlaceholderText('Search by name, description, or capability...');
      fireEvent.change(searchInput, { target: { value: 'nonexistent' } });
    });
    
    await waitFor(() => {
      expect(screen.getByText('No agents found matching your criteria')).toBeInTheDocument();
    });
  });

  test('sorts by category correctly', async () => {
    render(<AgentBrowser />);
    
    // Click NFT category
    await waitFor(() => {
      const nftButton = screen.getByText('NFT');
      fireEvent.click(nftButton);
    });
    
    await waitFor(() => {
      expect(screen.getByText('Agent Two')).toBeInTheDocument();
      expect(screen.queryByText('Agent One')).not.toBeInTheDocument();
    });
  });

  test('resets filter when All is clicked', async () => {
    render(<AgentBrowser />);
    
    // First filter by DeFi
    await waitFor(() => {
      const defiButton = screen.getByText('DeFi');
      fireEvent.click(defiButton);
    });
    
    // Then click All
    await waitFor(() => {
      const allButton = screen.getByText('All');
      fireEvent.click(allButton);
    });
    
    await waitFor(() => {
      expect(screen.getByText('Agent One')).toBeInTheDocument();
      expect(screen.getByText('Agent Two')).toBeInTheDocument();
      expect(screen.getByText('Agent Three')).toBeInTheDocument();
      expect(screen.getByText('Agent Four')).toBeInTheDocument();
    });
  });

  test('displays correct stats count', async () => {
    render(<AgentBrowser />);
    
    await waitFor(() => {
      const totalStat = screen.getAllByText('4')[0];
      expect(totalStat).toBeInTheDocument();
    });
  });

  test('handles fetch error gracefully', async () => {
    global.fetch.mockRejectedValueOnce(new Error('Network error'));
    
    render(<AgentBrowser />);
    
    await waitFor(() => {
      expect(screen.getByText('No agents found matching your criteria')).toBeInTheDocument();
    });
  });
});
