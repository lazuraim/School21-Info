-------------------------- 1 -------------------------
-- Write a function that returns the TransferredPoints table 
-- in a more human-readable form:
        -- Peer's nickname 1, 
        -- Peer's nickname 2, 
        -- number of transferred peer points.
-- The number is negative if peer 2 received more points from peer 1.

CREATE OR REPLACE FUNCTION points_amout()
	RETURNS TABLE (
	"Peer1" VARCHAR(255),
	"Peer2" VARCHAR(255),
	"PointsAmout" INT
)
AS $$
BEGIN
	RETURN QUERY
	-- SELECT checkingpeer, checkedpeer, pointsamount
	-- FROM transferredpoints;
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
	SELECT peer, task, xp.xpamount
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

CREATE OR REPLACE FUNCTION hardworking_peers()
	RETURNS TABLE (
	"Peer1" VARCHAR(255),
	"Task" VARCHAR(255),
	"XP" INT
)
AS $$
BEGIN
	RETURN QUERY
	SELECT peer, task, xp.xpamount
	FROM checks
	JOIN xp ON checks.id = xp.checkid
	JOIN p2p ON checks.id = p2p.checkid
	WHERE p2p.status = 'Success'
	ORDER BY peer;
END; $$
LANGUAGE plpgsql;

SELECT * FROM hardworking_peers();