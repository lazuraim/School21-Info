-------------------------- 1 -------------------------
-- Write a function that returns the TransferredPoints table 
-- in a more human-readable form:
        -- Peer's nickname 1, 
        -- Peer's nickname 2, 
        -- number of transferred peer points.
-- The number is negative if peer 2 received more points from peer 1.

CREATE OR REPLACE FUNCTION points_amount()
	RETURNS TABLE (
	"Peer1" VARCHAR(255),
	"Peer2" text,
	"PointsAmout" INT
)
AS $$
BEGIN
	RETURN QUERY
	SELECT tp1.checkingpeer,
		   tp1.checkedpeer, 
		   -1 * (tp1.pointsamount - tp2.pointsamount)
	FROM transferredpoints AS tp1
	JOIN transferredpoints AS tp2 ON tp1.checkingpeer = tp2.checkedpeer 
								 AND tp1.checkedpeer = tp2.checkingpeer 
								 AND tp1.id < tp2.id;
END; $$
LANGUAGE plpgsql;

SELECT * FROM points_amount();

-------------------------------- 2 ---------------------------------
-- Write a function that returns a table of the following form: 
        -- user name, 
        -- name of the checked task, 
        -- number of XP received
-- Include in the table only tasks that have successfully passed the check (according to the Checks table).
-- One task can be completed successfully several times. In this case, include all successful checks in the table.

CREATE OR REPLACE FUNCTION peer_task_xp()
	RETURNS TABLE (
	"Peer1" VARCHAR(255),
	"Task" VARCHAR(255),
	"XP" INT
)
AS $$
BEGIN
	RETURN QUERY
	SELECT peer, 
           task, 
           xp.xpamount
	FROM checks
	JOIN xp ON checks.id = xp.checkid
	JOIN p2p ON checks.id = p2p.checkid
	WHERE p2p.status = 'Success'
	ORDER BY peer;
END; $$
LANGUAGE plpgsql;

SELECT * FROM peer_task_xp();


-------------------------------- 3 ---------------------------------
-- Write a function that finds the peers who have not left campus for the whole day
-- Function parameters: day, for example 12.05.2022.
-- The function returns only a list of peers.

CREATE OR REPLACE FUNCTION hardworking_peers(day DATE)
	RETURNS TABLE (
	"Peer" VARCHAR(255)
	)
AS $$
BEGIN
	RETURN QUERY
	SELECT tt1.peer
	FROM timetracking AS tt1
	JOIN timetracking AS tt2 ON tt1.peer = tt2.peer 
                             AND tt1.date = tt2.date
	WHERE tt1.date = day 
          AND tt1.status = 1 
          AND tt2.status = 2 
          AND (tt2.time - tt1.time) > interval '10 hours';
END; $$
LANGUAGE plpgsql;

SELECT * FROM hardworking_peers('2022-08-08');
