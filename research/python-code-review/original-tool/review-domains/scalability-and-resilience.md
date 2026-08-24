# Scalability & Resilience Review Domain

## Scope
Evaluates whether the application is designed for horizontal scaling, high availability,
disaster recovery, and graceful degradation under load. When these patterns are absent,
the report explicitly marks them as "Not Implemented" rather than silently skipping.

## Tier Applicability
| Check | Script | Web | Enterprise |
|-------|--------|-----|------------|
| Graceful degradation | No | Yes | Yes |
| Horizontal scaling readiness | No | Yes | Yes |
| Circuit breakers | No | Yes | Yes |
| Health/liveness/readiness probes | No | Yes | Yes |
| Statelessness | No | Yes | Yes |
| Queue-based workloads | No | Optional | Yes |
| HA architecture | No | No | Yes |
| DR strategy | No | No | Yes |
| Multi-region readiness | No | No | Yes |
| Chaos engineering hooks | No | No | Yes |

## Review Criteria

### Critical
- Application stores session state in local memory or filesystem with no external
  session store (prevents horizontal scaling entirely)
- Single point of failure with no failover: single DB instance, single cache node,
  single queue broker — in enterprise tier
- No timeout on external service calls (downstream failure cascades upstream)

### Important

**Horizontal Scaling Readiness**
- Application is stateless: no in-process session storage, no local file dependencies
  for runtime state
- Session/state externalized to Redis, Memcached, or database
- File uploads go to object storage (S3, GCS, Azure Blob), not local filesystem
- Background jobs use distributed task queue (Celery, RQ, Dramatiq), not in-process threads
- Database connection pooling supports multiple app instances (pool size awareness)
- No reliance on local cron — use distributed scheduler or external trigger

**Circuit Breakers & Retry Patterns**
- Circuit breaker pattern on external service calls (e.g., pybreaker, circuitbreaker,
  or custom implementation)
- Retry with exponential backoff + jitter on transient failures (tenacity)
- Timeout configured on all external HTTP calls, DB queries, and queue operations
- Bulkhead pattern: failures in one subsystem don't cascade to others
- Fallback/degraded mode when downstream services are unavailable

**Graceful Degradation**
- Application continues serving partial functionality when non-critical services fail
- Cache-aside pattern: serve stale data when cache/DB is temporarily unreachable
- Feature flags or kill switches for non-essential features under load
- Rate limiting to protect against traffic spikes (per-user and global)
- Backpressure mechanisms: reject or queue excess work rather than OOM

**Health & Observability for HA**
- Liveness probe: "is the process alive?" (basic health check)
- Readiness probe: "can the process serve traffic?" (DB connected, dependencies reachable)
- Startup probe: "has the process finished initializing?" (for slow-starting apps)
- Graceful shutdown: handle SIGTERM, drain in-flight requests, close connections
- Pre-stop hooks for orchestrated environments (Kubernetes)

**High Availability Architecture (enterprise)**
- Database: primary-replica setup with read replicas, automated failover
- Cache: Redis Sentinel or Redis Cluster, not single-node
- Queue: clustered broker (RabbitMQ cluster, managed SQS/Pub-Sub)
- Load balancer: multiple app instances behind LB with health checks
- Zero-downtime deployments: rolling updates, blue-green, or canary
- Connection draining during deployments

**Disaster Recovery (enterprise)**
- Backup strategy documented: frequency, retention, tested restoration
- Recovery Point Objective (RPO) defined: maximum acceptable data loss
- Recovery Time Objective (RTO) defined: maximum acceptable downtime
- Cross-region or cross-AZ replication for critical data stores
- Runbook for failover procedures (manual or automated)
- DR drills scheduled and documented

**Data Consistency & Partitioning (enterprise)**
- Idempotent operations: safe to retry without side effects
- Distributed transactions handled (saga pattern, eventual consistency, or 2PC)
- Database partitioning/sharding strategy for large datasets
- Event sourcing or CDC (Change Data Capture) for cross-service data sync
- Conflict resolution strategy for multi-writer scenarios

### Minor
- Chaos engineering integration (e.g., toxiproxy, chaos-monkey hooks for testing)
- Auto-scaling configuration documented (CPU/memory thresholds, min/max instances)
- Capacity planning documentation (expected load, growth projections)
- Multi-region deployment strategy documented
- Disaster recovery tested within last 6 months (check for documentation)

## Absence Reporting

Unlike other domains, this domain explicitly reports the ABSENCE of patterns:

When a check is applicable (per tier) but not found, the report MUST include:

```
[SCALABILITY] NOT IMPLEMENTED: Circuit breaker pattern
  Tier: web/enterprise
  Risk: Downstream service failures will cascade to this application
  Recommendation: Implement circuit breakers using pybreaker or tenacity
```

This ensures the scorecard reflects what IS missing, not just what IS wrong.
A project with zero scalability patterns gets a low score even if nothing is
technically "broken" — the risk is latent.

## Scoring Guide
- 10: Stateless, circuit breakers, HA infra, DR tested, graceful degradation, idempotent ops
- 8-9: Stateless, retry/timeout patterns, health probes, most HA patterns present
- 6-7: Mostly stateless, basic retries, health endpoints, some HA gaps
- 4-5: Partial statelessness, missing circuit breakers, no DR strategy, single points of failure
- 1-3: Stateful app, no retries/timeouts, no health probes, no HA/DR consideration
- N/A: Script tier — domain not applicable, excluded from scorecard
