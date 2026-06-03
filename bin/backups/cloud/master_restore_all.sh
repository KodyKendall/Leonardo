#!/bin/bash
# Master restore script — runs all restore steps in correct order.
# Designed to be resilient: individual steps retry on failure,
# and non-critical failures don't abort the whole restore.
#
# Usage: ./master_restore_all.sh <instance_name> <s3_bucket_path>
# Example: ./master_restore_all.sh LP-Test5 s3://llampress-ai-backups/backups/leonardos/LP-Test5
#
# Restore source selection (auto-detected from S3 pointer files):
#   ${S3}/latest-backup.txt            → full backup timestamp (master_backup_all.sh)
#   ${S3}/latest/last-quick-backup.txt → quick backup timestamp (quick_backup.sh)
# Modes:
#   none   → neither pointer exists; treat as new instance, exit 0
#   full   → only full pointer, OR full ≥ quick: restore from timestamped folder
#   quick  → only quick pointer: project-files sync + postgres dump (lossy:
#            no docker volumes, no system configs)
#   hybrid → both, quick newer: full restore at FULL_TS, then overlay quick
#            project-files + postgres dump on top (preserves volumes & sys configs)

INSTANCE_NAME="$1"
S3_BUCKET="$2"

if [ -z "$INSTANCE_NAME" ] || [ -z "$S3_BUCKET" ]; then
    echo "Usage: $0 <instance_name> <s3_bucket_path>"
    echo "Example: $0 LP-Test5 s3://llampress-ai-backups/backups/leonardos/LP-Test5"
    exit 1
fi

# ─── Helpers ──────────────────────────────────────────────────────────────

# Wait for postgres to accept connections.
# Uses TCP (-h 127.0.0.1) instead of unix socket. The official postgres image
# runs a socket-only init phase on a fresh volume that pg_isready-via-socket
# reports as "ready", but the init phase then `pg_ctl stop`s and re-execs into
# the real production postgres — killing any client connection with "FATAL:
# terminating connection due to administrator command". TCP is only opened in
# the production phase, so it's a reliable readiness signal in all cases.
wait_for_postgres() {
    local timeout="${1:-60}"
    local elapsed=0
    echo -n "   Waiting for postgres"
    until docker compose exec -T db pg_isready -h 127.0.0.1 -U postgres > /dev/null 2>&1; do
        if [ $elapsed -ge $timeout ]; then
            echo " TIMEOUT (pg_isready TCP)"
            return 1
        fi
        echo -n "."
        sleep 1
        elapsed=$((elapsed + 1))
    done
    # Belt + suspenders: also verify a real query works
    until docker compose exec -T db psql -U postgres -c "SELECT 1" > /dev/null 2>&1; do
        if [ $elapsed -ge $timeout ]; then
            echo " TIMEOUT (query test)"
            return 1
        fi
        echo -n "."
        sleep 1
        elapsed=$((elapsed + 1))
    done
    echo " ready (${elapsed}s)"
    return 0
}

full_docker_down() {
    docker compose down --remove-orphans --timeout 10 2>/dev/null || true
    sleep 2
}

# Set the postgres role's password to match POSTGRES_PASSWORD in ./.env.
# Uses local socket auth inside the container (trust), so no current password needed.
align_postgres_password() {
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
        echo "   ❌ Password alignment verification failed"
        return 1
    fi
}

