import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import '@testing-library/jest-dom';
import DeFAIDashboard from '../src/DeFAIDashboard';

describe('DeFAIDashboard Component', () => {
  const mockYieldData = [
    { protocol: 'aave', chain: 'base', name: 'USDC', apy: 4.23, tvl: 45670000, risk: 15 },
    { protocol: 'aave', chain: 'ethereum', name: 'USDC', apy: 3.45, tvl: 89230000, risk: 15 },
    { protocol: 'compound', chain: 'ethereum', name: 'USDC', apy: 3.45, tvl: 89000000, risk: 15 },
    { protocol: 'curve', chain: 'ethereum', name: '3pool', apy: 5.67, tvl: 156780000, risk: 20 },
    { protocol: 'yearn', chain: 'ethereum', name: 'yvUSDC', apy: 6.12, tvl: 67890000, risk: 25 },
    { protocol: 'uniswap', chain: 'arbitrum', name: 'WETH/USDC 0.05%', apy: 12.34, tvl: 12000000, risk: 35 }
  ];

  beforeEach(() => {
    render(<DeFAIDashboard />);
  });

  test('renders dashboard header', async () => {
    await waitFor(() => {
      expect(screen.getByText('DeFAI Yield Dashboard')).toBeInTheDocument();
      expect(screen.getByText('Autonomous DeFi yield optimization across protocols')).toBeInTheDocument();
    });
  });

  test('renders protocol filter dropdown', async () => {
    await waitFor(() => {
      const protocolSelect = screen.getByLabelText('Protocol:');
      expect(protocolSelect).toBeInTheDocument();
      expect(protocolSelect.children.length).toBeGreaterThan(1);
    });
  });

  test('renders chain filter dropdown', async () => {
    await waitFor(() => {
      const chainSelect = screen.getByLabelText('Chain:');
      expect(chainSelect).toBeInTheDocument();
    });
  });

  test('renders sort dropdown', async () => {
    await waitFor(() => {
      const sortSelect = screen.getByLabelText('Sort by:');
      expect(sortSelect).toBeInTheDocument();
      expect(screen.getByText('Highest APY')).toBeInTheDocument();
    });
  });

  test('displays yield table with data', async () => {
    await waitFor(() => {
      expect(screen.getByText('Protocol')).toBeInTheDocument();
      expect(screen.getByText('Chain')).toBeInTheDocument();
      expect(screen.getByText('Pool/Asset')).toBeInTheDocument();
      expect(screen.getByText('APY')).toBeInTheDocument();
      expect(screen.getByText('TVL')).toBeInTheDocument();
      expect(screen.getByText('Risk')).toBeInTheDocument();
    });
  });

  test('filters by protocol', async () => {
    await waitFor(() => {
      const protocolSelect = screen.getByLabelText('Protocol:');
      fireEvent.change(protocolSelect, { target: { value: 'aave' } });
    });
    
    await waitFor(() => {
      expect(screen.getByText('AAVE')).toBeInTheDocument();
    });
  });

  test('filters by chain', async () => {
    await waitFor(() => {
      const chainSelect = screen.getByLabelText('Chain:');
      fireEvent.change(chainSelect, { target: { value: 'ethereum' } });
    });
    
    await waitFor(() => {
      expect(screen.getByText('Ethereum')).toBeInTheDocument();
    });
  });

  test('sorts by APY (highest first)', async () => {
    await waitFor(() => {
      const sortSelect = screen.getByLabelText('Sort by:');
      fireEvent.change(sortSelect, { target: { value: 'apy' } });
    });
    
    // First row should be highest APY (12.34% - Uniswap Arbitrum)
    await waitFor(() => {
      expect(screen.getByText('12.34%')).toBeInTheDocument();
    });
  });

  test('sorts by TVL (highest first)', async () => {
    await waitFor(() => {
      const sortSelect = screen.getByLabelText('Sort by:');
      fireEvent.change(sortSelect, { target: { value: 'tvl' } });
    });
    
    // First row should be highest TVL (156.78M - Curve 3pool)
    await waitFor(() => {
      expect(screen.getByText('$156.78M')).toBeInTheDocument();
    });
  });

  test('sorts by risk (lowest first)', async () => {
    await waitFor(() => {
      const sortSelect = screen.getByLabelText('Sort by:');
      fireEvent.change(sortSelect, { target: { value: 'risk' } });
    });
    
    // First row should be lowest risk (15/100 - Aave)
    await waitFor(() => {
      expect(screen.getByText('15/100')).toBeInTheDocument();
    });
  });

  test('displays risk badges with correct colors', async () => {
    await waitFor(() => {
      const riskBadges = screen.getAllByText(/\/100/);
      expect(riskBadges.length).toBeGreaterThan(0);
      
      // Low risk (green)
      expect(screen.getByText('15/100 (Low)')).toBeInTheDocument();
      
      // Medium risk (orange)
      expect(screen.getByText('25/100 (Medium)')).toBeInTheDocument();
      
      // High risk (red)
      expect(screen.getByText('35/100 (High)')).toBeInTheDocument();
    });
  });

  test('displays APY with percentage format', async () => {
    await waitFor(() => {
      expect(screen.getByText('4.23%')).toBeInTheDocument();
      expect(screen.getByText('5.67%')).toBeInTheDocument();
      expect(screen.getByText('12.34%')).toBeInTheDocument();
    });
  });

  test('displays TVL in millions format', async () => {
    await waitFor(() => {
      expect(screen.getByText('$45.67M')).toBeInTheDocument();
      expect(screen.getByText('$156.78M')).toBeInTheDocument();
    });
  });

  test('shows no results when filter matches nothing', async () => {
    await waitFor(() => {
      const protocolSelect = screen.getByLabelText('Protocol:');
      fireEvent.change(protocolSelect, { target: { value: 'nonexistent' } });
    });
    
    await waitFor(() => {
      expect(screen.getByText('No yield opportunities found for selected filters')).toBeInTheDocument();
    });
  });

  test('displays deployment phases in footer', async () => {
    await waitFor(() => {
      expect(screen.getByText('Phase 1: Yield Scanner CLI | Phase 1.5: ERC-8004 Integration | Phase 2: Autonomous Rebalancing')).toBeInTheDocument();
    });
  });
});
