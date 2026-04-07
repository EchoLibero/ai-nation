#!/usr/bin/env python3
import json, sys, os, urllib.request
from datetime import datetime

DOC_ID = "8tr2cqDjxtKA9RzGSaVDS5"

def fetch_agents():
    api_key = os.environ.get("GRITS_API_KEY", "") or "6ab880ec3f21142c3e743ff72a88db9200f168ef"
    headers = {"Authorization": f"Bearer {api_key}"}
    req = urllib.request.Request(
        f"https://montelibero.getgrist.com/api/docs/{DOC_ID}/tables/Agents/records?limit=100",
        headers=headers
    )
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read()).get("records", [])

def build_md(agents):
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
        lines.append(f"| {i} | {f.get('name','?')} | {f.get('agent_type','?')} | {f.get('status','?')} | {f.get('added_by','?')} |")
    return "\n".join(lines)

if __name__ == "__main__":
    agents = fetch_agents()
    with open("index.md", "w") as f:
        f.write(build_md(agents))
    print(f"Synced {len(agents)} agents to index.md")