# Load postgres dumps from quick backup. Backwards-compatible across three S3 layouts:
#   1. latest/{db}-{INSTANCE}.sql.gz       — current quick_backup.sh (per-db pg_dump)
#   2. latest/postgres-{INSTANCE}.sql.gz   — legacy pg_dumpall (most existing instances)
#   3. {db}_latest.sql.gz                  — backup_s3.sh / cron (per-db at S3 root)
load_quick_postgres_dump() {
    local ok=true

    # ── Strategy 1: per-database dumps in latest/ (current quick_backup.sh format)
    local found_per_db=false
    for db in llamapress_production llamabot_production; do
        local dump_url="${S3_BUCKET}/latest/${db}-${INSTANCE_NAME}.sql.gz"
        if aws s3 ls "$dump_url" > /dev/null 2>&1; then
            found_per_db=true
            echo "   Loading ${db} (per-db format)..."
            docker compose exec -T db psql -U postgres -tc \
                "SELECT 1 FROM pg_database WHERE datname='${db}'" | grep -q 1 \
                || docker compose exec -T db psql -U postgres -c "CREATE DATABASE \"${db}\";" 2>/dev/null
            if ! aws s3 cp "$dump_url" - --only-show-errors \
                | gunzip \
                | docker compose exec -T db psql -U postgres -d "$db" --quiet -f -; then
                echo "   ⚠️  Failed to load ${db}"
                ok=false
            fi
        fi
    done

    if [ "$found_per_db" = true ]; then
        $ok
        return
    fi

    # ── Strategy 2: pg_dumpall in latest/ (legacy format — what most instances have)
    local dumpall_url="${S3_BUCKET}/latest/postgres-${INSTANCE_NAME}.sql.gz"
    if aws s3 ls "$dumpall_url" > /dev/null 2>&1; then
        echo "   Loading pg_dumpall from ${dumpall_url} (legacy format)..."
        if aws s3 cp "$dumpall_url" - --only-show-errors \
            | gunzip \
            | docker compose exec -T db psql -U postgres --quiet -f -; then
            echo "   ✓ pg_dumpall loaded"
            return 0
        else
            echo "   ⚠️  pg_dumpall load failed"
            return 1
        fi
    fi

    # ── Strategy 3: per-database dumps at S3 root (backup_s3.sh / cron format)
    local found_root_db=false
    for db in llamapress_production llamabot_production; do
        local dump_url="${S3_BUCKET}/${db}_latest.sql.gz"
        if aws s3 ls "$dump_url" > /dev/null 2>&1; then
            found_root_db=true
            echo "   Loading ${db} (root-level format)..."
            docker compose exec -T db psql -U postgres -tc \
                "SELECT 1 FROM pg_database WHERE datname='${db}'" | grep -q 1 \
                || docker compose exec -T db psql -U postgres -c "CREATE DATABASE \"${db}\";" 2>/dev/null
            if ! aws s3 cp "$dump_url" - --only-show-errors \
                | gunzip \
                | docker compose exec -T db psql -U postgres -d "$db" --quiet -f -; then
                echo "   ⚠️  Failed to load ${db}"
                ok=false
            fi
        fi
    done

    if [ "$found_root_db" = true ]; then
        $ok
        return
    fi

    echo "   ⚠️  No postgres dumps found in any known format under ${S3_BUCKET}"
    return 1
}

# Load the pg_dumpall from a full (timestamped) backup.
load_full_postgres_dump() {
    local dump_url="${S3_BUCKET}/${FULL_TS}/postgres-${INSTANCE_NAME}-${FULL_TS}.sql.gz"
    if aws s3 ls "$dump_url" > /dev/null 2>&1; then
        echo "   Loading pg_dumpall from ${dump_url}..."
        aws s3 cp "$dump_url" - --only-show-errors \
            | gunzip \
            | docker compose exec -T db psql -U postgres --quiet -f -
    else
        echo "   ⚠️  Full dump not found at ${dump_url}"
        return 1
    fi
}

