#!/bin/bash
set -e

# Master restore script - runs all restore steps in correct order
# Usage: ./master_restore_all.sh <instance_name> <s3_bucket_path>
# Example: ./master_restore_all.sh LP-Test5 s3://llampress-ai-backups/backups/leonardos/LP-Test5

INSTANCE_NAME="$1"
S3_BUCKET="$2"

if [ -z "$INSTANCE_NAME" ] || [ -z "$S3_BUCKET" ]; then
    echo "Usage: $0 <instance_name> <s3_bucket_path>"
    echo "Example: $0 LP-Test5 s3://llampress-ai-backups/backups/leonardos/LP-Test5"
    exit 1
fi

# ─── Resolve which backup to restore from ──────────────────────────────────
# Two pointers can exist independently:
#   ${S3}/latest-backup.txt           → full backup timestamp (master_backup_all.sh)
#   ${S3}/latest/last-quick-backup.txt → quick backup timestamp (quick_backup.sh)
# Both are "YYYYMMDD-HHMMSS" strings, so lexical compare = chronological.
echo "🔍 Checking for existing backups..."
FULL_TS=$(aws s3 cp "${S3_BUCKET}/latest-backup.txt" - 2>/dev/null | tr -d '[:space:]' || true)
QUICK_TS=$(aws s3 cp "${S3_BUCKET}/latest/last-quick-backup.txt" - 2>/dev/null | tr -d '[:space:]' || true)

# MODE: none | full | quick | hybrid
if [ -z "$FULL_TS" ] && [ -z "$QUICK_TS" ]; then
    MODE="none"
elif [ -n "$FULL_TS" ] && [ -z "$QUICK_TS" ]; then
    MODE="full"
elif [ -z "$FULL_TS" ] && [ -n "$QUICK_TS" ]; then
    MODE="quick"
elif [[ "$QUICK_TS" > "$FULL_TS" ]]; then
    MODE="hybrid"
else
    MODE="full"
fi

if [ "$MODE" = "none" ]; then
    echo "════════════════════════════════════════════════════════════"
    echo "🆕 NEW INSTANCE DETECTED"
    echo "════════════════════════════════════════════════════════════"
    echo "📍 Instance: ${INSTANCE_NAME}"
    echo "📍 S3 Path: ${S3_BUCKET}"
    echo ""
    echo "ℹ️  No full or quick backup pointers found - this is a brand new instance"
    echo "✅ Skipping restore - instance will use fresh Leonardo installation"
    echo ""
    echo "🎉 Instance is ready to use!"
    echo "════════════════════════════════════════════════════════════"
    exit 0
fi

echo "════════════════════════════════════════════════════════════"
echo "🚀 MASTER RESTORE: ${INSTANCE_NAME}"
echo "════════════════════════════════════════════════════════════"
echo "📍 S3 Bucket: ${S3_BUCKET}"
echo "📍 Mode:      ${MODE}"
echo "📍 Full TS:   ${FULL_TS:-<none>}"
echo "📍 Quick TS:  ${QUICK_TS:-<none>}"
echo "⏱️  Start time: $(date)"
echo ""
MASTER_START=$(date +%s)

# ─── Helpers ──────────────────────────────────────────────────────────────
wait_for_postgres() {
    local timeout="${1:-30}"
    local elapsed=0
    until docker compose exec -T db pg_isready -U postgres > /dev/null 2>&1; do
        if [ $elapsed -ge $timeout ]; then
            echo "   ❌ Postgres failed to become ready within ${timeout}s"
            return 1
        fi
        sleep 1
        elapsed=$((elapsed + 1))
    done
    return 0
}

align_postgres_password() {
    # Sets the postgres role password to match POSTGRES_PASSWORD in ./.env.
    # Uses local socket auth inside the container (trust), so no current password needed.
    local new_password
    new_password=$(grep "^POSTGRES_PASSWORD=" .env | cut -d= -f2-)
    if [ -z "$new_password" ]; then
        echo "   ❌ POSTGRES_PASSWORD not found in .env"
        return 1
    fi
    docker compose exec -T db psql -U postgres -c \
        "ALTER USER postgres PASSWORD '$new_password';" > /dev/null 2>&1
    if docker compose exec -T db env PGPASSWORD="$new_password" \
        psql -U postgres -c "SELECT 1" > /dev/null 2>&1; then
        echo "   ✓ Password aligned with .env"
        return 0
    else
        echo "   ❌ Password alignment failed"
        return 1
    fi
}

