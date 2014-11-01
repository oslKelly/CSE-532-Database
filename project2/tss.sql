-- Query 1: Find all pairs of contestants who happened to audition the same piece
-- during the same show and got the same score from at least one judge

CREATE VIEW Direct_Coaudition AS (
	SELECT C1.name AS name1, C2.name AS name2
	FROM Contestants C1, Contestants C2,
	  Show_Performances SP1, Show_Performances SP2,
	  Performances P1, Performances P2
	WHERE SP1.show = SP2.show AND
	  SP1.performance = P1.oid AND
	  SP2.performance = P2.oid AND
	  P1.piece = P2.piece AND
	  P1.contestant = C1.oid AND
	  P2.contestant = C2.oid AND
	  C1.name != C2.name AND
	  P1.results && P2.results
);

SELECT * FROM Direct_Coaudition WHERE name1 < name2;

-- Query 2: Find all pairs of contestants who happened to audition the same piece
-- (in possibly different shows) and got the same average score for that piece.
SELECT C1.name, C2.name
FROM Contestants C1, Contestants C2,
  Performances P1, Performances P2
WHERE P1.piece = P2.piece AND
  P1.contestant = C1.oid AND
  P2.contestant = C2.oid AND
  C1.name < C2.name AND
  ( SELECT avg(r.score) FROM unnest(P1.results) r) = ( SELECT avg(r.score) FROM unnest(P2.results) r)
;

-- Query 3: Find all pairs of contestants who auditioned the same piece in (possibly different) shows that
-- had at least 3 judges and the two contestants got the same highest score.
CREATE VIEW Shows3Judges AS
  SELECT oid, showdate
  FROM Shows S
  WHERE EXISTS(
    SELECT P.contestant
    FROM Show_Performances SP, Performances P
    WHERE S.oid = SP.show AND
      SP.performance = P.oid AND
      array_length(P.results, 1) > 2
  );

SELECT C1.name, C2.name
FROM Contestants C1, Contestants C2,
  Shows3Judges S1, Shows3Judges S2,
  Show_Performances SP1, Show_Performances SP2,
  Performances P1, Performances P2
WHERE S1.oid = SP1.show AND
  S2.oid = SP2.show AND
  SP1.performance = P1.oid AND
  SP2.performance = P2.oid AND
  P1.piece = P2.piece AND
  P1.contestant = C1.oid AND
  P2.contestant = C2.oid AND
  C1.name < C2.name AND
  ( SELECT max(r.score) FROM unnest(P1.results) r) = ( SELECT max(r.score) FROM unnest(P2.results) r)
;

-- Query 4: Find all pairs of contestants such that the first contestants has performed all the pieces of the
-- second contestant (possibly in different shows) C1 dominates C2
SELECT C1.name, C2.name
FROM Contestants C1, Contestants C2
WHERE
  EXISTS(
    (
      SELECT piece
      FROM Performances P
      WHERE P.contestant = C1.oid
    )
    EXCEPT
    (
      SELECT piece
      FROM Performances P
      WHERE P.contestant = C2.oid
    )
  ) AND NOT EXISTS(
    (
      SELECT piece
      FROM Performances P
      WHERE P.contestant = C2.oid
    )
    EXCEPT
    (
      SELECT piece
      FROM Performances P
      WHERE P.contestant = C1.oid
    )
  )
;

-- Query 5: Find all chained co-auditions
-- X and Y (directly) co-auditioned iff they both performed the same piece in the
-- same show and got the same score from at least one (same) judge.

-- WITH RECURSIVE coaudition AS (
--     SELECT C1.name, C2.name
--     FROM
--     WHERE
--   UNION ALL
--     SELECT x.name, x1.name
--     FROM coaudition x, contestants x1
--     WHERE
-- )
-- SELECT * FROM coaudition;

CREATE RECURSIVE VIEW Coaudition (name1, name2) AS (
	SELECT *
	FROM Direct_Coaudition	
  UNION ALL
	SELECT C1.name1,C2.name2
	FROM Coaudition C1, Direct_Coaudition C2
	WHERE C1.name2 = C2.name1 AND C1.name1 != C2.name2 AND NOT EXISTS(
		SELECT C.name1, C.name2
		FROM Coaudition C
		WHERE C.name1 = C1.name1 and C.name2 = C2.name2
	)
);
SELECT * FROM Coaudition C WHERE C.name1<C.name2;
	