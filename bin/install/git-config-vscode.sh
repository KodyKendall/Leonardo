#!/bin/bash
set -e
docker compose exec -it code bash git config user.name "leonardo" 
docker compose exec -it code bash git config user.email "leonardo@llamapress.ai"