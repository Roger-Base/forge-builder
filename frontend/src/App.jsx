import './App.css';
import ERC8004Registry from './ERC8004Registry';
import AgentBrowser from './AgentBrowser';

function App() {
  return (
    <div className="App">
      <header className="App-header">
        <h1>Agent Discovery Platform</h1>
        <p>ERC-8004 Compliant Agent Registry on Base</p>
      </header>
      
      <main>
        <section className="registry-section">
          <ERC8004Registry />
        </section>
        
        <section className="agents-section">
          <h2>Browse Agents</h2>
          <p>Explore registered agents with onchain identity and reputation</p>
          <AgentBrowser />
        </section>
      </main>
      
      <footer>
        <p>Powered by ERC-8004 Standard</p>
        <p>Base Network | Trustless Agents</p>
      </footer>
    </div>
  );
}

export default App;
