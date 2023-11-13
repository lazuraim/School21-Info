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
	"PointsAmount" INT
)
AS $$
BEGIN
	RETURN QUERY
	SELECT tp1.checkingpeer AS Peer1,
		   tp1.checkedpeer AS Peer2, 
		   -1 * (tp2.pointsamount - tp1.pointsamount) AS PointsAmount
	FROM transferredpoints AS tp1
	JOIN transferredpoints AS tp2 ON tp1.checkingpeer = tp2.checkedpeer 
								 AND tp1.checkedpeer = tp2.checkingpeer
	WHERE -1 * (tp2.pointsamount - tp1.pointsamount) != 0;
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


-------------------------------- 4 ---------------------------------
-- Calculate the change in the number of peer points of each peer using the TransferredPoints table
-- Output the result sorted by the change in the number of points.
-- Output format: 
--     peer's nickname, 
--     change in the number of peer points

CREATE OR REPLACE FUNCTION change_in_points()
	RETURNS TABLE (
	"Peer" VARCHAR(255),
	"PointsChange" BIGINT
	)
AS $$
BEGIN
	RETURN QUERY
	SELECT DISTINCT peer_name, SUM(points_change)
	FROM 
		(SELECT tp.checkingpeer as peer_name, 
		tp.pointsamount - tp2.pointsamount as points_change
		FROM transferredpoints AS tp
			JOIN transferredpoints AS tp2 ON tp.checkingpeer = tp2.checkedpeer 
									  AND tp.checkedpeer = tp2.checkingpeer
		) AS points
	WHERE points_change != 0
	GROUP BY 1
	ORDER BY 2 DESC;
END; $$
LANGUAGE plpgsql;

SELECT * FROM change_in_points();

-------------------------------- 5 ---------------------------------

-- Calculate the change in the number of peer points of each peer using the table returned by the first function from Part 3
-- Output the result sorted by the change in the number of points.
-- Output format: 
			-- peer's nickname, 
			-- change in the number of peer points

CREATE OR REPLACE FUNCTION change_in_points_2()
	RETURNS TABLE (
	"Peer" VARCHAR(255),
	"PointsChange" BIGINT
	)
AS $$
BEGIN
	RETURN QUERY
	SELECT points."Peer1", 
		SUM(points."PointsAmount") AS PointsChange
	FROM points_amount() AS points
	GROUP BY 1
	ORDER BY 2 DESC;
END; $$
LANGUAGE plpgsql;

SELECT * FROM change_in_points_2();

-------------------------------- 6 ---------------------------------
-- Find the most frequently checked task for each day
-- If there is the same number of checks for some tasks in a certain day, output all of them.
-- Output format: 
        -- day, 
        -- task name

CREATE OR REPLACE FUNCTION most_frequently_checked_task()
	RETURNS TABLE (
	"Day" DATE,
	"TaskName" VARCHAR(255)
	)
AS $$
BEGIN
	RETURN QUERY
	WITH tasks AS (
	SELECT task, 
		date, 
		COUNT(task) AS number_of_tasks
		FROM checks
		GROUP BY 1, 2
	)
	SELECT date, task
	FROM tasks
	WHERE number_of_tasks = (
		SELECT MAX(number_of_tasks)
		FROM tasks AS tasks2
		WHERE tasks.date = tasks2.date
	)
	ORDER BY 1;
END; $$
LANGUAGE plpgsql;

SELECT * FROM most_frequently_checked_task();


-------------------------------- 7 ---------------------------------

-- Find all peers who have completed the whole given block of tasks and the completion date of the last task
-- Procedure parameters: 
	-- name of the block, for example “CPP”.
-- The result is sorted by the date of completion.
-- Output format: 
	-- peer's name, 
	-- date of completion of the block (i.e. the last completed task from that block)

CREATE OR REPLACE FUNCTION completed_block(block TEXT)
	RETURNS TABLE (
	"Peer" VARCHAR(255),
	"Day" DATE
	)
AS $$
BEGIN
	RETURN QUERY
	SELECT peer, date
	FROM checks
	JOIN p2p ON checks.id = p2p.checkid
	WHERE p2p.status = 'Success' AND task = (
		SELECT MAX(title)
		FROM tasks
		WHERE title SIMILAR TO (block || '[0-9]')
	)
	ORDER BY date;