load_quick_postgres_dump() {
    # Streams the quick-backup pg_dumpall through gunzip into psql.
    # pg_dumpall has no DROP statements, so callers must ensure the target
    # databases don't exist (fresh cluster, or DROP DATABASE first).
    aws s3 cp "${S3_BUCKET}/latest/postgres-${INSTANCE_NAME}.sql.gz" - --only-show-errors \
        | gunzip \
        | docker compose exec -T db psql -U postgres --quiet -f -
}

drop_user_databases() {
    # Drop every non-template, non-postgres database so the quick dump can recreate them.
    docker compose exec -T db psql -U postgres -d postgres -tAc \
        "SELECT datname FROM pg_database WHERE datistemplate = false AND datname <> 'postgres';" \
        | tr -d '\r' \
        | while read -r dbname; do
            [ -z "$dbname" ] && continue
            echo "   🗑  Dropping database: $dbname"
            docker compose exec -T db psql -U postgres -d postgres -c \
                "DROP DATABASE IF EXISTS \"$dbname\" WITH (FORCE);" > /dev/null 2>&1
        done
}

# ─── STEP 1: Restore project files ────────────────────────────────────────
# Always runs (both full and quick backups carry project files).
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 STEP 1: Restore Project Files"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd ~
rm -rf Leonardo llamapress 2>/dev/null || true

