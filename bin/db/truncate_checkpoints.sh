TABLES="checkpoints, checkpoint_writes, checkpoint_migrations, checkpoint_blobs"
SIZE_QUERY="SELECT coalesce(sum(pg_total_relation_size(table_name::regclass)) / 1024.0 / 1024.0, 0) AS size_mb FROM unnest(ARRAY['checkpoints','checkpoint_writes','checkpoint_migrations','checkpoint_blobs']) AS table_name;"

for DB in llamapress_production llamabot_production; do
  echo "=== $DB ==="

  echo "Size before truncation:"
  docker compose exec -T db psql -U postgres -d "$DB" -c "$SIZE_QUERY"

  docker compose exec -T db psql -U postgres -d "$DB" \
    -c "TRUNCATE TABLE $TABLES RESTART IDENTITY CASCADE;"

  echo "Size after truncation:"
  docker compose exec -T db psql -U postgres -d "$DB" -c "$SIZE_QUERY"

  echo ""
done
