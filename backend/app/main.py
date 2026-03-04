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
