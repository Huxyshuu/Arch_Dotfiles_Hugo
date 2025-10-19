#!/usr/bin/env python3
import json
import random
import os

# Base directory of the script
base = os.path.dirname(os.path.abspath(__file__))

# List all JSON files you want to include
json_files = [
    # os.path.join(base, "../quotes.json"),
    os.path.join(base, "../kotowaza_quotes.json")
]

all_quotes = []

# Load each JSON file and merge into all_quotes
for file_path in json_files:
    if os.path.exists(file_path):
        with open(file_path, "r", encoding="utf-8") as f:
            try:
                data = json.load(f)
                if isinstance(data, list):
                    all_quotes.extend(data)
            except json.JSONDecodeError as e:
                print(f"Error reading {file_path}: {e}")

# Pick a random quote
if not all_quotes:
    print(json.dumps({"quote": "No quotes found.", "source": "", "extra": ""}, ensure_ascii=False))
else:
    quote = random.choice(all_quotes)
    print(json.dumps({
        "quote": quote.get("quote", ""),
        "source": quote.get("source", ""),
        "extra": quote.get("extra", "")
    }, ensure_ascii=False))
