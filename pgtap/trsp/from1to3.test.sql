BEGIN;

SELECT plan(7);

UPDATE edge_table SET cost = sign(cost) + 0.001 * id * id, reverse_cost = sign(reverse_cost) + 0.001 * id * id;

CREATE OR REPLACE FUNCTION edge_cases()
RETURNS SETOF TEXT AS
$BODY$
BEGIN


  PREPARE q1 AS
  SELECT * from pgr_trsp(
    'select  id::INTEGER, source::INTEGER, target::INTEGER, cost, reverse_cost from edge_table',
    1, 1,
    true, true);

  PREPARE q2 AS
  SELECT * from pgr_trsp(
    'select  id::INTEGER, source::BIGINT, target::INTEGER, cost, reverse_cost from edge_table',
    1, 3,
    true, true);

  PREPARE q21 AS
  SELECT seq, id1, id2,   round(cost::numeric, 3) from pgr_trsp(
    'select  id::INTEGER, source::INTEGER, target::INTEGER,cost, reverse_cost from edge_table',
    1, 3,
    true, true);

  PREPARE q22 AS
  SELECT seq-1, node::INTEGER, edge::INTEGER, round(cost::numeric, 3) from pgr_dijkstra(
    'select  id::INTEGER, source::INTEGER, target::INTEGER,cost, reverse_cost from edge_table',
    1, 3, true);

  PREPARE q31 AS
  SELECT seq, id1, id2, round(cost::numeric, 3) from pgr_trsp(
    'select  id::INTEGER, source::INTEGER, target::INTEGER,cost, reverse_cost from edge_table',
    1, 3,
    true, true,
    'select 8::INTEGER as target_id, ''4''::TEXT as via_path,  100.2::FLOAT to_cost');

  PREPARE q32 AS
  SELECT (row_number() over() -1)::INTEGER, node::INTEGER,
  (CASE WHEN edge = -2 THEN -1 ELSE edge END)::INTEGER, round(cost::numeric, 3)
  FROM pgr_dijkstraVia(
    'select  id, source, target, cost, reverse_cost from edge_table',
    ARRAY[1, 10, 12, 4, 3],
    true) where edge != -1;


  RETURN QUERY SELECT is_empty('q1', '1: Directed: No path from 1 to 1');

  IF NOT min_version('4.0.0') THEN
    PERFORM todo(1, 'Function does not accept ANY-INTEGER and ANY-NUMERICAL');
  END IF;
  RETURN QUERY SELECT lives_ok('q2', 'ANY_INTEGER and ANY_NUMERICAL are accepted');

  RETURN QUERY SELECT set_eq('q21','q22','3: Directed: without retrictions returns the same as pgr_dijkstra');
  RETURN QUERY SELECT set_eq('q31','q32','4: Directed: with retrictions returns expected path');




  PREPARE q41 AS
  SELECT * from pgr_trsp(
    'select  id::INTEGER, source::INTEGER, target::INTEGER,cost, reverse_cost from edge_table',
    1, 1,
    FALSE, true);

  PREPARE q51 AS
  SELECT seq, id1, id2, cost::text from pgr_trsp(
    'select  id::INTEGER, source::INTEGER, target::INTEGER,cost, reverse_cost from edge_table',
    1, 3,
    FALSE, true);

  PREPARE q52 AS
  SELECT seq-1, node::INTEGER, edge::INTEGER, cost::text from pgr_dijkstra(
    'select  id::INTEGER, source::INTEGER, target::INTEGER,cost, reverse_cost from edge_table',
    1, 3, FALSE);

  PREPARE q61 AS
  SELECT seq, id1, id2, cost::text from pgr_trsp(
    'select  id::INTEGER, source::INTEGER, target::INTEGER,cost, reverse_cost from edge_table',
    1, 3,
    FALSE, true,
    'select 8::INTEGER as target_id, ''4''::TEXT as via_path,  100.2::FLOAT to_cost');

  PREPARE q62 AS
  SELECT (row_number() over() -1)::INTEGER, node::INTEGER,
  (CASE WHEN edge = -2 THEN -1 ELSE edge END)::INTEGER, cost::text
  FROM pgr_dijkstraVia(
    'select  id::INTEGER, source::INTEGER, target::INTEGER, cost, reverse_cost from edge_table',
    ARRAY[1, 2, 3],
    FALSE) where edge != -1;


  RETURN QUERY SELECT is_empty('q41', '5: Undirected: No path from 1 to 1');
  RETURN QUERY SELECT set_eq('q51','q52','6: Undirected: without retrictions returns the same as pgr_dijkstra');

  RETURN QUERY SELECT set_eq('q61','q62','7: Undirected: with retrictions returns expected path');
END;
$BODY$
LANGUAGE plpgsql;

SELECT edge_cases();

SELECT finish();
ROLLBACK;
