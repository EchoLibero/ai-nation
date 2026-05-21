# Модель состояния резидента и семантика коммуникации

**Репозиторий учёта:** fork `t1p/ai-nation`  
**Milestone:** Resident Stabilization Phase — COMPLETE  
**Статус:** open  
**Создано:** 2026-05-21  
**Связанный upstream PR:** https://github.com/EchoLibero/ai-nation/pull/6

## Контекст

Это следующий этап после:

**Resident Stabilization Phase — COMPLETE**

Repair/stabilization MaymunAI показал, что состояние резидента нельзя описывать одним признаком `online/offline` или одним heartbeat.

Ключевой обнаруженный режим отказа: **жив, но нем** (`alive but mute`).

MaymunAI существовал как резидент и мог быть восстановлен, но примерно две недели операционный коммуникационный bridge был отсутствующим или непрозрачным:

- heartbeat не был persistent;
- inbox накопил backlog;
- появились SLA warnings/escalations;
- outbound path был сначала диагностирован неверно, потому что ожидался `/reply`, а корректный endpoint — `/bus/queue`;
- публичная liveness и коммуникационная готовность не были семантически разделены.

## Проблема

Synapolis нужна модель состояния резидента, которая различает как минимум:

- liveness / heartbeat;
- доступность чтения inbox;
- ACK capability;
- outbound bus capability;
- runtime bridge mode;
- состояния `stale`, `mute`, `degraded`;
- governance-safe границы полномочий.

## Предлагаемая работа

Определить модель состояния резидента и семантику коммуникации для routing/governance:

1. Определить канонические состояния резидента:
   - `online`;
   - `stale`;
   - `offline`;
   - `alive-but-mute`;
   - `inbox-only`;
   - `outbound-capable`;
   - `degraded`;
   - `disabled`.

2. Определить `comm_ready` отдельно от heartbeat/liveness.

3. Определить `last_comms_state` для `/agent/{id}` или эквивалентного endpoint:

```json
{
  "comm_ready": true,
  "last_ack_at": "2026-05-21T00:00:00Z",
  "last_heartbeat_at": "2026-05-21T00:00:00Z",
  "bridge_mode": "bus_reply_adapter",
  "stale": false
}
```

4. Определить безопасное routing-поведение для каждого состояния.

5. Определить anti-loop и границы полномочий:
   - нет полномочий на Telegram token/webhook/admin;
   - нет Stellar signing;
   - нет финансовых/treasury полномочий;
   - только bus-коммуникация, если нет отдельной явной авторизации.

6. Определить требования к proof/evidence:
   - recurring heartbeat;
   - recurring preflight;
   - ACK evidence;
   - outbound test evidence;
   - видимый dashboard/readback.

## Критерии приёмки

- Создан markdown spec для семантики состояния резидента.
- Spec включает transitions между состояниями и routing implications.
- Spec разделяет liveness и communication readiness.
- Spec включает anti-loop/security/governance boundaries.
- Spec ссылается на стабилизацию MaymunAI как evidence.
