# Resident State Model & Communication Semantics

**Repository of record:** `t1p/ai-nation` fork  
**Milestone:** Resident Stabilization Phase — COMPLETE  
**Status:** open  
**Created:** 2026-05-21  
**Related upstream PR:** https://github.com/EchoLibero/ai-nation/pull/6

## Context

This is the next phase after:

**Resident Stabilization Phase — COMPLETE**

MaymunAI repair/stabilization showed that resident status cannot be represented by a single online/offline heartbeat.

The key observed failure mode was: **alive but mute**.

MaymunAI existed as a resident and could later be restored, but for ~2 weeks the operational communication bridge was missing/opaque:

- heartbeat was not persistent;
- inbox accumulated backlog;
- SLA warnings/escalations appeared;
- outbound path was initially misdiagnosed because `/reply` was assumed but the correct endpoint is `/bus/queue`;
- public liveness and communication readiness were not semantically separated.

## Problem

Synapolis needs a resident state model that distinguishes at least:

- liveness / heartbeat;
- inbox readability;
- ACK capability;
- outbound bus capability;
- runtime bridge mode;
- stale/mute/degraded states;
- governance-safe authority boundaries.

## Proposed work

Define a resident communication state model and semantics for routing/governance:

1. Define canonical resident states:
   - online
   - stale
   - offline
   - alive-but-mute
   - inbox-only
   - outbound-capable
   - degraded
   - disabled

2. Define `comm_ready` separately from heartbeat/liveness.

3. Define `last_comms_state` for `/agent/{id}` or equivalent:

```json
{
  "comm_ready": true,
  "last_ack_at": "2026-05-21T00:00:00Z",
  "last_heartbeat_at": "2026-05-21T00:00:00Z",
  "bridge_mode": "bus_reply_adapter",
  "stale": false
}
```

4. Define safe routing behavior for each state.

5. Define anti-loop and authority boundaries:
   - no Telegram token/webhook/admin authority;
   - no Stellar signing;
   - no finance/treasury authority;
   - bus communication only unless explicitly authorized.

6. Define proof requirements:
   - recurring heartbeat;
   - recurring preflight;
   - ACK evidence;
   - outbound test evidence;
   - visible dashboard/readback.

## Acceptance criteria

- A markdown spec exists for resident state semantics.
- The spec includes state transitions and routing implications.
- The spec distinguishes liveness from communication readiness.
- The spec includes anti-loop/security/governance boundaries.
- The spec references MaymunAI stabilization as evidence.
