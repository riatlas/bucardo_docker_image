set -euo pipefail

# Example script
# the script combine bucardo commands and psql 


echo "create test db"
createdb test1 
createdb test2 

echo "run pgbench"
pgbench -i test1 
pgbench -i test2 

# create a table without a primary key
for db in "test1" "test2"; do
  psql -d $db -At <<EOF
  CREATE TABLE "test_me" (
    id serial NOT NULL,
    text varchar(255) NULL
  );
EOF
done


# add databases
echo "add databases"
bucardo add database test1 dbname=test1 dbuser=postgres
bucardo add database test2 dbname=test2 dbuser=postgres

# create primary key for tables that do not have it
for db in "test1" "test2"; do
  echo "DATABASE: $db" 
  T_TABLES=($(psql -v ON_ERROR_STOP=1 -d $db -At --csv <<EOF | awk -F, '{print $1"."$2}' 
  select tbl.table_schema, 
        tbl.table_name
  from information_schema.tables tbl
  where table_type = 'BASE TABLE'
    and table_schema not in ('pg_catalog', 'information_schema')
    and not exists (select 1 
                    from information_schema.key_column_usage kcu
                    where kcu.table_name = tbl.table_name 
                      and kcu.table_schema = tbl.table_schema)
EOF
  ))

  for i in "${T_TABLES[@]}"; do
    psql -v ON_ERROR_STOP=1 -d $db -At <<EOF
      ALTER TABLE $i ADD COLUMN __PK__ SERIAL PRIMARY KEY;
EOF
  done
done

# test
# psql -v ON_ERROR_STOP=1 -d test1 -At <<EOF
# ALTER TABLE pgbench_history DROP COLUMN __PK__;
# EOF

# add tables
echo "add tables to bucardo"
bucardo add all tables db=test1 --relgroup=pgbench --verbose 
# add sequences (if any)
bucardo add all sequences db=test1 

# add the syncs
echo "add syncs to bucardo"
bucardo add sync benchdelta relgroup=pgbench dbs=test1,test2 onetimecopy=1 

# truncate tabla table to show the replication
psql -v ON_ERROR_STOP=1 -d test2 -At <<EOF
truncate pgbench_accounts;
EOF

# start bucardo
echo "start bucardo"
bucardo start

# check status
sleep 5
T1=$(psql -v ON_ERROR_STOP=1 -d test1 -At -c 'select count(*) from pgbench_accounts')
T2=$(psql -v ON_ERROR_STOP=1 -d test2 -At -c 'select count(*) from pgbench_accounts')

echo "T1=$T1, T2=$T2"
echo "Test replication successful comparing the pgbench_accounts tables"
[ "$T1" == "$T2" ] && {
  echo "Sync Successful"
} || {
  echo "Sync Failed"
}
