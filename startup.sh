#!/bin/bash
set -euo pipefail

# Retrieve DB password from GCE instance metadata
METADATA_URL="http://metadata.google.internal/computeMetadata/v1/instance/attributes/db_password"
DB_PASSWORD="$(curl -fsSL -H 'Metadata-Flavor: Google' ${METADATA_URL})"

# Update OS
apt-get update -y
apt-get upgrade -y

# Install dependencies
apt-get install -y curl tar postgresql postgresql-contrib

# Enable PostgreSQL
systemctl enable postgresql
systemctl start postgresql

# Create DB and user (idempotent)
sudo -u postgres psql <<EOF || true
DO
\$do\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'bindplane') THEN
      PERFORM dblink_connect('dbname=postgres');
      CREATE DATABASE bindplane;
   END IF;
END
\$do\$;
EOF

sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='bindplane_user'" | grep -q 1 || sudo -u postgres psql -c "CREATE USER bindplane_user WITH PASSWORD '${DB_PASSWORD}';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE bindplane TO bindplane_user;" || true

# Download BindPlane binary (observiq bindplane example)
BP_URL="https://github.com/observiq/bindplane/releases/latest/download/bindplane_linux_amd64.tar.gz"
curl -fsSL "${BP_URL}" -o /tmp/bindplane.tar.gz
tar -xzf /tmp/bindplane.tar.gz -C /tmp
mv /tmp/bindplane /usr/local/bin/bindplane
chmod +x /usr/local/bin/bindplane

# Create config directory
mkdir -p /etc/bindplane
cat <<EOF >/etc/bindplane/config.yaml
server:
  http:
    address: 0.0.0.0:3001

database:
  type: postgres
  host: localhost
  port: 5432
  name: bindplane
  user: bindplane_user
  password: ${DB_PASSWORD}
  sslmode: disable
EOF

# Systemd service
cat <<EOF >/etc/systemd/system/bindplane.service
[Unit]
Description=BindPlane Server
After=network.target postgresql.service

[Service]
ExecStart=/usr/local/bin/bindplane serve --config /etc/bindplane/config.yaml
Restart=always
User=root
Environment=PATH=/usr/local/bin:/usr/bin:/bin

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable bindplane
systemctl start bindplane

# Cleanup
rm -f /tmp/bindplane.tar.gz