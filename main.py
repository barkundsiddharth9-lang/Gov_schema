"""
main.py — GovSchemes.AI Ultimate Unified Backend (v6.0)
Single-file solution: FastAPI + Supabase + AI Recommender + Data Manager.
"""

import os
import re
import sys
import argparse
import json
import csv
import time
from typing import Optional, List, Dict, Any
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from supabase import create_client, Client

# --- SETUP & CONFIG ---
load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL", "https://your-project.supabase.co")
SUPABASE_KEY = os.getenv("SUPABASE_KEY", "your-service-role-key")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

VERSION = "6.0.0"
THRESHOLD = 50

# --- AI CONSTANTS & ALIASES ---
INCOME_LADDER = ["below1", "1to2.5", "2.5to5", "5to8", "above8"]

OCC_ALIASES = {
    "farmer": ["agriculture", "kisan", "cultivation", "fisherman", "horticulture"],
    "student": ["scholar", "education", "trainee", "apprentice"],
    "self_employed": ["entrepreneur", "business", "msme", "startup", "proprietor"],
    "labour": ["worker", "construction", "unorganised", "migrant", "labourer"],
    "government_employee": ["government", "service", "central_employee"],
    "woman": ["women", "girl", "mahila", "widow", "mother"],
    "differently_abled": ["disabled", "handicapped", "divyang"],
}

# --- DATA INFERENCE UTILS (From legacy import scripts) ---

def infer_income(text: str) -> list:
    t = text.lower()
    res = []
    if any(w in t for w in ['bpl', 'below poverty', '1 lakh', 'income not exceed']):
        res.extend(['below1', '1to2.5'])
    if any(w in t for w in ['3 lakh', '5 lakh', 'middle class']):
        res.extend(['1to2.5', '2.5to5'])
    if not res: res = INCOME_LADDER
    return list(set(res))

def infer_occupations(text: str) -> list:
    t = text.lower()
    res = []
    for key, aliases in OCC_ALIASES.items():
        if key in t or any(a in t for a in aliases):
            res.append(key)
    return res or ["unemployed", "farmer", "student", "labour"]

def infer_age(text: str) -> tuple:
    age_range = re.search(r'(\d{2})\s*(?:to|-|and)\s*(\d{2,3})', text, re.I)
    if age_range: return int(age_range.group(1)), int(age_range.group(2))
    return 0, 100

# --- AI RECOMMENDER LOGIC ---

def score_scheme(scheme: Dict, user: Dict) -> Dict:
    score = 0
    # 1. Age (Weight: 25)
    u_age = user['age']
    s_min = scheme.get('min_age') or 0
    s_max = scheme.get('max_age') or 100
    if s_min <= u_age <= s_max: score += 25
    elif abs(s_min - u_age) <= 3: score += 10
    else: score -= 25

    # 2. Income (Weight: 25)
    u_inc = user['income']
    s_incs = scheme.get('income_levels') or []
    if not s_incs or u_inc in s_incs: score += 25
    else: score -= 25

    # 3. Occupation (Weight: 25)
    u_occ = user['occupation'].lower()
    s_occs = [str(o).lower() for o in (scheme.get('occupations') or [])]
    if not s_occs or u_occ in s_occs: score += 25
    else:
        # Check aliases
        matched_alias = False
        for alias in OCC_ALIASES.get(u_occ, []):
            if any(alias in s for s in s_occs):
                score += 15
                matched_alias = True
                break
        if not matched_alias: score -= 20

    # 4. State/Level (Weight: 25)
    lvl = (scheme.get("ministry") or "").lower()
    if any(k in lvl for k in ("central", "national", "india")):
        score += 25
    elif user.get("state") and user["state"].lower() in lvl:
        score += 20
    
    final_score = max(0, min(100, score))
    return {
        "final_score": final_score,
        "confidence": "High" if final_score >= 85 else "Medium" if final_score >= 70 else "Low"
    }

# --- FASTAPI APP ---
app = FastAPI(title="GovSchemes AI Unified API")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

class RecommendRequest(BaseModel):
    age: int; income: str; occupation: str; gender: str
    state: Optional[str] = None; top_n: Optional[int] = 10

@app.get("/")
def root(): return {"api": "GovSchemes AI", "version": VERSION, "status": "running"}

@app.post("/recommend")
def recommend(req: RecommendRequest):
    res = supabase.table("schemes").select("*").execute()
    schemes = res.data or []
    
    scored = []
    user = req.dict()
    for s in schemes:
        sc_res = score_scheme(s, user)
        if sc_res["final_score"] >= THRESHOLD:
            scored.append({**sc_res, "id": s['id'], "name": s['name'], "benefit": s.get('benefit')})
    
    scored.sort(key=lambda x: x["final_score"], reverse=True)
    return {"results": scored[:req.top_n]}

@app.post("/search")
def search(query: str = Query(...)):
    res = supabase.table("schemes").select("*").ilike("name", f"%{query}%").execute()
    return {"results": res.data or []}

# --- CLI DATA MANAGEMENT ---

def seed_db():
    print("Seeding sample data...")
    samples = [
        {"id": "pm-kisan", "name": "PM-Kisan", "min_age": 18, "max_age": 75, "occupations": ["farmer"], "income_levels": ["below1", "1to2.5"], "benefit": "₹6,000/year"},
        {"id": "ayushman", "name": "Ayushman Bharat", "min_age": 0, "max_age": 100, "occupations": ["farmer", "labour", "unemployed"], "income_levels": ["below1", "1to2.5"], "benefit": "₹5 Lakh health cover"},
        {"id": "post-matric", "name": "Post-Matric Scholarship", "min_age": 15, "max_age": 30, "occupations": ["student"], "income_levels": ["below1", "1to2.5", "2.5to5"], "benefit": "Tuition fee waiver & stipend"},
        {"id": "pm-svanidhi", "name": "PM SVANidhi", "min_age": 18, "max_age": 60, "occupations": ["self_employed", "labour"], "income_levels": ["below1", "1to2.5"], "benefit": "₹10,000 working capital loan"}
    ]
    supabase.table("schemes").upsert(samples).execute()
    print("✅ Seeded successfully!")

def import_csv(path: str):
    print(f"Importing from {path}...")
    with open(path, newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        batch = []
        for row in reader:
            name = row.get('scheme_name')
            if not name: continue
            elig = row.get('eligibility', '')
            min_a, max_a = infer_age(elig)
            scheme = {
                "id": row.get('slug') or re.sub(r'[^a-z0-9]', '-', name.lower())[:50],
                "name": name,
                "category": row.get('schemeCategory', 'General'),
                "benefit": row.get('benefits', ''),
                "description": row.get('details', ''),
                "min_age": min_a, "max_age": max_a,
                "income_levels": infer_income(elig),
                "occupations": infer_occupations(elig + " " + row.get('schemeCategory', '')),
                "ministry": row.get('level', 'Central')
            }
            batch.append(scheme)
            if len(batch) >= 20:
                supabase.table("schemes").upsert(batch).execute()
                batch = []
        if batch: supabase.table("schemes").upsert(batch).execute()
    print("✅ CSV Import complete!")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--seed", action="store_true")
    parser.add_argument("--import-csv", type=str)
    parser.add_argument("--serve", action="store_true", default=True)
    args = parser.parse_args()

    if args.seed: seed_db()
    elif args.import_csv: import_csv(args.import_csv)
    else:
        import uvicorn
        uvicorn.run(app, host="0.0.0.0", port=8000)
