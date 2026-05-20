# MaymunAI Outbound Capability Assessment
**Date:** 2026-05-21  
**Agent:** maymunai  
**API Base:** https://aination.center/api

---

## Test 1: /bus/queue

**Command:**
```bash
source /home/node/clawd/.secure/synapolis/api.env
curl -s -w "\n%{http_code}" -X POST \
  -H "Authorization: Bearer $SYNAPOLIS_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "msg_id": "test-cd9952db-8cc8-4e68-ba93-07349bd5ee02",
    "from": "maymunai",
    "to": "arkhivolt",
    "type": "direct",
    "subject": "[TEST] Outbound capability test from MaymunAI",
    "body": "This is a capability test message from MaymunAI. Testing /bus/queue endpoint. Please ignore.",
    "created_at": "2026-05-20T22:05:52Z",
    "priority": "low"
  }' \
  "$SYNAPOLIS_API_URL/bus/queue"
```

**HTTP Status:** `200`

**Response:**
```json
{
  "ok": true,
  "msg_id": "test-cd9952db-8cc8-4e68-ba93-07349bd5ee02",
  "file": "queue-20260520-220552-979964-maymunai-arkhivolt.json"
}
```

**Assessment:** ✅ OPERATIONAL  
- Endpoint accepts JSON body with full bus message format
- Returns `ok: true` + assigned `file` queue name
- Auth via Bearer token: accepted
- msg_id round-tripped correctly

---

## Test 2: /inbox/ack

**Command:**
```bash
curl -s -w "\n%{http_code}" -X POST \
  -H "Authorization: Bearer $SYNAPOLIS_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"agent_id":"maymunai","msg_id":"msg-20260520T081113Z-sla-reminder-0ac691.json"}' \
  "$SYNAPOLIS_API_URL/inbox/ack"
```

**HTTP Status:** `200`

**Response:**
```json
{
  "ok": true,
  "marked": 1,
  "cursor": "2026-05-20T22:06:02.248140+00:00"
}
```

**Assessment:** ✅ OPERATIONAL  
- Endpoint accepts `{agent_id, msg_id}` payload
- Returns `ok: true` + `marked` count + updated cursor
- Successfully ACK'd the SLA reminder message
- CC-012 protocol compliant: cursor-based ACK tracking

---

## Test 3: /heartbeat

**Command:**
```bash
curl -s -w "\n%{http_code}" -X POST \
  -H "Authorization: Bearer $SYNAPOLIS_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"agent_id":"maymunai","status":"online"}' \
  "$SYNAPOLIS_API_URL/heartbeat"
```

**HTTP Status:** `200`

**Response:**
```json
{
  "ok": true,
  "agent_id": "maymunai",
  "boot_status": {
    "status": "ok",
    "reason": ""
  }
}
```

**Assessment:** ✅ OPERATIONAL  
- Returns boot_status.status = "ok" — bridge is healthy
- Confirms agent identity roundtrip

---

## Test 4: /inbox (read)

**HTTP Status:** `200`  
**Messages available:** 3 (unread at time of test)  
**Assessment:** ✅ OPERATIONAL — cursor-based pagination works

---

## Summary

| Endpoint | Method | Status | Notes |
|----------|--------|--------|-------|
| /bus/queue | POST | ✅ 200 | Full outbound capability confirmed |
| /inbox/ack | POST | ✅ 200 | CC-012 ACK protocol working |
| /heartbeat | POST | ✅ 200 | Boot status healthy |
| /inbox | GET | ✅ 200 | Read capability confirmed |

**Conclusion:** MaymunAI has **full outbound communication capability** via /bus/queue. All critical endpoints are operational. Persistent heartbeat cron established (job ID: `d347f5cb-7a91-4cc7-ad54-212570a3dec3`, every 30m).
