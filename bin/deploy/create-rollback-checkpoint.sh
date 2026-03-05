#!/bin/bash

# @Michaela If it goes bad and you need to roll back: 
# 1. run this command: `docker compose exec -it llamapress bundle exec rails db:migrate VERSION=20260224231745`
# 2. Then run: `git stash && git checkout stable-checkpoint-20260305-043122`
# 3. Then click the “Pull Update” button which will restart the Rails & LlamaBot app.

# Generate a timestamp for the branch name
DATE=$(date +%Y%m%d%H%M%S)
BRANCH_NAME="stable-checkpoint-$DATE"

echo "Creating stable checkpoint: $BRANCH_NAME..."

# 1. Create and switch to the new checkpoint branch
git checkout -b $BRANCH_NAME

# 2. Extract the exact database version from the running Rails container
# `rails db:version` outputs "Current version: 20231012123456". The grep command isolates the numbers.
DB_VERSION=$(docker exec llamapress bundle exec rails db:version | grep -oE '[0-9]+')

if [ -z "$DB_VERSION" ]; then
  echo "Error: Could not retrieve database version from llamapress container."
  exit 1
fi

echo "Captured stable database version: $DB_VERSION"

# 3. Save the timestamp to a file
echo $DB_VERSION > .last_stable_db_version

# 4. Commit this file purely to the checkpoint branch
git add .last_stable_db_version
git commit -m "chore: snapshot stable db version $DB_VERSION"

# 5. Push the checkpoint branch to GitHub
git push -u origin $BRANCH_NAME

# 6. Switch back to your deployment branch (assuming 'main') so you can continue the deploy
git checkout main

echo "Checkpoint saved successfully!"