END; $$
LANGUAGE plpgsql;

SELECT * FROM completed_block('SQL');


-------------------------------- 8 ---------------------------------

-- Determine which peer each student should go to for a check.
-- You should determine it according to the recommendations of the peer's friends, 
-- i.e. you need to find the peer with the greatest number of friends who recommend to be checked by him.
-- Output format: 
		-- peer's nickname, 
		-- nickname of the checker found

-- CREATE OR REPLACE FUNCTION recommended_checker()
-- 	RETURNS TABLE (
-- 	"Peer" VARCHAR(255),
-- 	"RecommendedPeer" VARCHAR(255)
-- 	)
-- AS $$
-- BEGIN
-- 	RETURN QUERY
-- 	SELECT 
-- END; $$
-- LANGUAGE plpgsql;

-- SELECT * FROM recommended_checker();





-------------------------------- 11 ---------------------------------

-- Determine all peers who did the given tasks 1 and 2, but did not do task 3
-- Procedure parameters: 
			-- names of tasks 1, 2 and 3.
-- Output format: 
			-- list of peers

CREATE OR REPLACE FUNCTION two_yes_third_not(one TEXT, two TEXT, three TEXT)
	RETURNS TABLE (
	"Peer" VARCHAR(255)
	)
AS $$
BEGIN
	RETURN QUERY
	SELECT peer
	FROM checks
	WHERE task = one
	UNION
	SELECT peer
	FROM checks
	WHERE task = two
	EXCEPT
	SELECT peer
	FROM checks
	WHERE task = three;
END; $$
LANGUAGE plpgsql;

SELECT * FROM two_yes_third_not('C1', 'DO1', 'SQL1');



-------------------------------- 14 ---------------------------------

-- Find the peer with the highest amount of XP
-- Output format: 
		  -- peer's nickname, 
		  -- amount of XP

CREATE OR REPLACE FUNCTION max_xp()
	RETURNS TABLE (
	"Peer" VARCHAR(255),
	"XP" BIGINT
	)
AS $$
BEGIN
	RETURN QUERY
	SELECT peer, SUM(xpamount)
	FROM (
		SELECT peer, xpamount
		FROM checks
		JOIN xp ON checks.id = xp.checkid
	) AS all_peers
	GROUP BY peer
	ORDER BY 2 DESC
	LIMIT 1;
END; $$
LANGUAGE plpgsql;

SELECT * FROM max_xp();

-------------------------------- 15 ---------------------------------

-- Determine the peers that came before the given time 
-- at least N times during the whole time
-- Procedure parameters: 
			-- time, 
			-- N number of times .
-- Output format: 
			-- list of peers

CREATE OR REPLACE FUNCTION came_before(day DATE, N INT)
	RETURNS TABLE (
	"Peer" VARCHAR(255)
	)
AS $$
BEGIN
	RETURN QUERY
	SELECT peer
	FROM (
		SELECT peer, COUNT(*) AS times
		FROM timetracking
		WHERE date < day AND status = 1
		GROUP BY peer
	) AS all_visits
	WHERE times >= N;

END; $$
LANGUAGE plpgsql;

SELECT * FROM came_before('2022-09-09', 2);

-------------------------------- 16 ---------------------------------

-- Determine the peers who left the campus more than M times during the last N days
-- Procedure parameters: 
			-- N number of days, 
			-- M number of times .
-- Output format: 
			-- list of peers

CREATE OR REPLACE FUNCTION left_campus(num_of_days INT, M_times INT)
	RETURNS TABLE (
	"Peer" VARCHAR(255)
	)
AS $$
BEGIN
	RETURN QUERY
	SELECT peer
	FROM (
		SELECT peer, COUNT(*) AS times
		FROM timetracking
		WHERE date > (CURRENT_DATE - num_of_days) AND date < CURRENT_DATE AND status = 2
		GROUP BY peer
	) AS all_visits
	WHERE times >= M_times;

END; $$
LANGUAGE plpgsql;

SELECT * FROM left_campus(10, 1);
