FROM metabase/metabase:latest

# Copy setup-admin.sh into the container at /setup-admin.sh
COPY setup-admin.sh /setup-admin.sh
RUN chmod +x /setup-admin.sh
