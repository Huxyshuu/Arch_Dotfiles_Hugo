#!/bin/bash
DB="$HOME/.cache/cliphist/db"
TMP="$DB.tmp"

if [ -f "$DB" ]; then
    head -n 30 "$DB" > "$TMP"
    mv "$TMP" "$DB"
fi
