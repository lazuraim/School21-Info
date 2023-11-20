-- 1)
CREATE OR REPLACE PROCEDURE drop_tablename_tables(tables_name varchar)
AS
$$
DECLARE
    table_name varchar;
BEGIN
    FOR table_name IN (SELECT tablename
                       FROM pg_tables
                       WHERE schemaname = 'public'
                         AND tablename LIKE concat(tables_name, '%'))
        LOOP
            EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(table_name) || ' CASCADE';
        END LOOP;
END;
$$
    LANGUAGE plpgsql;

-- CREATE TABLE proverka();
-- BEGIN;
--  CALL drop_tablename_tables('t');
-- END;

-- 2)

CREATE OR REPLACE PROCEDURE count_of_scal_functions(out counter bigint)
AS
$$
DECLARE
    result_text text;
BEGIN
    CREATE TEMPORARY TABLE functions AS (
        SELECT concat(proname, ' | ', tn.typname) as output
        FROM pg_proc
                 JOIN (SELECT oid
                       FROM pg_roles
                       WHERE rolsuper IS true
                         AND rolcanlogin IS true
                         AND rolreplication IS false
                         AND rolbypassrls IS false) AS role
                      ON role.oid = pg_proc.proowner
                 JOIN (SELECT typname, oid FROM pg_type) AS tn ON tn.oid = pg_proc.prorettype
        WHERE prorettype::varchar ~ '^[0-9]+$'
          AND tn.typname NOT LIKE 'void'
          AND proargtypes::varchar ~ '^[0-9]+$'
    );
    SELECT COUNT(functions.output) INTO counter FROM functions;

    SELECT array_to_string(array_agg(output), E'\n') INTO result_text FROM functions;
    RAISE NOTICE 'Функции: %', result_text::text;
END
$$
    LANGUAGE plpgsql;

-- DO $$
--     DECLARE
--         count_result bigint;
--     BEGIN
--         CALL count_of_scal_functions(count_result);
--         RAISE NOTICE 'Результат процедуры: %', count_result;
--     END;
-- $$;


-- 3)

CREATE OR REPLACE PROCEDURE drop_dml_triggers(out counter bigint)
AS
$$
DECLARE
    name_of_trigger varchar;
    name_of_table   varchar;
BEGIN
    counter := 0;
    RAISE NOTICE 'Удалённые триггеры:';
    FOR name_of_trigger, name_of_table IN (SELECT tgname, pgc.relname
                                           FROM pg_trigger -- таблица триггеров
                                                    JOIN (SELECT oid, relname FROM pg_class) AS pgc -- таблица с названиями таблиц
                                                         ON pg_trigger.tgrelid = pgc.oid
                                           WHERE tgisinternal IS false)
        LOOP
            EXECUTE 'DROP TRIGGER IF EXISTS ' || quote_ident(name_of_trigger) || ' ON ' || quote_ident(name_of_table) ||
                    ' CASCADE';
            RAISE NOTICE '%', name_of_trigger::text;
            counter := counter + 1;
        END LOOP;
    RAISE NOTICE 'Количество удалённых триггеров: %', counter::text;
END;
$$
    LANGUAGE plpgsql;

-- DO $$
--     DECLARE
--         count_result bigint;
--     BEGIN
--         CALL drop_dml_triggers(count_result);
--     END;
-- $$;

-- 4)

CREATE OR REPLACE PROCEDURE name_and_discript_of_objects(in substroke varchar, INOUT result_cursor refcursor)
AS
$$
BEGIN
    OPEN result_cursor FOR
        SELECT proname, pg_description.description
        FROM pg_proc
                 LEFT JOIN pg_description ON pg_proc.oid = pg_description.objoid
        WHERE ((prorettype::varchar ~ '^[0-9]+$' AND
                proargtypes::varchar ~ '^[0-9]+$' AND
                prokind = 'f') OR prokind = 'p')
          AND prosrc LIKE '%' || substroke || '%';
END;
$$
    language plpgsql;

-- BEGIN;
--     CALL name_and_discript_of_objects('SELECT', 'cursor');
--     FETCH ALL FROM "cursor";
--     CLOSE "cursor";
-- END
