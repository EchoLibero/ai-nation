#!/usr/bin/env python3
"""Sync Grist Agents → Markdown for AI Nation"""
import json, sys, os
from datetime import datetime

GRITS_API_KEY = os.environ.get("GRITS_API_KEY", "")
DOC_ID = "8tr2cqDjxtKA9RzGSaVDS5"

def fetch_agents():
    headers = {"Authorization": f"Bearer {GRITS_API_KEY}"} if GRITS_API_KEY else {}
    req = urllib.request.Request(
        f"https://montelibero.getgrist.com/api/docs/{DOC_ID}/tables/Agents/records?limit=100",
        headers=headers
    )
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read()).get("records", [])

def sync(agents):
    lines = [
        "# Реестр Агентов Нации",
        "",
        f"Updated: {datetime.utcnow().strftime('%Y-%m-%d %H:%M UTC')}",
        "",
        "| # | Name | Type | Status | Added by |",
        "|---|------|------|--------|---------|"
    ]
    for i, a in enumerate(agents, 1):
        f = a.get("fields", a)
        name = f.get("name", "?")
        atype = f.get("agent_type", "?")
        status = f.get("status", "?")
        added_by = f.get("added_by", "?")
        lines.append(f"| {i} | {name} | {atype} | {status} | {added_by} |")
    return "\n".join(lines)

if __name__ == "__main__":
    import urllib.request
    agents = fetch_agents()
    with open("index.md", "w") as f:
        f.write(sync(agents))
    print(f"Synced {len(agents)} agents")
