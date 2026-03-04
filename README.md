# 🎯 Powerball Pro - Professional Lottery Analysis Platform

A production-grade web application for Powerball number analysis and generation using advanced pattern matching and AI.

![Version](https://img.shields.io/badge/version-2.0.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Python](https://img.shields.io/badge/python-3.11-blue)
![React](https://img.shields.io/badge/react-18.2-blue)

## 🌟 Features

- **Live Draw Results** - Real-time latest winning numbers
- **Smart Number Generation** - 6 different AI/pattern-based models
- **Ticket Checker** - Verify your numbers against recent draws
- **Advanced Analytics** - Frequency analysis, pattern matching, range distributions
- **AI Chatbot** - Natural language number generation (Claude/GPT)
- **State Buy Links** - Direct links to official lottery websites
- **Mobile Responsive** - Perfect on any device
- **Fast & Scalable** - Built with FastAPI and React

## 🏗️ Architecture
```
┌─────────────┐      ┌─────────────┐      ┌──────────────┐
│   React     │─────▶│   FastAPI   │─────▶│  NY Lottery  │
│   Frontend  │      │   Backend   │      │     API      │
└─────────────┘      └─────────────┘      └──────────────┘
                            │
                            ▼
                     ┌─────────────┐
                     │   Redis     │
                     │   Cache     │
                     └─────────────┘
```

## 🚀 Quick Start

### Prerequisites

- Python 3.11+
- Node.js 18+
- npm or yarn

### Backend Setup
```bash
cd backend
pip install -r requirements.txt
python app/main.py
```

Backend runs at: `http://localhost:8000`

### Frontend Setup
```bash
cd frontend
npm install
npm start
```

Frontend runs at: `http://localhost:3000`

## 📦 Deployment

### Deploy to Vercel (Frontend)
```bash
cd frontend
vercel --prod
```

### Deploy to Railway (Backend)
```bash
cd backend
railway up
```

### Deploy to Heroku (Backend)
```bash
heroku create powerball-pro-api
git push heroku main
```

### Deploy to AWS/Google Cloud

See [deployment/README.md](deployment/README.md) for cloud deployment guides.

## 🔑 Environment Variables

### Backend (.env)
```env
ANTHROPIC_API_KEY=your_claude_key
OPENAI_API_KEY=your_openai_key  # Optional
REDIS_URL=redis://localhost:6379
ENVIRONMENT=production
```

### Frontend (.env)
```env
REACT_APP_API_URL=http://localhost:8000
REACT_APP_GA_ID=your_google_analytics_id
```

## 📊 API Documentation

Once backend is running, visit:
- Swagger UI: `http://localhost:8000/api/docs`
- ReDoc: `http://localhost:8000/api/redoc`

### Key Endpoints
```
GET  /api/draws/latest          # Latest winning numbers
GET  /api/analysis/frequency    # Number frequency data
POST /api/generate               # Generate numbers
POST /api/check-ticket           # Check ticket
POST /api/chatbot                # AI chatbot
```

## 🎨 Tech Stack

### Frontend
- React 18
- TypeScript
- Tailwind CSS
- Axios
- React Query
- Framer Motion

### Backend
- FastAPI
- Python 3.11
- Pandas/NumPy
- Redis (caching)
- Anthropic Claude API
- SQLAlchemy (optional)

## 📈 Performance

- **Backend Response Time**: <50ms average
- **Frontend Load Time**: <1.5s
- **Lighthouse Score**: 95+
- **Mobile Optimized**: 100%

## 🔒 Security

- Rate limiting on all endpoints
- CORS configured
- Input validation
- API key encryption
- HTTPS enforced in production

## 💰 Monetization Options

- **Free Tier**: 5 generations/day
- **Pro ($9.99/mo)**: Unlimited, all models
- **Premium ($29.99/mo)**: API access, priority support

Stripe integration ready in `backend/app/payments.py`

## 📱 Mobile App

React Native version coming soon!

## 🤝 Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md)

## 📄 License

MIT License - see [LICENSE](LICENSE)

## ⚠️ Disclaimer

This is an educational tool for pattern analysis. Lottery draws are random. Past patterns do not predict future results. Play responsibly.

## 👨‍💻 Author

**Raj Kumar Konka**
- Portfolio: [rajkonka.github.io](https://rajkonka.github.io/Profile-Application/)
- LinkedIn: [linkedin.com/in/rajkumark1](https://www.linkedin.com/in/rajkumark1/)
- Email: konkarajkumar74@gmail.com

## 🌟 Star History

[![Star History Chart](https://api.star-history.com/svg?repos=RajKonka/powerball-pro&type=Date)](https://star-history.com/#RajKonka/powerball-pro&Date)

---

**Built with ❤️ for lottery enthusiasts**
