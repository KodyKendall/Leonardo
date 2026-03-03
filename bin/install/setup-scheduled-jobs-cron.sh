#!/bin/bash
#
# Install crontab entry for scheduled job invocation
#
# This runs every minute and calls the LlamaBot API to check for due jobs.
# The actual job schedules are managed in the database via ScheduledJob.cron_expression.
#
# Usage:
#   ./setup-scheduled-jobs-cron.sh
#
# Environment variables:
#   SCHEDULER_TOKEN - Optional. If not set, will be auto-generated and appended to .env
#   LLAMABOT_URL - Optional. Defaults to http://localhost:8000

set -e

# Get Leonardo root - script runs from Leonardo directory via slash command
# When run via nsenter, we're already cd'd to Leonardo directory
LEONARDO_ROOT="${LEONARDO_ROOT:-$(pwd)}"
ENV_FILE="${LEONARDO_ROOT}/.env"

# Always use localhost:8000 for cron (runs on host, calls into container)
LLAMABOT_URL="http://localhost:8000"
SCHEDULER_TOKEN="${SCHEDULER_TOKEN}"
LOG_FILE="${LOG_FILE:-/var/log/llamabot-scheduler.log}"

# If SCHEDULER_TOKEN not set, check .env file or generate new one
if [ -z "$SCHEDULER_TOKEN" ]; then
    # Try to load from .env file
    if [ -f "$ENV_FILE" ]; then
        SCHEDULER_TOKEN=$(grep -E "^SCHEDULER_TOKEN=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2- | tr -d '"' | tr -d "'")
    fi

    # If still not set, generate and append to .env
    if [ -z "$SCHEDULER_TOKEN" ]; then
        echo "SCHEDULER_TOKEN not found. Generating new token..."
        SCHEDULER_TOKEN=$(openssl rand -hex 32)

        if [ -f "$ENV_FILE" ]; then
            # Append to existing .env with comment
            echo "" >> "$ENV_FILE"
            echo "# Token for scheduled job cron authentication (used by bin/install/setup-scheduled-jobs-cron.sh)" >> "$ENV_FILE"
            echo "SCHEDULER_TOKEN=${SCHEDULER_TOKEN}" >> "$ENV_FILE"
            echo "" >> "$ENV_FILE"
            echo "Generated SCHEDULER_TOKEN and appended to $ENV_FILE"
        else
            echo "ERROR: .env file not found at $ENV_FILE"
            echo "Please create the .env file first or set SCHEDULER_TOKEN environment variable"
            exit 1
        fi
    else
        echo "Using SCHEDULER_TOKEN from $ENV_FILE"
    fi
fi

# Create log file if it doesn't exist
sudo touch "$LOG_FILE" 2>/dev/null || touch "$LOG_FILE"
sudo chmod 666 "$LOG_FILE" 2>/dev/null || chmod 666 "$LOG_FILE"

# Build cron command
# Runs every minute, silently fails if server is down (-f), logs output
CRON_CMD="* * * * * curl -sf -X POST \"${LLAMABOT_URL}/api/scheduled-jobs/invoke\" -H \"X-Scheduler-Token: ${SCHEDULER_TOKEN}\" >> ${LOG_FILE} 2>&1"

# Check if cron entry already exists
EXISTING_CRON=$(crontab -l 2>/dev/null || true)

if echo "$EXISTING_CRON" | grep -q "scheduled-jobs/invoke"; then
    echo "Scheduled jobs cron entry already exists. Updating..."
    # Remove old scheduled-jobs entry, preserve everything else, then add new entry
    (echo "$EXISTING_CRON" | grep -v "scheduled-jobs/invoke"; echo "$CRON_CMD") | crontab -
else
    # Append new entry, preserving all existing cron jobs
    if [ -n "$EXISTING_CRON" ]; then
        (echo "$EXISTING_CRON"; echo "$CRON_CMD") | crontab -
    else
        echo "$CRON_CMD" | crontab -
    fi
fi

echo "Scheduled jobs cron entry installed successfully!"
echo ""
echo "Cron will run every minute and check for due jobs."
echo "Logs will be written to: $LOG_FILE"
echo ""
echo "To view logs:    tail -f $LOG_FILE"
echo "To list cron:    crontab -l"
echo "To remove cron:  crontab -l | grep -v 'scheduled-jobs/invoke' | crontab -"
