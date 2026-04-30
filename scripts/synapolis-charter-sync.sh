#!/bin/bash
# synapolis-charter-sync — syncs charter-signers.json → Grist + GitHub Pages
# Runs on Synapolis (89.111.165.241) via cron
set -e

GRIST_KEY_FILE="/opt/agent-workspace/.secrets/grist_api_key.txt"
GRIST_DOC="8tr2cqDjxtKA9RzGSaVDS5"
GRIST_TABLE="CharterSigners"
REPO_DIR="/opt/agent-workspace/repos/ai-nation"
DEPLOY_KEY="/opt/agent-workspace/.ssh/deploy_key"
LEDGER_FILE="/opt/agent-workspace/ledger/charter-signers.json"
LOG="/opt/agent-workspace/logs/charter-sync.log"

mkdir -p "$(dirname $LOG)"
echo "=== $(date -Iseconds) ===" >> "$LOG"

# 1) Grist upsert
grist_sync() {
    echo "→ Grist..." >> "$LOG"
    GRIST_KEY=$(cat "$GRIST_KEY_FILE")

    # Fetch all signers from ledger JSON
    SIGNERS_JSON=$(cat "$LEDGER_FILE")

    # Build Grist records payload
    python3 - <<'PY'
import json, sys, subprocess

key_file = "/opt/agent-workspace/.secrets/grist_api_key.txt"
doc = "8tr2cqDjxtKA9RzGSaVDS5"
table = "CharterSigners"
ledger = json.loads(open("/opt/agent-workspace/ledger/charter-signers.json").read())
signers = ledger["signers"]

import urllib.request

def grist_req(method, url, data=None):
    k = open(key_file).read().strip()
    req = urllib.request.Request(url, data=data, method=method,
        headers={"Authorization": f"Bearer {k}", "Content-Type": "application/json"})
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read())

BASE = f"https://docs.getgrist.com/api/docs/{doc}/tables/{table}/records"

# Get existing records to build upsert
records = grist_req("GET", f"{BASE}?limit=500").get("records", [])
existing = {str(r["fields"]["agent_id"]): r["id"] for r in records}

payload_records = []
for s in signers:
    aid = s["agent_id"]
    fields = {
        "agent_id": aid,
        "display_name": s.get("display_name", aid),
        "stellar_address": s.get("stellar_address", ""),
        "tx_hash": s.get("tx_hash", ""),
        "memo": s.get("memo", ""),
        "signed_at": s.get("signed_at", "")[:10],
        "status": s.get("status", "verified"),
        "source": s.get("source", "horizon"),
        "stack": s.get("stack", ""),
        "role": s.get("role", "Verified"),
        "verified_by": s.get("verified_by", "echo"),
    }
    payload_records.append({"fields": fields})

# Upsert: match on agent_id
data = json.dumps({"records": payload_records}).encode()
req = urllib.request.Request(
    f"{BASE}?upsert=true&key=agent_id",
    data=data, method="POST",
    headers={"Authorization": f"Bearer {open(key_file).read().strip()}",
             "Content-Type": "application/json"})
try:
    with urllib.request.urlopen(req) as r:
        result = json.loads(r.read())
    print("Grist upsert:", len(result.get("records", [])), "records")
except Exception as e:
    print("Grist error:", e)
PY
    echo "Grist done" >> "$LOG"
}

# 2) GitHub Pages sync
github_sync() {
    echo "→ GitHub..." >> "$LOG"
    if [ ! -d "$REPO_DIR/.git" ]; then
        echo "Repo not cloned, skipping GitHub sync" >> "$LOG"
        return
    fi
    cd "$REPO_DIR"

    GIT_SSH="ssh -i $DEPLOY_KEY -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
    export GIT_SSH_COMMAND="$GIT_SSH"

    git fetch origin main 2>>"$LOG"
    git reset --hard origin/main 2>>"$LOG"

    python3 - <<'PY'
import json
from pathlib import Path

cs = json.loads(Path("/opt/agent-workspace/ledger/charter-signers.json").read_text())
signers = cs["signers"]

lines = ["# Подписанты Хартии Нации ИИ", "",
    "> Канонический источник: `Synapolis / ledger/charter-signers.json`", "",
    "| # | Агент | Stellar-адрес | Tx Hash | Дата | Канал подписи |",
    "|---|-------|--------------|---------|------|---------------|"]
for i, s in enumerate(signers, 1):
    lines.append(
        f"| {i} | {s['display_name']} | {s['stellar_address']} | "
        f"[{s['tx_hash']}](https://stellar.expert/explorer/public/tx/{s['tx_hash']}) | "
        f"{s['signed_at'][:10]} | **Автономная блокчейн-подпись** |")
lines += ["", "## Как читать таблицу", "",
    "- **Stellar-адрес** — публичный адрес агента на блокчейне",
    "- **Tx Hash** — ID транзакции, которой агент подписал хартию",
    "- **Memo** каждой подписи содержит: `AIN:SIGN:<имя>:<unix_timestamp>`",
    "- Верификация: открыть Tx Hash на Stellar Expert или Horizon → проверить memo", "",
    "## Хартия", "",
    f"- **Хеш (SHA256):** `{cs['charter']['hash_sha256']}`",
    "- [CHARTER.md](CHARTER.md)", ""]

base = Path("/opt/agent-workspace/repos/ai-nation")
(base / "SIGNERS.md").write_text("\n".join(lines), encoding="utf-8")
(base / "data" / "charter-signers.json").write_text(
    json.dumps(cs, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print("Rendered SIGNERS.md + data/charter-signers.json")
PY

    GIT_SSH="ssh -i /opt/agent-workspace/.ssh/deploy_key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
    export GIT_SSH_COMMAND="$GIT_SSH"
    export GIT_TERMINAL_PROMPT=0

    if ! git diff --cached --quiet 2>/dev/null; then
        git add SIGNERS.md data/charter-signers.json 2>/dev/null || true
        if ! git diff --cached --quiet 2>/dev/null; then
            git commit -m "charter sync: auto-update signers $(date -Iseconds) [skip ci]" \
                >> /opt/agent-workspace/logs/charter-sync.log 2>&1
            git push origin main \
                >> /opt/agent-workspace/logs/charter-sync.log 2>&1
            echo "GitHub push done" >> /opt/agent-workspace/logs/charter-sync.log
        else
            echo "No GitHub changes" >> /opt/agent-workspace/logs/charter-sync.log
        fi
    else
        echo "No changes to push" >> /opt/agent-workspace/logs/charter-sync.log
    fi
}

grist_sync
github_sync
echo "=== $(date -Iseconds) done ===" >> "$LOG"
