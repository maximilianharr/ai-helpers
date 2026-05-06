# Runbook: High Error Rate

**Alert**: `HighErrorRate`
**Severity**: Warning → Critical if sustained > 10 min
**Maintained by**: ops-agent (auto-updates after incidents)

---

## Symptoms

- Prometheus alert `HighErrorRate` fires
- Error rate `rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.05`
- Users report 500 errors

---

## Immediate Triage (< 2 minutes)

```bash
# 1. Is the backend container running?
podman ps --filter name=backend

# 2. Check recent logs (last 50 lines)
podman logs --tail 50 backend

# 3. Check database connectivity
podman exec backend python -c "
import asyncio, os
from sqlalchemy.ext.asyncio import create_async_engine
async def check():
    engine = create_async_engine(os.getenv('DATABASE_URL'))
    async with engine.connect() as c:
        await c.execute(text('SELECT 1'))
    print('DB OK')
asyncio.run(check())
"

# 4. Check Redis
podman exec redis redis-cli -a "$REDIS_PASSWORD" ping
```

---

## Common Causes & Fixes

### Cause 1: Recent deployment broke something
**Signals**: Error rate spike immediately after deployment
```bash
# Rollback to previous image
IMAGE_TAG=<previous-sha> podman compose up -d backend
```

### Cause 2: Database connection pool exhausted
**Signals**: Logs show `TimeoutError: QueuePool limit`
```bash
# Check active connections
podman exec postgres psql -U app -c "SELECT count(*) FROM pg_stat_activity;"

# Restart backend to reset pool
podman compose restart backend
```

### Cause 3: Unhandled exception in new code path
**Signals**: Specific error message repeated in logs
```bash
# Find the error
podman logs backend 2>&1 | grep '"level":"error"' | tail -20 | jq .

# Fix: ops-agent creates a GitHub issue, dev-agent implements fix
scripts/run-agent.sh ops-agent --from-logs
```

---

## Escalation

If error rate > 20% for > 5 minutes and root cause not identified:
1. Rollback immediately: `IMAGE_TAG=<last-known-good> podman compose up -d`
2. Page on-call engineer
3. ops-agent will have created a GitHub issue — attach it to the incident

---

## Post-Incident

After resolution, ops-agent will:
1. Update this runbook if the cause wasn't listed above
2. Create a GitHub issue for the root-cause fix
3. Add a test to `tests/ai-generated/` that would have caught this
