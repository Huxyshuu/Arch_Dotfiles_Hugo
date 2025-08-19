#!/usr/bin/env python3
import requests
from bs4 import BeautifulSoup
import json
import time
import os

BASE_URL = "https://kotowaza.jitenon.jp"
OUTPUT_FILE = "kotowaza_quotes.json"

def load_existing_quotes():
    """Load quotes from the existing JSON file, if it exists."""
    if os.path.exists(OUTPUT_FILE):
        with open(OUTPUT_FILE, "r", encoding="utf-8") as f:
            try:
                return json.load(f)
            except json.JSONDecodeError:
                return []
    return []

def fetch_quotes(existing_quotes):
    res = requests.get(BASE_URL)
    if res.status_code != 200:
        print(f"Failed to fetch {BASE_URL}")
        return []

    soup = BeautifulSoup(res.text, "html.parser")
    ul = soup.select_one("#sidebar > div:nth-of-type(2) > div > div:nth-of-type(1) > ul")
    if not ul:
        print("Could not find the quotes UL")
        return []

    quotes = []

    # Build a set of existing quotes and URLs for quick checking
    existing_texts = {q["quote"] for q in existing_quotes}
    existing_links = {q["source"] for q in existing_quotes}

    for li in ul.find_all("li"):
        a = li.find("a")
        if not a:
            continue

        link = a.get("href", "").strip()
        print(f"Processing link: {link}")
        if link and not link.startswith("http"):
            link = f"{BASE_URL}{link}"

        # Skip if quote or link already exists
        if link in existing_links:
            print(f"Skipping existing link: {link}")
            continue

        try:
            res_page = requests.get(link)
            if res_page.status_code != 200:
                print(f"Failed to fetch {link}")
                continue

            soup_page = BeautifulSoup(res_page.text, "html.parser")
            quote_div = soup_page.select_one("#content > div:nth-of-type(2) > div:nth-of-type(1) > div:nth-of-type(1)")
            if not quote_div:
                print(f"Could not find quote on page {link}")
                continue

            full_quote = quote_div.get_text(strip=True)
            if full_quote in existing_texts:
                print(f"Skipping existing quote: {full_quote[:30]}...")
                continue

            quote_div = soup_page.select_one("#content > div:nth-of-type(2) > div:nth-of-type(1) > div:nth-of-type(1)")
            full_quote = quote_div.get_text(strip=True) if quote_div else ""

            # Extract the smaller explanation under the quote
            smaller_td = soup_page.select_one("#content > div:nth-of-type(2) > table > tbody > tr:nth-of-type(3) > td")
            extra_text = smaller_td.get_text(strip=True) if smaller_td else ""


            quotes.append({
                "quote": full_quote,
                "source": link,
                "extra": extra_text
            })

            # Optional: polite delay
            time.sleep(0.5)

        except Exception as e:
            print(f"Error fetching {link}: {e}")
            continue

    return quotes

def main():
    existing_quotes = load_existing_quotes()
    new_quotes = fetch_quotes(existing_quotes)

    if not new_quotes:
        print("No new quotes found.")
        return

    # Combine existing quotes with new quotes
    combined_quotes = existing_quotes + new_quotes

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(combined_quotes, f, ensure_ascii=False, indent=2)

    print(f"Added {len(new_quotes)} new quotes. Total now: {len(combined_quotes)}")

if __name__ == "__main__":
    main()
