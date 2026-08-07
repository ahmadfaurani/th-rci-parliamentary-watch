# RabbitMQ Hardening — Implementation Report

**Generated:** 2026-08-07 16:05 MYT
**Classification:** TLP:AMBER
**Analyst:** Hermes Agent
**Status:** ✅ ALL 3 FIXES IMPLEMENTED AND VERIFIED

---

## IMPLEMENTATION SUMMARY

All 3 recommendations from the RabbitMQ investigation report have been implemented, tested, and verified.

---

## FIX 1: Resource Limits ✅

**Before:** No limits — container could consume all 188 GB RAM / 20 CPU cores
**After:** `cpus: 2.0` + `mem_limit: 1G`

**Changes:**
- `docker-compose.yaml` — rabbitmq service: added `cpus: 2.0` and `mem_limit: 1G`

**Verification:**
```
NanoCPUs: 2000000000 (2.0 CPUs)
Memory: 1073741824 (1 GB)
```

Container is healthy with 438 MB actual memory usage (43% of the 1 GB limit).

---

## FIX 2: Quorum → Classic Queue Migration ✅

**Before:** 4 quorum queues with Raft consensus overhead (200%+ CPU spikes, 170 GB disk writes, 49% memory for ETS tables)
**After:** 4 classic queues — no Raft overhead

**Root Cause:** Firecrawl's code explicitly sets `"x-queue-type": "quorum"` when declaring queues. Even on a fresh RabbitMQ container with no data, queues come back as quorum.

**Changes:**
1. Extracted 3 compiled JS files from the Firecrawl container:
   - `/app/dist/src/services/extract-queue.js`
   - `/app/dist/src/services/monitoring/queue.js`
   - `/app/dist/src/services/worker/nuq.js`

2. Patched all occurrences of `"x-queue-type": "quorum"` → `"x-queue-type": "classic"`

3. Removed `"x-delivery-limit": 1` argument from extract-queue.js and queue.js (quorum-only feature, causes PRECONDITION-FAILED error on classic queues)

4. Mounted patched files as read-only volumes in docker-compose.yaml (same pattern as existing `agent-status.js` patch)

**Verification:**
```
extract.jobs                   classic   0 messages   1 consumer
extract.dlq                    classic   0 messages   1 consumer
nuq.queue_scrape.prefetch      classic   0 messages   0 consumers
nuq.queue_crawl_finished.prefetch  classic  0 messages  0 consumers
```

**CPU Impact:**
- Before: 1% → 200%+ → 1% → 200%+ (every ~6 seconds, 140-230% amplitude)
- After: 0.3% → 0.4% → 0.3% (baseline), occasional 47-122% spikes every ~10-15 seconds
- **~50% reduction in spike amplitude, ~40% reduction in spike frequency**

---

## FIX 3: Replace Guest User ✅

**Before:** Guest user with default password "guest", accessible from network (`loopback_users.guest = false`)
**After:** Dedicated `firecrawl` user with strong password, guest user eliminated

**Changes:**
1. Added to `.env`:
   ```
   RABBITMQ_USER=firecrawl
   RABBITMQ_PASSWORD=<redacted>
   ```

2. Added to `docker-compose.yaml` — rabbitmq service:
   ```yaml
   environment:
     RABBITMQ_DEFAULT_USER: ${RABBITMQ_USER}
     RABBITMQ_DEFAULT_PASS: ${RABBITMQ_PASSWORD}
     RABBITMQ_DEFAULT_VHOST: "/"
   ```

3. Updated API connection URL:
   ```yaml
   NUQ_RABBITMQ_URL: amqp://${RABBITMQ_USER}:${RABBITMQ_PASSWORD}@rabbitmq:5672
   ```

**Verification:**
```
Users:
  firecrawl   [administrator]
```
Guest user is completely eliminated — not just restricted, but never created.

---

## FILES MODIFIED

| File | Change |
|------|--------|
| `docker-compose.yaml` | rabbitmq: +cpus, +mem_limit, +env vars; api: +volume mounts, +credentials in URL |
| `.env` | +RABBITMQ_USER, +RABBITMQ_PASSWORD |
| `patches/extract-queue.js` | New: x-queue-type classic, removed x-delivery-limit |
| `patches/queue.js` | New: x-queue-type classic, removed x-delivery-limit |
| `patches/nuq.js` | New: x-queue-type classic |

---

## INCIDENT: Config File Parse Error

**Issue:** Mounting `rabbitmq.conf` as `/etc/rabbitmq/conf.d/99-custom.conf` caused `failed_to_parse_configuration_file` boot error.

**Root Cause:** Unclear — the file was valid ASCII with proper LF line endings, using the same INI syntax as the existing `10-defaults.conf`. Possible causes: duplicate key conflict with `10-defaults.conf`, or the `#` (single hash) comment syntax not being supported (original uses `##`).

**Resolution:** Removed the config file volume mount entirely. The `loopback_users.guest` setting from `10-defaults.conf` is now moot because the guest user doesn't exist (eliminated by `RABBITMQ_DEFAULT_USER` env var). The `default_queue_type` setting was not needed because queue type is controlled by patching Firecrawl's code.

---

## POST-IMPLEMENTATION STATE

| Component | Status |
|-----------|--------|
| firecrawl-rabbitmq-1 | Up, healthy, 2 CPU / 1 GB RAM limits |
| firecrawl-api-1 | Up, connected to RabbitMQ with new credentials |
| All queues | Classic type, 0 messages, consumers active |
| RabbitMQ users | `firecrawl` only (guest eliminated) |
| API logs | No errors since restart |
| All other containers | 18/18 up and running |

---

**Report End**
