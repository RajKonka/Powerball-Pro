#!/bin/bash

echo "🚀 Building Powerball Pro Production Repository..."

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Create structure
echo -e "${BLUE}Creating folder structure...${NC}"
mkdir -p frontend/{public,src/{components/{common,layout,features},pages,services,hooks,styles,utils,types}}
mkdir -p backend/app/{api,core,models,services}
mkdir -p deployment/{docker,kubernetes,terraform}
mkdir -p .github/workflows
mkdir -p docs

# ============================================================
# BACKEND FILES
# ============================================================

echo -e "${BLUE}Creating backend files...${NC}"

# Backend requirements.txt
cat > backend/requirements.txt << 'EOF'
fastapi==0.109.0
uvicorn[standard]==0.27.0
pydantic==2.5.3
python-dotenv==1.0.0
requests==2.31.0
pandas==2.1.4
numpy==1.26.3
anthropic==0.18.1
redis==5.0.1
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
slowapi==0.1.9
python-multipart==0.0.6
aiofiles==23.2.1
EOF

# Backend main.py (Complete FastAPI app)
cat > backend/app/main.py << 'EOFMAIN'
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import random
import numpy as np
import pandas as pd
import requests
from datetime import datetime, timedelta
import os

app = FastAPI(
    title="Powerball Pro API",
    description="Professional Powerball Analysis API",
    version="2.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

LOTTERY_API = "https://data.ny.gov/resource/d6yy-54nr.json?$limit=5000"
CACHE = {"data": None, "time": None}

class GenerateRequest(BaseModel):
    model: str = "smart"
    count: int = 5
    lookback: int = 500

class CheckRequest(BaseModel):
    whites: List[int]
    powerball: int
    check_draws: int = 20

def load_data():
    global CACHE
    if CACHE["data"] and CACHE["time"]:
        if (datetime.now() - CACHE["time"]).seconds < 3600:
            return CACHE["data"]
    
    resp = requests.get(LOTTERY_API, timeout=15)
    raw = resp.json()
    df = pd.DataFrame(raw)
    df["draw_date"] = pd.to_datetime(df["draw_date"])
    nums = df["winning_numbers"].str.split(" ", expand=True).iloc[:, :6].astype(int)
    nums.columns = ["w1", "w2", "w3", "w4", "w5", "pb"]
    df = pd.concat([df[["draw_date"]], nums], axis=1)
    df = df.sort_values("draw_date", ascending=False).reset_index(drop=True)
    
    CACHE["data"] = df
    CACHE["time"] = datetime.now()
    return df

@app.get("/")
def root():
    return {"app": "Powerball Pro API", "version": "2.0.0", "status": "online"}

@app.get("/api/draws/latest")
def latest_draws(count: int = 10):
    df = load_data()
    draws = []
    for i in range(min(count, len(df))):
        row = df.iloc[i]
        draws.append({
            "date": row.draw_date.strftime("%Y-%m-%d"),
            "whites": [int(row.w1), int(row.w2), int(row.w3), int(row.w4), int(row.w5)],
            "powerball": int(row.pb)
        })
    return {"draws": draws}

@app.get("/api/analysis/frequency")
def frequency(lookback: int = 500):
    df = load_data().head(lookback)
    freq = pd.concat([df.w1, df.w2, df.w3, df.w4, df.w5]).value_counts()
    return {
        "hot": freq.nlargest(15).to_dict(),
        "cold": freq.nsmallest(15).to_dict()
    }

@app.post("/api/generate")
def generate(req: GenerateRequest):
    df = load_data().head(req.lookback)
    results = []
    
    for _ in range(req.count):
        if req.model == "smart":
            sums = df[["w1", "w2", "w3", "w4", "w5"]].sum(axis=1)
            target = sums.median()
            for attempt in range(500):
                w = sorted(random.sample(range(1, 70), 5))
                if abs(sum(w) - target) < 25:
                    break
        else:
            w = sorted(random.sample(range(1, 70), 5))
        
        results.append({"whites": w, "powerball": random.randint(1, 26)})
    
    return {"numbers": results, "model": req.model}

@app.post("/api/check-ticket")
def check(req: CheckRequest):
    df = load_data().head(req.check_draws)
    matches = []
    my_w = set(req.whites)
    
    for i in range(len(df)):
        row = df.iloc[i]
        win_w = set([int(row.w1), int(row.w2), int(row.w3), int(row.w4), int(row.w5)])
        match_count = len(my_w & win_w)
        pb_match = req.powerball == int(row.pb)
        
        if match_count >= 3:
            matches.append({
                "date": row.draw_date.strftime("%Y-%m-%d"),
                "white_matches": match_count,
                "pb_match": pb_match
            })
    
    return {"matches": matches}

@app.get("/health")
def health():
    return {"status": "healthy"}
EOFMAIN

# Backend Dockerfile
cat > backend/Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ ./app/

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

# ============================================================
# FRONTEND FILES
# ============================================================

echo -e "${BLUE}Creating frontend files...${NC}"

# package.json
cat > frontend/package.json << 'EOF'
{
  "name": "powerball-pro-frontend",
  "version": "2.0.0",
  "private": true,
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.21.1",
    "axios": "^1.6.5",
    "react-query": "^3.39.3",
    "framer-motion": "^10.18.0",
    "recharts": "^2.10.4"
  },
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test",
    "eject": "react-scripts eject"
  },
  "devDependencies": {
    "react-scripts": "5.0.1",
    "@types/react": "^18.2.0",
    "@types/react-dom": "^18.2.0"
  },
  "browserslist": {
    "production": [">0.2%", "not dead", "not op_mini all"],
    "development": ["last 1 chrome version", "last 1 firefox version", "last 1 safari version"]
  }
}
EOF

