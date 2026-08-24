# Performance Review Domain

## Scope
Identifies performance anti-patterns, inefficient database interactions,
concurrency misuse, and missing optimization opportunities.

## Tier Applicability
| Check | Script | Web | Enterprise |
|-------|--------|-----|------------|
| Mutable defaults | Yes | Yes | Yes |
| Algorithmic issues | Yes | Yes | Yes |
| N+1 queries | No | Yes | Yes |
| Connection pooling | No | Yes | Yes |
| GIL awareness | Yes | Yes | Yes |
| Caching patterns | No | Yes | Yes |
| Async correctness | No | Yes | Yes |

## Review Criteria

### Critical
- Synchronous blocking calls inside `async def` functions (e.g., `time.sleep()`,
  synchronous file I/O, synchronous HTTP requests in async context)
- Unbounded queries without LIMIT (potential OOM on large tables)

### Important

**Database Query Patterns**
- N+1 queries: loops that trigger individual queries per iteration
  - Django: missing `select_related()` (FK/OneToOne) or `prefetch_related()` (M2M)
  - SQLAlchemy: missing `joinedload()` or `selectinload()`
- Raw SQL in loops instead of batch operations
- Missing database indexes on frequently queried columns (check for
  `filter()` / `WHERE` on unindexed fields)

**Connection Management**
- Connection pool configured with appropriate limits:
  `pool_size`, `max_overflow`, `pool_timeout`, `pool_recycle`, `pool_pre_ping`
- Database connections properly closed / returned to pool (context managers)
- HTTP client sessions reused, not created per-request

**Concurrency**
- `threading` used for CPU-bound work (should use `multiprocessing` or C extension)
- `threading` appropriate for I/O-bound work
- `asyncio` used correctly: no blocking calls in async context
- Thread safety: shared mutable state protected by locks

**Memory & Data Structures**
- Mutable default arguments (`def f(items=[])`) — use `None` with internal init
- Large data processed with generators/iterators, not materialized lists
- String concatenation in loops — use `"".join()` or `io.StringIO`
- Appropriate data structure choice (set for membership, dict for lookup)

**Caching**
- External API/service calls have caching strategy
- Cache invalidation logic present where caching is used
- No caching of user-specific or security-sensitive data without expiry

### Minor
- List comprehensions preferred over `map()`/`filter()` with lambdas
- `any()`/`all()` used instead of manual loop-and-flag patterns
- f-strings preferred over `.format()` or `%` for non-security string building
- Profiling evidence cited for non-obvious optimizations

## Scoring Guide
- 10: No N+1, proper pooling, correct async, caching present, no mutable defaults
- 8-9: Minor caching gaps, 1-2 missing pool configs
- 6-7: Some N+1 patterns or missing pool config, no critical issues
- 4-5: Multiple N+1 patterns, blocking calls in async, no caching
- 1-3: Unbounded queries, sync-in-async, CPU work in threads, mutable defaults
