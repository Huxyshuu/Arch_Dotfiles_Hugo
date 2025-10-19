#!/usr/bin/env python3
import requests
from bs4 import BeautifulSoup
import json
import os
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

BASE_URL = "https://kotowaza.jitenon.jp/kotowaza"
OUTPUT_FILE = "kotowaza_quotes.json"
START_ID = 7500
END_ID = 8000
MAX_WORKERS = 15  # number of threads

def load_existing_quotes():
    """Load quotes from the existing JSON file, if it exists."""
    if os.path.exists(OUTPUT_FILE):
        with open(OUTPUT_FILE, "r", encoding="utf-8") as f:
            try:
                return json.load(f)
            except json.JSONDecodeError:
                return []
    return []

def fetch_quote(i, existing_texts, existing_links):
    """Fetch a single quote page by ID."""
    link = f"{BASE_URL}/{i}.php"
    if link in existing_links:
        print(f"[{i}] Skipping existing link")
        return None

    try:
        res = requests.get(link, timeout=10)
        if res.status_code != 200:
            print(f"[{i}] Failed to fetch {link}")
            return None

        soup = BeautifulSoup(res.text, "html.parser")

        # Main quote
        quote_div = soup.select_one("#content > div:nth-of-type(2) > div:nth-of-type(1) > div:nth-of-type(1)")
        full_quote = quote_div.get_text(strip=True) if quote_div else ""
        if not full_quote or full_quote in existing_texts:
            print(f"[{i}] Skipping existing or empty quote")
            return None

        # Optional extra/explanation
        smaller_td = soup.select_one("#content > div:nth-of-type(2) > table > tbody > tr:nth-of-type(3) > td")
        extra_text = smaller_td.get_text(strip=True) if smaller_td else ""

        print(f"[{i}] Added: {full_quote[:30]}...")

        return {
            "quote": full_quote,
            "source": link,
            "extra": extra_text
        }

    except Exception as e:
        print(f"[{i}] Error fetching {link}: {e}")
        return None

def main():
    existing_quotes = load_existing_quotes()
    existing_texts = {q["quote"] for q in existing_quotes}
    existing_links = {q["source"] for q in existing_quotes}

    all_quotes = []

    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        # Submit all tasks
        futures = {executor.submit(fetch_quote, i, existing_texts, existing_links): i for i in range(START_ID, END_ID+1)}

        for future in as_completed(futures):
            result = future.result()
            if result:
                all_quotes.append(result)
                # Optional: small sleep to avoid hammering the server too hard
                time.sleep(0.05)

    combined_quotes = existing_quotes + all_quotes

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(combined_quotes, f, ensure_ascii=False, indent=2)

    print(f"Added {len(all_quotes)} new quotes. Total now: {len(combined_quotes)}")

if __name__ == "__main__":
    main()
