import React, { useState, useEffect } from 'react';
import './App.css';

const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000';

function App() {
  const [draws, setDraws] = useState([]);
  const [frequency, setFrequency] = useState({ hot: {}, cold: {} });
  const [generated, setGenerated] = useState([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    fetch(`${API_URL}/api/draws/latest?count=10`)
      .then(r => r.json())
      .then(data => setDraws(data.draws));
    
    fetch(`${API_URL}/api/analysis/frequency?lookback=500`)
      .then(r => r.json())
      .then(data => setFrequency(data));
  }, []);

  const generateNumbers = async () => {
    setLoading(true);
    const res = await fetch(`${API_URL}/api/generate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ model: 'smart', count: 5 })
    });
    const data = await res.json();
    setGenerated(data.numbers);
    setLoading(false);
  };

  return (
    <div className="App">
      <header className="header">
        <h1>🎯 Powerball Pro</h1>
        <p>Professional Lottery Analysis Platform</p>
      </header>

      <main className="container">
        <section className="section">
          <h2>🏆 Latest Draws</h2>
          <div className="draws-grid">
            {draws.slice(0, 5).map((draw, i) => (
              <div key={i} className="draw-card">
                <div className="date">{draw.date}</div>
                <div className="numbers">
                  {draw.whites.map((n, j) => (
                    <span key={j} className="ball white">{n}</span>
                  ))}
                  <span className="ball powerball">{draw.powerball}</span>
                </div>
              </div>
            ))}
          </div>
        </section>

        <section className="section">
          <h2>🎲 Generate Numbers</h2>
          <button onClick={generateNumbers} disabled={loading} className="generate-btn">
            {loading ? 'Generating...' : '✨ Generate Smart Numbers'}
          </button>
          
          {generated.length > 0 && (
            <div className="generated-grid">
              {generated.map((set, i) => (
                <div key={i} className="number-set">
                  {set.whites.map((n, j) => (
                    <span key={j} className="ball white">{n}</span>
                  ))}
                  <span className="ball powerball">{set.powerball}</span>
                </div>
              ))}
            </div>
          )}
        </section>

        <section className="section">
          <h2>📊 Hot & Cold Numbers</h2>
          <div className="freq-grid">
            <div className="freq-box">
              <h3>🔥 Hot Numbers</h3>
              <div className="freq-numbers">
                {Object.keys(frequency.hot).slice(0, 10).map(n => (
                  <span key={n} className="freq-num hot">{n}</span>
                ))}
              </div>
            </div>
            <div className="freq-box">
              <h3>❄️ Cold Numbers</h3>
              <div className="freq-numbers">
                {Object.keys(frequency.cold).slice(0, 10).map(n => (
                  <span key={n} className="freq-num cold">{n}</span>
                ))}
              </div>
            </div>
          </div>
        </section>
      </main>

      <footer className="footer">
        <p>⚠️ Educational tool only. Lottery is random. Play responsibly.</p>
        <p>Built by Raj Kumar Konka | <a href="https://github.com/RajKonka">GitHub</a></p>
      </footer>
    </div>
  );
}

export default App;
