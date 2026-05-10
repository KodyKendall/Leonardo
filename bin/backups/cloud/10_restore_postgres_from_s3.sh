#!/bin/bash
# Postgres restore from S3 with retry logic.
# Downloads the dump to a temp file first so the psql step can be retried
# without re-downloading from S3.

S3_BUCKET="$1"
BACKUP_NAME="$2"  # Optional: specific backup name

if [ -z "$S3_BUCKET" ]; then
    echo "Usage: $0 <s3_bucket> [backup_name]"
    echo "Example: $0 s3://my-bucket/postgres-backups"
    exit 1
fi

echo "🔵 Postgres Restore Starting..."
echo "⏱️  Start: $(date +%H:%M:%S)"
START=$(date +%s)

# If no backup specified, try to find the latest
if [ -z "$BACKUP_NAME" ]; then
    echo "📋 No backup specified, finding latest..."

    LATEST_TIMESTAMP=$(aws s3 cp "${S3_BUCKET}/latest-backup.txt" - 2>/dev/null | tr -d '[:space:]' || echo "")

    if [ -z "$LATEST_TIMESTAMP" ]; then
        # Fallback: list timestamp folders, excluding the quick-backup 'latest/' prefix
        LATEST_TIMESTAMP=$(aws s3 ls "${S3_BUCKET}/" \
            | grep "PRE" \
            | awk '{print $2}' \
            | sed 's|/||g' \
            | grep -v '^latest$' \
            | sort \
            | tail -n 1)
    fi

    if [ -z "$LATEST_TIMESTAMP" ]; then
        echo "❌ No full backups found in ${S3_BUCKET}"
        exit 1
    fi

    echo "📍 Using timestamp: ${LATEST_TIMESTAMP}"

    LATEST_FILE=$(aws s3 ls "${S3_BUCKET}/${LATEST_TIMESTAMP}/" | grep "postgres-" | awk '{print $4}' | head -n 1)
    if [ -z "$LATEST_FILE" ]; then
        echo "❌ No postgres backup found in ${S3_BUCKET}/${LATEST_TIMESTAMP}/"
        exit 1
    fi

    BACKUP_NAME="${LATEST_TIMESTAMP}/${LATEST_FILE}"
    echo "📍 Using: ${BACKUP_NAME}"
fi

# --- Download dump to temp file (so we can retry psql without re-downloading) ---
DUMP_FILE="/tmp/pg_restore_$$.sql.gz"
trap "rm -f '$DUMP_FILE'" EXIT

echo "📥 Downloading SQL dump from S3..."
echo "   Source: ${S3_BUCKET}/${BACKUP_NAME}"
if ! aws s3 cp "${S3_BUCKET}/${BACKUP_NAME}" "$DUMP_FILE"; then
    echo "❌ Failed to download SQL dump from S3"
    exit 1
fi

DUMP_SIZE=$(stat -c%s "$DUMP_FILE" 2>/dev/null || echo "unknown")
echo "   ✓ Downloaded (${DUMP_SIZE} bytes)"

# --- Helper: ensure postgres is up and accepting queries ---
# Uses TCP (-h 127.0.0.1) instead of unix socket. The official postgres image
# runs a socket-only init phase on a fresh volume that pg_isready-via-socket
# reports as "ready", but the init phase then `pg_ctl stop`s and re-execs into
# the real production postgres — killing any client connection with "FATAL:
# terminating connection due to administrator command". TCP is only opened in
# the production phase, so it's a reliable readiness signal in all cases.
ensure_postgres_ready() {
    echo "🚀 Ensuring database is running..."
    docker compose up -d db

    echo -n "⏳ Waiting for DB"
    local timeout=60
    local elapsed=0
    until docker compose exec -T db pg_isready -h 127.0.0.1 -U postgres > /dev/null 2>&1; do
        if [ $elapsed -ge $timeout ]; then
            echo " ❌ Timeout (pg_isready)!"
            return 1
        fi
        echo -n "."
        sleep 1
        elapsed=$((elapsed + 1))
    done
    # Verify a real query works (belt + suspenders)
    until docker compose exec -T db psql -U postgres -c "SELECT 1" > /dev/null 2>&1; do
        if [ $elapsed -ge $timeout ]; then
            echo " ❌ Timeout (query test)!"
            return 1
        fi
        echo -n "."
        sleep 1
        elapsed=$((elapsed + 1))
    done
    echo " ✓ (${elapsed}s)"
    return 0
}

# --- Restore with retry ---
MAX_ATTEMPTS=3
RESTORE_OK=false

for attempt in $(seq 1 $MAX_ATTEMPTS); do
    echo ""
    echo "📥 Restoring SQL dump (attempt ${attempt}/${MAX_ATTEMPTS})..."

    if ! ensure_postgres_ready; then
        echo "   ⚠️  Postgres not ready, restarting container..."
        docker compose down db --timeout 10 2>/dev/null || true
        sleep 3
        continue
    fi

    # Feed the dump to psql from the local file (not streaming from S3)
    if gunzip -c "$DUMP_FILE" \
        | docker compose exec -T db psql -U postgres 2>&1 \
        | grep -v "^CREATE\|^ALTER\|^SET\|^--\|^INSERT\|^COPY\|^$" || true; then

        # Verify data was actually restored
        echo "🔍 Verifying data restoration..."
        TABLE_COUNT=$(docker compose exec -T db psql -U postgres -t -c \
            "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" \
            2>/dev/null | tr -d ' \n' || echo "0")
        echo "   Found ${TABLE_COUNT} tables in database"

        if [ "$TABLE_COUNT" != "0" ] && [ -n "$TABLE_COUNT" ]; then
            echo "   ✓ Data verified"
            RESTORE_OK=true
            break
        else
            echo "   ⚠️  No tables found after restore — psql may have been interrupted"
        fi
    fi

    if [ $attempt -lt $MAX_ATTEMPTS ]; then
        echo "   Retrying in 5s..."
        # Full restart of DB to clear any bad state
        docker compose down db --timeout 10 2>/dev/null || true
        sleep 5
    fi
done

END=$(date +%s)
DURATION=$((END - START))

if [ "$RESTORE_OK" = true ]; then
    echo "✅ Restore complete in ${DURATION} seconds"
    echo "⏱️  End: $(date +%H:%M:%S)"
    exit 0
else
    echo "❌ Restore FAILED after ${MAX_ATTEMPTS} attempts (${DURATION}s)"
    echo "⏱️  End: $(date +%H:%M:%S)"
    exit 1
fi
