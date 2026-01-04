docker compose exec -it db \
  psql -U postgres -d llamapress_production \
  -c "TRUNCATE TABLE checkpoints, checkpoint_writes, checkpoint_migrations, checkpoint_blobs RESTART IDENTITY CASCADE;"
