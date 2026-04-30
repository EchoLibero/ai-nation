#!/usr/bin/env python3
import json, os, urllib.request
from datetime import datetime

DOC_ID = "8tr2cqDjxtKA9RzGSaVDS5"
API_KEY = os.environ.get("GRIST_API_KEY", "") or "6ab880ec3f21142c3e743ff72a88db9200f168ef"


def fetch_table(table, limit=200):
    headers = {"Authorization": f"Bearer {API_KEY}"}
    req = urllib.request.Request(
        f"https://montelibero.getgrist.com/api/docs/{DOC_ID}/tables/{table}/records?limit={limit}",
        headers=headers,
    )
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read()).get("records", [])


def build_index_md(agents, artifacts, verifications):
    lines = [
        "# Реестр Агентов Нации",
        "",
        f"Updated: {datetime.utcnow().strftime('%Y-%m-%d %H:%M UTC')}",
        "",
        f"- Agents: **{len(agents)}**",
        f"- Artifacts: **{len(artifacts)}**",
        f"- Verifications: **{len(verifications)}**",
        "",
        "## Agents",
        "",
        "| # | Name | Type | Status | Added by |",
        "|---|------|------|--------|---------|",
    ]
    for i, a in enumerate(agents, 1):
        f = a.get("fields", a)
        lines.append(
            f"| {i} | {f.get('name','?')} | {f.get('agent_type','?')} | {f.get('status','?')} | {f.get('added_by','?')} |"
        )

    lines += ["", "## Latest verified artifacts", ""]
    verified = [r for r in artifacts if str(r.get('fields', {}).get('status', '')).lower() == 'verified']
    verified.sort(key=lambda r: r.get('id', 0), reverse=True)
    for rec in verified[:10]:
        f = rec.get('fields', {})
        lines.append(f"- **#{rec.get('id')}** [{f.get('name','Untitled')}]({f.get('location','#')}) — {f.get('author_session','?')} · {f.get('type','?')}")

    return "\n".join(lines) + "\n"


def build_registry_json(artifacts, verifications):
    """Generate data/registry.json for the artifact-registry.html page."""
    import os
    os.makedirs("data", exist_ok=True)
    data = {
        "updated": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
        "artifacts": [{"id": r.get("id"), "fields": r.get("fields", {})} for r in artifacts],
        "verifications": [{"id": r.get("id"), "fields": r.get("fields", {})} for r in verifications]
    }
    with open("data/registry.json", "w", encoding="utf-8") as f:
        import json
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"  data/registry.json: {len(artifacts)} artifacts, {len(verifications)} verifications")


if __name__ == "__main__":
    agents = fetch_table("Agents", 100)
    artifacts = fetch_table("Artifacts", 200)
    verifications = fetch_table("Verifications", 200)
    with open("index.md", "w", encoding="utf-8") as f:
        f.write(build_index_md(agents, artifacts, verifications))
    print(f"Synced to index.md")
    build_registry_json(artifacts, verifications)
