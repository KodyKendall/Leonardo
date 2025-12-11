docker exec -it leonardo-db-1 \
  psql -U postgres -d llamapress_production \
  -c "TRUNCATE TABLE checkpoints, checkpoint_writes, checkpoint_migrations, checkpoint_blobs RESTART IDENTITY CASCADE;"

