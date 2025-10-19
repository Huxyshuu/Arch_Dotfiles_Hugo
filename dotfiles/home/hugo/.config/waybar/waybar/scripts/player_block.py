#!/usr/bin/env python3
import json
import subprocess

DELIM = "⟪⟪⟪"

def get_player_metadata():
    try:
        output = subprocess.check_output([
            "playerctl", "-a", "metadata",
            "--format",
            f"{{{{status}}}}{DELIM}{{{{markup_escape(artist)}}}} - {{{{markup_escape(title)}}}}{DELIM}{{{{playerName}}}}"
        ], stderr=subprocess.DEVNULL).decode().strip()

        if not output:
            raise ValueError("Empty playerctl output")

        for line in output.splitlines():
            parts = line.strip().split(DELIM)
            if len(parts) == 3:
                status, label, player = parts

                icon_map = {
                    "Playing": "󰏥",
                    "Paused": "",
                    "Stopped": ""
                }
                icon = icon_map.get(status, "")

                return {
                    "text": f"{icon}  {label}",
                    "tooltip": f"{player} : {label}",
                    "class": status.lower()
                }

        raise ValueError("No valid player metadata found")

    except Exception:
        return {
            "text": " No Player",
            "tooltip": "No active player",
            "class": "stopped"
        }

if __name__ == "__main__":
    import sys
    print(json.dumps(get_player_metadata()))
