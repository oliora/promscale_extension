\pset pager off

select version();

\drds
\du+
\l
\dn+
\dx
\dx+ promscale
\ddp

-- dynamically generate meta commands to describe schemas
select format('%s %s', c.c, s.s)
from unnest(array
[ 'public'
, '_prom_catalog'
, '_prom_ext'
, '_ps_catalog'
, '_ps_trace'
, 'prom_api'
, 'prom_data'
, 'prom_data_exemplar'
, 'prom_data_series'
, 'prom_info'
, 'prom_metric'
, 'prom_series'
, 'ps_tag'
, 'ps_trace'
, '_timescaledb_cache'
, '_timescaledb_catalog'
, '_timescaledb_config'
, '_timescaledb_internal'
, 'timescaledb_experimental'
, 'timescaledb_information'
]) s(s)
cross join unnest(array
[ '\dp+'
, '\ddp'
]) c(c)
order by c.c, s.s
\g (tuples_only=on format=csv) describe_schemas.sql
\i describe_schemas.sql

-- dynamically generate meta commands to describe objects in the schemas
select format('%s %s', c.c, s.s)
from unnest(array
[ 'public.*'
, '_prom_catalog.*'
, '_prom_ext.*'
, '_ps_catalog.*'
, '_ps_trace.*'
, 'prom_api.*'
, 'prom_data.*'
, 'prom_data_exemplar.*'
, 'prom_data_series.*'
, 'prom_info.*'
, 'prom_metric.*'
, 'prom_series.*'
, 'ps_tag.*'
, 'ps_trace.*'
, '_timescaledb_cache.*'
, '_timescaledb_catalog.*'
, '_timescaledb_config.*'
, '_timescaledb_internal.*'
, 'timescaledb_experimental.*'
, 'timescaledb_information.*'
]) s(s)
cross join unnest(array
[ '\d+'
, '\df+'
, '\dp+'
, '\di'
, '\dy'
, '\do'
, '\dT'
, '\dS+'
]) c(c)
order by c.c, s.s
\g (tuples_only=on format=csv) describe_objects.sql
\i describe_objects.sql

-- snapshot the data from all the tables
select
    format($$select '%I.%I' as table_snapshot;$$, n.nspname, k.relname),
    case
        -- we don't care about comparing the applied_at_version and applied_at columns of the migration table
        when n.nspname = '_ps_catalog'::name and k.relname = 'migration'::name
            then 'select name, body from _ps_catalog.migration order by name, body;'
        when n.nspname = '_timescaledb_internal' and (k.relname like '_compressed_hypertable_%' or k.relname like 'compress_hyper_%_chunk')
            -- cannot order by tbl on compressed hypertables
            then format('select * from %I.%I', n.nspname, k.relname)
        else format('select * from %I.%I tbl order by tbl;', n.nspname, k.relname)
    end
from pg_namespace n
inner join pg_class k on (n.oid = k.relnamespace)
where k.relkind in ('r', 'p')
and n.nspname in
( 'public'
, '_prom_catalog'
, '_prom_ext'
, '_ps_catalog'
, '_ps_trace'
, 'prom_api'
, 'prom_data'
, 'prom_data_exemplar'
, 'prom_data_series'
, 'prom_info'
, 'prom_metric'
, 'prom_series'
, 'ps_tag'
, 'ps_trace'
, '_timescaledb_cache'
, '_timescaledb_catalog'
, '_timescaledb_config'
, '_timescaledb_internal'
, 'timescaledb_experimental'
, 'timescaledb_information'
)
and (n.nspname, k.relname) not in
(
    ('_timescaledb_internal', 'bgw_job_stat'),
    ('_timescaledb_catalog', 'metadata')
)
order by n.nspname, k.relname
\gexec