# Drop every non-template, non-postgres database so the quick dump can recreate them.
# Used in hybrid mode to clear the FULL_TS data before loading QUICK_TS dump.
drop_user_databases() {
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

# ─── Resolve restore mode from pointer files ──────────────────────────────
echo "🔍 Checking for existing backups..."
FULL_TS=$(aws s3 cp "${S3_BUCKET}/latest-backup.txt" - 2>/dev/null | tr -d '[:space:]' || true)
QUICK_TS=$(aws s3 cp "${S3_BUCKET}/latest/last-quick-backup.txt" - 2>/dev/null | tr -d '[:space:]' || true)

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
ERRORS=""

# ─── STEP 1: Restore project files ────────────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 STEP 1: Restore Project Files"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd ~

# Preserve .ssh-shared before wiping Leonardo — the golden image bakes in a
# shared LXD jump key that the VSCode SSH setup script needs. The backup
# predates this key, so restoring would lose it.
if [ -d "Leonardo/.ssh-shared" ]; then
    cp -a Leonardo/.ssh-shared /tmp/.ssh-shared-preserve
fi

# Preserve target instance identity before wipe. The backup's .env carries the
# SOURCE instance's identity/creds — restoring it would point this instance at
# the wrong S3 path, mothership token, AWS creds, LXD host, etc. We splice
# select identity keys back from this snapshot after the tarball is restored.
cp /home/ubuntu/Leonardo/.env /tmp/.env.pre-restore 2>/dev/null || true

rm -rf Leonardo llamapress 2>/dev/null || true

# Bootstrap: pull latest scripts so they survive the project-files restore
mkdir -p Leonardo/bin/backups/cloud
cd Leonardo
aws s3 sync s3://llampress-ai-backups/proprietary-scripts/ bin/backups/cloud/ --exclude "*" --include "*.sh" --quiet
chmod +x bin/backups/cloud/*.sh

if [ "$MODE" = "quick" ]; then
    if ./bin/backups/cloud/8_restore_project_files_from_s3.sh \
        "${INSTANCE_NAME}" "${S3_BUCKET}" /home/ubuntu quick; then
        echo "✅ Step 1 complete (quick sync)"
    else
        echo "❌ Step 1 FAILED — project files quick-sync failed"
        exit 1
    fi
else
    if ./bin/backups/cloud/8_restore_project_files_from_s3.sh \
        "${INSTANCE_NAME}" "${S3_BUCKET}" /home/ubuntu full; then
        echo "✅ Step 1 complete (tarball)"
    else
        echo "❌ Step 1 FAILED — project files tarball restore failed"
        exit 1
    fi

    # Normalize folder name to Leonardo
    cd ~
    if [ -d "llamapress" ]; then
        rm -rf Leonardo
        mv llamapress Leonardo
    fi
fi

cd ~/Leonardo

# Restore .ssh-shared if it was preserved before the wipe
if [ -d "/tmp/.ssh-shared-preserve" ]; then
    cp -a /tmp/.ssh-shared-preserve .ssh-shared
    rm -rf /tmp/.ssh-shared-preserve
    echo "   ✓ Restored .ssh-shared (LXD jump key)"
fi

# Splice target instance identity back into .env. The tarball restore just
# overwrote .env with the SOURCE instance's values; here we put back the keys
# that define THIS instance (S3 path, mothership token, AWS creds, LXD host,
# etc.). Done before any later step reads .env so services start with the
# correct identity. POSTGRES_PASSWORD is intentionally excluded — the later
# postgres password-alignment step will sync the running DB with the source's
# password from the restored .env.
if [ -f /tmp/.env.pre-restore ]; then
    echo "🔐 Splicing target instance identity back into .env..."
    IDENTITY_KEYS=(
        INSTANCE_NAME
        S3_BUCKET_PATH
        HOSTED_DOMAIN
        FULL_HOSTED_DOMAIN
        MOTHERSHIP_API_TOKEN
        MOTHERSHIP_INSTANCE_NAME
        MOTHERSHIP_URL
        AWS_ACCESS_KEY_ID
        AWS_SECRET_ACCESS_KEY
        AWS_DEFAULT_REGION
        LXD_HOST_IP
        LXD_HOST_PORT
        LXD_HOST_USER
        LEONARDO_IP
        VSCODE_PASSWORD
        SECRET_KEY_BASE
        LLAMAPRESS_AI_LOGIN_SECRET
    )

    for key in "${IDENTITY_KEYS[@]}"; do
        val=$(grep "^${key}=" /tmp/.env.pre-restore | head -1 | cut -d= -f2-)
        if [ -n "$val" ]; then
            if grep -q "^${key}=" /home/ubuntu/Leonardo/.env 2>/dev/null; then
                sed -i "s|^${key}=.*|${key}=${val}|" /home/ubuntu/Leonardo/.env
            else
                echo "${key}=${val}" >> /home/ubuntu/Leonardo/.env
            fi
        fi
    done

    cp /home/ubuntu/Leonardo/.env /home/ubuntu/Leonardo/.env.rails
    rm /tmp/.env.pre-restore
    echo "   ✓ Identity spliced for ${INSTANCE_NAME}"
fi

# Re-anchor cwd to the freshly-restored Leonardo. The earlier `rm -rf Leonardo`
# left the shell's cwd fd pointing at a deleted inode; without this, every
# subsequent `docker compose` call fails with "no configuration file provided"
# because compose can't find docker-compose.yml from the stale cwd.
cd /home/ubuntu/Leonardo

# The restored project tarball can land bin/*.sh without exec bits, which makes later
# `sudo bin/db/backup.sh` / master_backup_all.sh sub-script calls fail ("command not found"
# / exit 126) and orphan the instance in `error` on its next backup. Re-assert exec bits on
# all repo scripts so the restored instance is runnable. Idempotent; safe to re-run.
echo "🔧 Re-asserting exec bits on bin/*.sh after project restore..."
find /home/ubuntu/Leonardo/bin -name '*.sh' -exec chmod +x {} + 2>/dev/null || true

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
    full_docker_down
    PG_VOLUME=$(docker volume ls --format '{{.Name}}' | grep -E '(_|^)postgres_data$' | head -n 1)
    if [ -n "$PG_VOLUME" ]; then
        echo "   🗑  Removing stale postgres volume: $PG_VOLUME"
        docker volume rm "$PG_VOLUME" > /dev/null 2>&1 || true
    fi

    # Try up to 3 times to bring postgres up, load dump, align password
    QUICK_PG_OK=false
    for pg_attempt in 1 2 3; do
        echo ""
        echo "🚀 Starting postgres (attempt ${pg_attempt}/3)..."
        full_docker_down
        docker compose up -d db

        if ! wait_for_postgres 90; then
            echo "   ⚠️  Postgres failed to become ready on attempt ${pg_attempt}"
            [ $pg_attempt -lt 3 ] && sleep 5
            continue
        fi

        echo "📥 Loading quick postgres dump (timestamp ${QUICK_TS})..."
        if load_quick_postgres_dump; then
            echo "   ✓ Database loaded"
        else
            echo "   ⚠️  Dump load returned non-zero on attempt ${pg_attempt}"
            [ $pg_attempt -lt 3 ] && sleep 5
            continue
        fi

        echo "🔐 Aligning postgres password with .env..."
        if align_postgres_password; then
            QUICK_PG_OK=true
            break
        else
            echo "   ⚠️  Password alignment failed on attempt ${pg_attempt}"
            [ $pg_attempt -lt 3 ] && sleep 5
        fi
    done

    if [ "$QUICK_PG_OK" != true ]; then
        echo "❌ Quick postgres restore FAILED after 3 attempts"
        ERRORS="${ERRORS}quick_pg_restore "
    fi

# ─── FULL or HYBRID PATH ──────────────────────────────────────────────────
else
    # STEP 2: Restore Docker Volumes
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 STEP 2: Restore Docker Volumes"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    # Must use -v so compose-prefixed volumes (e.g. leonardo_postgres_data) are
    # actually removed — otherwise the volume restore script's `docker volume rm`
    # silently fails and the old volume (with a different postgres password) survives.
    docker compose down -v --remove-orphans --timeout 10 2>/dev/null || true
    sleep 2

    if ./bin/backups/cloud/9_restore_docker_volumes_from_s3.sh \
        "${INSTANCE_NAME}" "${S3_BUCKET}" "${FULL_TS}"; then
        echo "✅ Step 2 complete"
    else
        echo "⚠️  Step 2 had errors (some volumes may have failed)"
        ERRORS="${ERRORS}volume_restore "
    fi
    echo ""

    # STEP 3: Fix Postgres Password Mismatch (3 attempts)
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 STEP 3: Fix Postgres Password"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    PG_PASSWORD_OK=false
    for pg_attempt in 1 2 3; do
        echo "🚀 Starting postgres (attempt ${pg_attempt}/3)..."
        full_docker_down
        docker compose up -d db

        if wait_for_postgres 60; then
            echo "🔐 Updating postgres password to match .env..."
            if align_postgres_password; then
                PG_PASSWORD_OK=true
                break
            fi
        else
            echo "   ⚠️  Postgres failed to start on attempt ${pg_attempt}"
        fi

        if [ $pg_attempt -lt 3 ]; then
            echo "   Retrying in 5s..."
            sleep 5
        fi
    done

    if [ "$PG_PASSWORD_OK" = true ]; then
        # Safety net: load pg_dumpall in case volume restore targeted wrong volume names.
        # This ensures database data is present even if the volume tar went to an orphaned volume.
        echo "🔄 Loading pg_dumpall as safety net..."
        drop_user_databases
        if load_full_postgres_dump; then
            echo "   ✓ Full dump loaded"
            echo "🔐 Realigning postgres password after dump load..."
            align_postgres_password || ERRORS="${ERRORS}pg_dump_pwd "
        else
            echo "   ⚠️  Full dump not available — relying on volume restore data"
        fi

        echo "🔄 Restarting db + redis with new password..."
        full_docker_down
        docker compose up -d db redis
        if wait_for_postgres 60; then
            echo "   ✓ Postgres restarted"
        else
            echo "   ⚠️  Postgres slow to restart after password change"
            ERRORS="${ERRORS}pg_restart "
        fi
        echo "✅ Step 3 complete"
    else
        echo "❌ Step 3 FAILED — could not fix postgres password after 3 attempts"
        ERRORS="${ERRORS}pg_password "
    fi
    echo ""

    # STEP 4: Restore system configs (SSL certs, Caddyfile, etc.)
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 STEP 4: Restore System Configs & SSL Certificates"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if sudo ./bin/backups/cloud/7_restore_system_configs_from_s3.sh \
        "${INSTANCE_NAME}" "${S3_BUCKET}"; then
        echo "✅ Step 4 complete"
    else
        echo "⚠️  Step 4 had errors (non-critical, Caddy will re-issue certs)"
        ERRORS="${ERRORS}system_configs "
    fi
    echo "🔄 Reloading Caddy..."
    sudo systemctl reload caddy 2>/dev/null || true
    echo ""

    # STEP 5 (hybrid only): Overlay quick backup on top of full
    if [ "$MODE" = "hybrid" ]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📦 STEP 5: Overlay Quick Backup (QUICK ${QUICK_TS} > FULL ${FULL_TS})"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        # Overlay project files (no --delete inside step 8 quick mode: preserves
        # .git, node_modules, etc. that the tarball restored)
        if ./bin/backups/cloud/8_restore_project_files_from_s3.sh \
            "${INSTANCE_NAME}" "${S3_BUCKET}" /home/ubuntu quick; then
            echo "   ✓ Quick project files overlaid"
        else
            echo "   ⚠️  Quick project files overlay had errors"
            ERRORS="${ERRORS}quick_overlay_files "
        fi

        # Replace postgres data with quick dump.
        # Postgres is already running from Step 3 with .env password aligned.
        # pg_dumpall has no DROP statements, so drop user databases first.
        if [ "$PG_PASSWORD_OK" = true ]; then
            echo "🗑  Dropping FULL_TS user databases before loading QUICK dump..."
            drop_user_databases

            echo "📥 Loading quick postgres dump (timestamp ${QUICK_TS})..."
            if load_quick_postgres_dump; then
                echo "   ✓ Quick dump loaded"
                echo "🔐 Realigning postgres password with .env..."
                align_postgres_password || ERRORS="${ERRORS}quick_overlay_pwd "
            else
                echo "   ⚠️  Quick dump load failed"
                ERRORS="${ERRORS}quick_overlay_pg "
            fi
        else
            echo "   ⚠️  Skipping quick postgres overlay (Step 3 password fix failed)"
        fi
        echo "✅ Step 5 complete"
        echo ""
    fi
fi

# ─── Final start + verification ───────────────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Start All Services"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
IPADDRESS=""
if TOKEN=$(curl -sf -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" --connect-timeout 2 2>/dev/null); then
    IPADDRESS=$(curl -sf -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4 --connect-timeout 2 2>/dev/null || true)
fi
echo "📍 Public IP: ${IPADDRESS:-<not available - LXD or non-AWS host>}"
echo "🌐 DNS already configured by orchestrator"
echo ""
echo "🚀 Starting all services..."
full_docker_down
docker compose up -d

echo "🔍 Verifying services..."
sleep 5
RUNNING_SERVICES=$(docker compose ps --format '{{.Service}} {{.State}}' 2>/dev/null || echo "")
echo "   Services: ${RUNNING_SERVICES}"

if echo "$RUNNING_SERVICES" | grep -q "db.*running"; then
    echo "   ✓ Database is running"
else
    echo "   ⚠️  Database may not be running"
    ERRORS="${ERRORS}db_not_running "
fi
echo ""

# ─── Final summary ────────────────────────────────────────────────────────
MASTER_END=$(date +%s)
MASTER_DURATION=$((MASTER_END - MASTER_START))

echo "════════════════════════════════════════════════════════════"
if [ -z "$ERRORS" ]; then
    echo "✅ RESTORE COMPLETE! (mode=${MODE})"
else
    echo "⚠️  RESTORE COMPLETE WITH WARNINGS (mode=${MODE})"
    echo "   Issues: ${ERRORS}"
fi
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

# Exit non-zero only on truly fatal failures
if echo "$ERRORS" | grep -qE "pg_password|quick_pg_restore|db_not_running"; then
    exit 1
fi
exit 0