# Frontend index.html
cat > frontend/public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <meta name="theme-color" content="#667eea" />
  <meta name="description" content="Professional Powerball number analysis and generation" />
  <title>Powerball Pro - Smart Lottery Analysis</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen', 'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue', sans-serif;
      -webkit-font-smoothing: antialiased;
      -moz-osx-font-smoothing: grayscale;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      min-height: 100vh;
    }
  </style>
</head>
<body>
  <noscript>You need to enable JavaScript to run this app.</noscript>
  <div id="root"></div>
</body>
</html>
EOF

# Frontend App.js
cat > frontend/src/App.js << 'EOF'
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
EOF

# Frontend CSS
cat > frontend/src/App.css << 'EOF'
.App {
  min-height: 100vh;
  color: white;
}

.header {
  text-align: center;
  padding: 3rem 1rem;
  background: rgba(0,0,0,0.2);
}

.header h1 {
  font-size: 3rem;
  margin-bottom: 0.5rem;
  text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem 1rem;
}

.section {
  background: rgba(255,255,255,0.1);
  backdrop-filter: blur(10px);
  border-radius: 20px;
  padding: 2rem;
  margin-bottom: 2rem;
}

.section h2 {
  margin-bottom: 1.5rem;
  font-size: 1.8rem;
}

.draws-grid {
  display: grid;
  gap: 1rem;
}

.draw-card {
  background: rgba(255,255,255,0.1);
  padding: 1.5rem;
  border-radius: 15px;
}

.date {
  font-size: 0.9rem;
  opacity: 0.8;
  margin-bottom: 1rem;
}

.numbers {
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
}

.ball {
  width: 50px;
  height: 50px;
  border-radius: 50%;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-weight: bold;
  font-size: 1.2rem;
}

.ball.white {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.ball.powerball {
  background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
}

.generate-btn {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  padding: 1rem 2rem;
  font-size: 1.2rem;
  border-radius: 50px;
  cursor: pointer;
  font-weight: 600;
  transition: transform 0.2s;
  width: 100%;
  max-width: 400px;
  margin: 0 auto;
  display: block;
}

.generate-btn:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 10px 30px rgba(102, 126, 234, 0.4);
}

