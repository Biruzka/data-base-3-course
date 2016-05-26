
--==============================================
-- EXPLAIN (ANALYSE )
--==============================================

EXPLAIN (ANALYSE )
SELECT *
FROM master_class
JOIN person
  ON master_class.id_lector = person.id

-- Суммарное время выполнения запроса: 314 ms.
-- 7 строк получено.

-- "Hash Join  (cost=5146.00..13287.00 rows=100000 width=156) (actual time=208.892..302.658 rows=100000 loops=1)"
-- "  Hash Cond: (master_class.id_lector = person.id)"
-- "  ->  Seq Scan on master_class  (cost=0.00..2429.00 rows=100000 width=68) (actual time=0.007..11.100 rows=100000 loops=1)"
-- "  ->  Hash  (cost=2528.00..2528.00 rows=100000 width=88) (actual time=208.613..208.613 rows=100000 loops=1)"
-- "        Buckets: 1024  Batches: 16  Memory Usage: 781kB"
-- "        ->  Seq Scan on person  (cost=0.00..2528.00 rows=100000 width=88) (actual time=0.002..13.348 rows=100000 loops=1)"
-- "Total runtime: 306.194 ms"


SET enable_seqscan TO off;

EXPLAIN (ANALYSE )
SELECT *
FROM master_class
JOIN person
  ON master_class.id_lector = person.id

-- Суммарное время выполнения запроса: 162 ms.
-- 7 строк получено.

-- "Hash Join  (cost=10000006753.29..10000014894.29 rows=100000 width=156) (actual time=48.435..150.106 rows=100000 loops=1)"
-- "  Hash Cond: (master_class.id_lector = person.id)"
-- "  ->  Seq Scan on master_class  (cost=10000000000.00..10000002429.00 rows=100000 width=68) (actual time=0.003..10.883 rows=100000 loops=1)"
-- "  ->  Hash  (cost=4135.29..4135.29 rows=100000 width=88) (actual time=48.202..48.202 rows=100000 loops=1)"
-- "        Buckets: 1024  Batches: 16  Memory Usage: 781kB"
-- "        ->  Index Scan using person_pkey on person  (cost=0.29..4135.29 rows=100000 width=88) (actual time=0.011..20.868 rows=100000 loops=1)"
-- "Total runtime: 154.045 ms"

--==============================================
-- EXPLAIN (ANALYSE )
--==============================================