# Bootstrap: pull latest scripts from S3 into a temporary location so they
# survive the project-files restore (which lays down its own bin/backups/cloud).
mkdir -p Leonardo/bin/backups/cloud
cd Leonardo
aws s3 sync s3://llampress-ai-backups/proprietary-scripts/ bin/backups/cloud/ --exclude "*" --include "*.sh" --quiet
chmod +x bin/backups/cloud/*.sh

if [ "$MODE" = "quick" ]; then
    # Quick-only: sync directly into ~/Leonardo
    ./bin/backups/cloud/8_restore_project_files_from_s3.sh \
        "${INSTANCE_NAME}" \
        "${S3_BUCKET}" \
        /home/ubuntu \
        quick
else
    # full or hybrid: extract tarball, normalize folder name to Leonardo
    ./bin/backups/cloud/8_restore_project_files_from_s3.sh \
        "${INSTANCE_NAME}" \
        "${S3_BUCKET}" \
        /home/ubuntu \
        full

    cd ~
    if [ -d "llamapress" ]; then
        rm -rf Leonardo
        mv llamapress Leonardo
    fi
fi

cd ~/Leonardo
echo "✅ Step 1 complete"
echo ""

# ─── QUICK-ONLY PATH ──────────────────────────────────────────────────────
if [ "$MODE" = "quick" ]; then
    echo "⚠️  ════════════════════════════════════════════════════════"
    echo "⚠️   QUICK-ONLY RESTORE"
    echo "⚠️  ════════════════════════════════════════════════════════"
    echo "⚠️   No full backup pointer found. Restoring postgres + project"
    echo "⚠️   files only. The following are NOT restored:"
    echo "⚠️     • Docker volumes (e.g. ActiveStorage on disk)"
    echo "⚠️     • System configs (Caddyfile, SSL certs)"
    echo "⚠️   Run /backup or /install-cron once stable to enable full restore."
    echo "⚠️  ════════════════════════════════════════════════════════"
    echo ""

    # Ensure clean postgres state — wipe any stale volume from prior partial runs
    echo "📦 STEP 2 (quick): Prepare Fresh Postgres"
    docker compose down 2>/dev/null || true
    PG_VOLUME=$(docker volume ls --format '{{.Name}}' | grep -E '(_|^)postgres_data$' | head -n 1)
    if [ -n "$PG_VOLUME" ]; then
        echo "   🗑  Removing stale postgres volume: $PG_VOLUME"
        docker volume rm "$PG_VOLUME" > /dev/null 2>&1 || true
    fi

    echo "🚀 Starting postgres (fresh volume)..."
    docker compose up -d db
    echo "⏳ Waiting for postgres..."
    wait_for_postgres 60 || exit 1
    echo "   ✓ Postgres is ready"

    echo "📥 Loading quick postgres dump (timestamp ${QUICK_TS})..."
    load_quick_postgres_dump
    echo "   ✓ Database loaded"

    echo "🔐 Aligning postgres password with .env..."
    align_postgres_password || exit 1

    echo ""
    echo "🚀 Starting all services..."
    docker compose up -d
    echo "✅ Quick-only restore complete"
    echo ""

# ─── FULL or HYBRID PATH ──────────────────────────────────────────────────
else
    # STEP 2: Restore Docker Volumes (includes postgres_data at FULL_TS)
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 STEP 2: Restore Docker Volumes"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    docker compose down

    ./bin/backups/cloud/9_restore_docker_volumes_from_s3.sh \
        "${INSTANCE_NAME}" \
        "${S3_BUCKET}"
    echo "✅ Step 2 complete"
    echo ""

    # STEP 3: Fix Postgres Password Mismatch
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 STEP 3: Fix Postgres Password"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🚀 Starting postgres with OLD password (from restored volume)..."
    docker compose up -d db
    echo "⏳ Waiting for postgres..."
    wait_for_postgres 30 || exit 1
    echo "   ✓ Postgres is ready"

    echo "🔐 Updating postgres password to match .env..."
    align_postgres_password || exit 1

    echo "🔄 Restarting postgres + redis..."
    docker compose down
    docker compose up -d db redis
    echo "⏳ Waiting for postgres..."
    wait_for_postgres 30 || exit 1
    echo "   ✓ Postgres restarted with new password"
    echo "✅ Step 3 complete"
    echo ""

    # STEP 4: Restore system configs (SSL certs, Caddyfile, etc.)
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 STEP 4: Restore System Configs & SSL Certificates"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    sudo ./bin/backups/cloud/7_restore_system_configs_from_s3.sh \
        "${INSTANCE_NAME}" \
        "${S3_BUCKET}"

    echo "🔄 Reloading Caddy..."
    sudo systemctl reload caddy
    echo "✅ Step 4 complete"
    echo ""

    # STEP 5 (hybrid only): Overlay quick backup on top of full
    if [ "$MODE" = "hybrid" ]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📦 STEP 5: Overlay Quick Backup (QUICK ${QUICK_TS} > FULL ${FULL_TS})"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        # Overlay project files (no --delete: preserves .git, node_modules, etc.
        # that the tarball restored but quick_backup.sh excludes)
        ./bin/backups/cloud/8_restore_project_files_from_s3.sh \
            "${INSTANCE_NAME}" \
            "${S3_BUCKET}" \
            /home/ubuntu \
            quick

        # Replace postgres data with quick dump.
        # Postgres is already running from Step 3 with the .env password aligned.
        # pg_dumpall has no DROP statements, so we drop user databases first.
        echo "🗑  Dropping FULL_TS user databases before loading QUICK dump..."
        drop_user_databases

        echo "📥 Loading quick postgres dump (timestamp ${QUICK_TS})..."
        load_quick_postgres_dump
        echo "   ✓ Database loaded"

        # The dump's ALTER ROLE postgres may have reset the password to the
        # backup-time value. Realign with current .env.
        echo "🔐 Realigning postgres password with .env..."
        align_postgres_password || exit 1

        echo "✅ Step 5 complete"
        echo ""
    fi

    # Final start
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 Start All Services"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null)
    IPADDRESS=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null)
    echo "📍 Public IP: ${IPADDRESS}"
    echo "🌐 DNS already configured by orchestrator"
    echo ""
    echo "🚀 Starting all services..."
    docker compose up -d
    echo ""
fi

# ─── Final summary ────────────────────────────────────────────────────────
MASTER_END=$(date +%s)
MASTER_DURATION=$((MASTER_END - MASTER_START))

echo "════════════════════════════════════════════════════════════"
echo "✅ RESTORE COMPLETE! (mode=${MODE})"
echo "════════════════════════════════════════════════════════════"
echo "⏱️  Total time: ${MASTER_DURATION} seconds"
echo "⏱️  End time: $(date)"
echo ""
echo "🌐 Your instance is available at:"
echo "   - https://${INSTANCE_NAME}.llamapress.ai"
echo "   - https://rails-${INSTANCE_NAME}.llamapress.ai"
echo "   - https://vscode-${INSTANCE_NAME}.llamapress.ai"
echo ""
echo "📊 Check service status:"
echo "   docker compose ps"
echo ""
echo "📋 View logs:"
echo "   docker compose logs -f"
echo "════════════════════════════════════════════════════════════"