.generate-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.generated-grid {
  margin-top: 2rem;
  display: grid;
  gap: 1rem;
}

.number-set {
  background: rgba(255,255,255,0.1);
  padding: 1.5rem;
  border-radius: 15px;
  display: flex;
  gap: 0.5rem;
  justify-content: center;
  flex-wrap: wrap;
}

.freq-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 2rem;
}

.freq-box h3 {
  margin-bottom: 1rem;
  font-size: 1.3rem;
}

.freq-numbers {
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
}

.freq-num {
  padding: 0.5rem 1rem;
  border-radius: 25px;
  font-weight: 600;
}

.freq-num.hot {
  background: rgba(255, 107, 107, 0.3);
  border: 2px solid rgba(255, 107, 107, 0.6);
}

.freq-num.cold {
  background: rgba(78, 205, 196, 0.3);
  border: 2px solid rgba(78, 205, 196, 0.6);
}

.footer {
  text-align: center;
  padding: 2rem;
  opacity: 0.8;
  font-size: 0.9rem;
}

.footer a {
  color: white;
  text-decoration: underline;
}

@media (max-width: 768px) {
  .header h1 { font-size: 2rem; }
  .section { padding: 1.5rem; }
  .ball { width: 40px; height: 40px; font-size: 1rem; }
}
EOF

# Frontend index.js
cat > frontend/src/index.js << 'EOF'
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
EOF

# ============================================================
# DEPLOYMENT FILES
# ============================================================

echo -e "${BLUE}Creating deployment files...${NC}"

# Docker Compose
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  backend:
    build: ./backend
    ports:
      - "8000:8000"
    environment:
      - ENVIRONMENT=production
    restart: always

  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    environment:
      - REACT_APP_API_URL=http://backend:8000
    depends_on:
      - backend
    restart: always
EOF

# Frontend Dockerfile
cat > frontend/Dockerfile << 'EOF'
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

CMD ["npm", "start"]
EOF

# Vercel config for frontend
cat > frontend/vercel.json << 'EOF'
{
  "buildCommand": "npm run build",
  "outputDirectory": "build",
  "framework": "create-react-app",
  "rewrites": [
    { "source": "/(.*)", "destination": "/index.html" }
  ]
}
EOF

# Railway config for backend
cat > backend/railway.json << 'EOF'
{
  "build": {
    "builder": "NIXPACKS"
  },
  "deploy": {
    "startCommand": "uvicorn app.main:app --host 0.0.0.0 --port $PORT",
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
EOF

# GitHub Actions CI/CD
cat > .github/workflows/deploy.yml << 'EOF'
name: Deploy

on:
  push:
    branches: [ main ]

jobs:
  deploy-backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Deploy to Railway
        run: echo "Deploy backend"
  
  deploy-frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Deploy to Vercel
        run: echo "Deploy frontend"
EOF

# Main .env.example
cat > .env.example << 'EOF'
# Backend
ANTHROPIC_API_KEY=sk-ant-your-key-here
OPENAI_API_KEY=sk-your-key-here
ENVIRONMENT=production

# Frontend
REACT_APP_API_URL=https://your-backend.railway.app
REACT_APP_GA_ID=G-XXXXXXXXXX
EOF

echo -e "${GREEN}✅ Project structure created!${NC}"
echo ""
echo "📁 Structure:"
echo "  frontend/    - React app"
echo "  backend/     - FastAPI server"
echo "  deployment/  - Docker configs"
echo ""
echo "🚀 Next steps:"
echo "  1. cd backend && pip install -r requirements.txt && python app/main.py"
echo "  2. cd frontend && npm install && npm start"
echo "  3. git add . && git commit -m 'Initial commit'"
echo "  4. Create repo on GitHub"
echo "  5. git remote add origin <your-repo-url>"
echo "  6. git push -u origin main"
echo ""
echo -e "${GREEN}Done! 🎉${NC}"
