"""
supabase_setup.py — Single file for database setup and seeding.

DIRECTIONS:
1. Copy the SQL below into your Supabase SQL Editor.
2. Run this Python script to insert sample schemes.
"""

import os
from dotenv import load_dotenv
from supabase import create_client, Client

load_dotenv()

# --- Configurations ---
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

# --- SQL TO RUN IN SUPABASE DASHBOARD ---
"""
-- Run this in your Supabase SQL Editor:

CREATE TABLE IF NOT EXISTS public.schemes (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    category TEXT,
    ministry TEXT,
    benefit TEXT,
    description TEXT,
    min_age INT,
    max_age INT,
    income_levels JSONB DEFAULT '[]'::jsonb,
    occupations JSONB DEFAULT '[]'::jsonb,
    tags JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Optional: Enable RLS (Row Level Security) or make it public for now
ALTER TABLE public.schemes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public Read" ON public.schemes FOR SELECT USING (true);
"""

def seed_data():
    if not SUPABASE_URL or not SUPABASE_KEY:
        print("Error: Please set SUPABASE_URL and SUPABASE_KEY in .env file.")
        return

    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
    
    sample_schemes = [
        {
            "id": "pm-kisan",
            "name": "PM-Kisan Yojana",
            "category": "Agriculture",
            "min_age": 18,
            "max_age": 70,
            "income_levels": ["below1", "1to2.5"],
            "occupations": ["farmer"],
            "benefit": "₹6,000 per year in 3 installments.",
            "description": "Income support for land-holding farmer families."
        },
        {
            "id": "ayushman",
            "name": "Ayushman Bharat",
            "category": "Health",
            "min_age": 0,
            "max_age": 100,
            "income_levels": ["below1", "1to2.5", "2.5to5"],
            "occupations": ["farmer", "unemployed", "labour"],
            "benefit": "₹5 Lakh health cover per family.",
            "description": "World's largest health insurance scheme."
        },
        {
            "id": "pmsy",
            "name": "PM Scholarship Scheme",
            "category": "Education",
            "min_age": 15,
            "max_age": 30,
            "income_levels": ["below1", "1to2.5", "2.5to5"],
            "occupations": ["student"],
            "benefit": "Financial assistance to meritorious students.",
            "description": "Scholarships for higher education."
        }
    ]

    print(f"Connecting to: {SUPABASE_URL}")
    try:
        for scheme in sample_schemes:
            result = supabase.table("schemes").upsert(scheme).execute()
            print(f"Upserted: {scheme['name']}")
        print("\n✅ Seeding complete!")
    except Exception as e:
        print(f"❌ Error seeding data: {e}")

if __name__ == "__main__":
    seed_data()
