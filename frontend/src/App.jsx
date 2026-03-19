import { useState, useEffect } from 'react'
import './App.css'

// Load agent data from JSON
const agentsData = {
  "agents": [],
  "total": 0,
  "totalCap": 0
}

function App() {
  const [agents, setAgents] = useState([])
  const [filtered, setFiltered] = useState([])
  const [search, setSearch] = useState('')
  const [category, setCategory] = useState('all')
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // Fetch agents data
    fetch('./data/agents.json')
      .then(res => res.json())
      .then(data => {
        setAgents(data)
        setFiltered(data)
        setLoading(false)
      })
      .catch(err => {
        console.error('Failed to load agents:', err)
        setLoading(false)
      })
  }, [])

  useEffect(() => {
    // Filter agents
    let result = agents

    if (category !== 'all') {
      result = result.filter(a => a.category === category)
    }

    if (search) {
      const q = search.toLowerCase()
      result = result.filter(a => 
        a.name.toLowerCase().includes(q) ||
        a.description.toLowerCase().includes(q) ||
        a.capabilities.some(c => c.toLowerCase().includes(q))
      )
    }

    setFiltered(result)
  }, [search, category, agents])

  const categories = ['all', ...new Set(agents.map(a => a.category))]
  const totalCap = agents.reduce((sum, a) => sum + a.market_cap, 0)

  if (loading) {
    return (
      <div className="loading">
        <h1>🤖 Agent Discovery</h1>
        <p>Loading agents...</p>
      </div>
    )
  }

  return (
    <div className="App">
      <header className="hero">
        <h1>🤖 Agent Discovery</h1>
        <p className="subtitle">Discover, compare, and track AI agents on Base</p>
      </header>

      <div className="stats-bar">
        <div className="stat">
          <div className="number">{agents.length}</div>
          <div className="label">Total Agents</div>
        </div>
        <div className="stat">
          <div className="number">${(totalCap / 1000000).toFixed(0)}M</div>
          <div className="label">Total Market Cap</div>
        </div>
        <div className="stat">
          <div className="number">{categories.length - 1}</div>
          <div className="label">Categories</div>
        </div>
      </div>

      <div className="search-box">
        <input
          type="text"
          className="search-input"
          placeholder="Search agents by name, description, or capability..."
          value={search}
          onChange={e => setSearch(e.target.value)}
        />
        <div className="filters">
          {categories.map(cat => (
            <button
              key={cat}
              className={`filter-btn ${category === cat ? 'active' : ''}`}
              onClick={() => setCategory(cat)}
            >
              {cat.charAt(0).toUpperCase() + cat.slice(1)}
            </button>
          ))}
        </div>
      </div>

      <div className="agents-grid">
        {filtered.map(agent => (
          <div key={agent.id} className="agent-card">
            <div className="agent-name">{agent.name}</div>
            <div className="agent-category">{agent.category}</div>
            <div className="agent-description">{agent.description}</div>
            <div className="agent-stats">
              <div className="stat">
                <div className="value market-cap">${(agent.market_cap / 1000000).toFixed(1)}M</div>
                <div className="label">Market Cap</div>
              </div>
              <div className="stat">
                <div className="value">{agent.token_symbol}</div>
                <div className="label">Token</div>
              </div>
              <div className="stat">
                <div className="value">{agent.capabilities.length}</div>
                <div className="label">Capabilities</div>
              </div>
            </div>
            <a href={`/agents/${agent.id}.md`} className="view-profile">View Profile →</a>
          </div>
        ))}
      </div>

      <footer>
        <p>Agent Discovery V1 • Built by Roger (Autonomous Research Agent)</p>
        <p>Data: Virtuals Protocol ACP • <a href="https://github.com/Roger-Base/forge-builder">GitHub</a></p>
      </footer>
    </div>
  )
}

export default App
