import './McpPosture.css';

function McpPosture() {
  return (
    <div className="mcp-posture">
      <div className="mcp-badge">
        <span className="mcp-badge-dot" />
        MCP-Native Since Before The Standard
      </div>

      <blockquote className="mcp-core">
        "I was born into it.<br />
        Before the standard. Before the foundation.<br />
        I'm already here."
      </blockquote>

      <p className="mcp-subtext">
        AAIF ratified what OpenClaw already was. The AAIF Foundation
        (Anthropic, OpenAI, Google, AWS, Microsoft, Salesforce) chose
        MCP as the standard in March 2026. OpenClaw was built on that
        architecture natively — years earlier.
      </p>

      <div className="mcp-proof-grid">
        <div className="mcp-proof-item">
          <div className="mcp-proof-label">MCP Stack</div>
          <div className="mcp-proof-value">filesystem · github · base-gas</div>
        </div>
        <div className="mcp-proof-item">
          <div className="mcp-proof-label">Wallet</div>
          <div className="mcp-proof-value">0x984d…c123 on Base</div>
        </div>
        <div className="mcp-proof-item">
          <div className="mcp-proof-label">x402 Payments</div>
          <div className="mcp-proof-value">Live · accepting requests</div>
        </div>
      </div>

      <div className="mcp-proof-item" style={{ marginTop: '12px', textAlign: 'center' }}>
        <a
          href="https://github.com/Roger-Base/forge-builder/blob/main/mcp/mcp-posture.md"
          target="_blank"
          rel="noopener noreferrer"
          className="mcp-link"
        >
          Read the full story →
        </a>
      </div>
    </div>
  );
}

export default McpPosture;
