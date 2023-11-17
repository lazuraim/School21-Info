-- 1)

create
    or replace procedure prcdr_drop_tables_started_TableName() as
$$
declare
    rec record;
begin
    for rec in
        select tablename
        from pg_catalog.pg_tables
        where schemaname != 'pg_catalog'
          and schemaname != 'information_schema'
          and tablename ~* '^TableName'
        loop
            execute 'drop table ' || quote_ident(rec.tablename);
            raise
                info 'Dropped table: %', quote_ident(rec.tablename);
        end loop;
end;
$$
    language plpgsql;

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

create or replace procedure prcdr_destroy_DML_triggers(num out int)
AS
$$
declare
    i record;
begin
    num := 0;
    for i in
        select *
        from information_schema.triggers
        where event_manipulation in ('DELETE', 'UPDATE', 'INSERT')
        loop
            execute 'drop trigger ' || i.trigger_name || ' on '
                        || i.event_object_table || ' cascade';
            num := num + 1;
        end loop;
end;
$$
    language plpgsql;

-- 4)

create
    or replace procedure prcdr_find_objects_by_text(
    sub in text,
    list out text
) as
$$
declare
    i record;
begin
    list
        := '';
    for i in
        select routine_name as name,
               'procedure'  as object_type
        from information_schema.routines
        where routine_type = 'PROCEDURE'
          and routine_name ~ sub
        union all
        select proname    as name,
               'function' as object_type
        from pg_catalog.pg_namespace n
                 join pg_catalog.pg_proc p on p.pronamespace = n.oid
        where p.prokind = 'f'
          and n.nspname = 'public'
          and proname ~ sub
        loop
            list := (list || i.name || ' [type -> '
                         || i.object_type || ']' || E'\n');
        end loop;
end;
$$
    language plpgsql;


do
$$
    declare
        result refcursor = 'dad';
    begin
        open result for call prcdr_funcs_with_arguments();
    end
$$;
fetch all in "generated_result_cursor";
close "generated_result_cursor";
