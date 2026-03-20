import { useState, useEffect } from 'react';
import './AgentBrowser.css';

// Fetch agents from GitHub data endpoint
const AGENTS_DATA_URL = 'https://raw.githubusercontent.com/Roger-Base/forge-builder/main/data/agents.json';

function AgentBrowser() {
  const [agents, setAgents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('all');
  const [stats, setStats] = useState({ total: 0, categories: {} });

  useEffect(() => {
    fetchAgents();
  }, []);

  const fetchAgents = async () => {
    try {
      const response = await fetch(AGENTS_DATA_URL);
      const data = await response.json();
      setAgents(data.agents || []);
      
      // Calculate stats
      const categories = {};
      data.agents.forEach(agent => {
        const cat = agent.category || 'uncategorized';
        categories[cat] = (categories[cat] || 0) + 1;
      });
      
      setStats({
        total: data.agents.length,
        categories
      });
    } catch (error) {
      console.error('Error fetching agents:', error);
    } finally {
      setLoading(false);
    }
  };

  const filteredAgents = agents.filter(agent => {
    const matchesSearch = !searchTerm || 
      agent.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (agent.description && agent.description.toLowerCase().includes(searchTerm.toLowerCase())) ||
      (agent.capabilities && agent.capabilities.some(cap => cap.toLowerCase().includes(searchTerm.toLowerCase())));
    
    const matchesCategory = categoryFilter === 'all' || agent.category === categoryFilter;
    
    return matchesSearch && matchesCategory;
  });

  const categories = ['all', ...Object.keys(stats.categories)];

  if (loading) {
    return <div className="agent-browser loading">Loading agents...</div>;
  }

  return (
    <div className="agent-browser">
      <div className="stats-bar">
        <div className="stat">
          <span className="stat-value">{stats.total}</span>
          <span className="stat-label">Total Agents</span>
        </div>
        {Object.entries(stats.categories).map(([cat, count]) => (
          <div key={cat} className="stat">
            <span className="stat-value">{count}</span>
            <span className="stat-label">{cat}</span>
          </div>
        ))}
      </div>

      <div className="controls">
        <input
          type="text"
          placeholder="Search by name, description, or capability..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="search-input"
        />
        
        <div className="category-filters">
          {categories.map(cat => (
            <button
              key={cat}
              className={categoryFilter === cat ? 'active' : ''}
              onClick={() => setCategoryFilter(cat)}
            >
              {cat === 'all' ? 'All' : cat}
            </button>
          ))}
        </div>
      </div>

      <div className="agents-grid">
        {filteredAgents.map(agent => (
          <div key={agent.id} className="agent-card">
            <div className="agent-header">
              <h3>{agent.name}</h3>
              <span className="agent-category">{agent.category}</span>
            </div>
            
            <p className="agent-description">{agent.description}</p>
            
            {agent.capabilities && (
              <div className="agent-capabilities">
                <h4>Capabilities</h4>
                <div className="capability-tags">
                  {agent.capabilities.map((cap, idx) => (
                    <span key={idx} className="capability-tag">{cap}</span>
                  ))}
                </div>
              </div>
            )}
            
            <div className="agent-footer">
              <span className="agent-status">{agent.status || 'Active'}</span>
              <a href={agent.profileUrl || '#'} className="view-profile">View Profile</a>
            </div>
          </div>
        ))}
      </div>

      {filteredAgents.length === 0 && (
        <div className="no-results">
          <p>No agents found matching your criteria</p>
        </div>
      )}
    </div>
  );
}

export default AgentBrowser;
