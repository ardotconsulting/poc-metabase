#!/bin/sh
# setup-admin.sh — claim the admin account automatically after first deploy.
# Metabase exposes a setup API at /api/setup/ that we can POST to.
# This script waits for Metabase to be ready, then creates the admin user
# as admin@ardotconsulting.com with $ADMIN_PASSWORD. If setup is already
# complete (no setup token), it does nothing.
#
# Tools available in the Metabase image: wget (busybox), sh.

set -e

MB_HOST="localhost"
MB_PORT="3000"
ADMIN_EMAIL="admin@ardotconsulting.com"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-changeme}"
SITE_NAME="ARDOT Consulting POC"

# Wait for Metabase to respond
echo "Waiting for Metabase to be ready..."
for i in $(seq 1 60); do
    code=$(wget -q -O /dev/null --spider "http://${MB_HOST}:${MB_PORT}/api/health" 2>/dev/null && echo "200" || echo "000")
    if [ "$code" = "200" ]; then
        echo "Metabase is ready."
        break
    fi
    sleep 5
done

# Check if setup is already done via session/properties
setup_token_resp=$(wget -q -O - "http://${MB_HOST}:${MB_PORT}/api/session/properties" 2>/dev/null || echo "")
setup_token=$(echo "$setup_token_resp" | grep -o '"setup-token":"[^"]*"' | head -1 | sed 's/"setup-token":"//;s/"//')

if [ -z "$setup_token" ]; then
    echo "No setup token found — setup may already be complete. Nothing to do."
    exit 0
fi

echo "Setup token found. Claiming admin..."

# POST to /api/setup/ with the token and admin credentials
PAYLOAD="{\"token\":\"${setup_token}\",\"user\":{\"email\":\"${ADMIN_EMAIL}\",\"site_name\":\"${SITE_NAME}\",\"password\":\"${ADMIN_PASSWORD}\",\"first_name\":\"ARDOT\",\"last_name\":\"Admin\"},\"prefs\":{\"site_name\":\"${SITE_NAME}\",\"site_locale\":\"en\"}}"

wget -q -O /dev/null --post-data="$PAYLOAD" \
    --header="Content-Type: application/json" \
    "http://${MB_HOST}:${MB_PORT}/api/setup/" 2>/dev/null && \
    echo "Admin account created successfully." || \
    echo "Setup POST returned an error — setup may already be complete."

exit 0
