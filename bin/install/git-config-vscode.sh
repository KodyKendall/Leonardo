#!/bin/bash
set -e
docker compose exec -it code git config --global user.name "leonardo"
docker compose exec -it code git config --global user.email "leonardo@llamapress.ai"