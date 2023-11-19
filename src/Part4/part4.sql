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
            EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(table_name) || ' CASCADE'; -- удаляем, quote_ident для нормальной вставки переменной в команду
        END LOOP;
END;
$$
    LANGUAGE plpgsql;

-- CREATE TABLE proverka();
-- BEGIN;
--  CALL drop_tablename_tables('t');
-- END;

-- 2)

create
    or replace procedure prcdr_funcs_with_arguments(
    func out text,
    numb out int
) as
$$
declare
    line record;
begin
    func
        := '';
    numb
        := 0;
    for line in
        select (
                   p.proname || ' (' || pg_get_function_arguments(p.oid) || ')'
                   ) as functions_list
        from pg_catalog.pg_namespace n
                 join pg_catalog.pg_proc p on p.pronamespace = n.oid
        where p.prokind = 'f'
          and n.nspname = 'public'
          and (pg_get_function_arguments(p.oid) = '') is not true
        loop
            func := (func || line.functions_list || E'\n');
            numb
                := numb + 1;
        end loop;
end;
$$
    language plpgsql;

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
