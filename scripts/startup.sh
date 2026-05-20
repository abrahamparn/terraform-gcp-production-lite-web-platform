#!/bin/bash
set -euo pipefail

APP_DIR="/opt/prod-lite-app"
APP_PORT="80"

apt-get update -y
apt-get install -y curl ca-certificates nodejs npm

mkdir -p "${APP_DIR}"

cat > "${APP_DIR}/package.json" <<'EOF'
{
  "name": "terraform-gcp-production-lite-web-platform",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2"
  }
}
EOF

cat > "${APP_DIR}/server.js" <<'EOF'
const express = require("express");
const os = require("os");

const app = express();
const port = process.env.PORT || 80;

app.get("/", (req, res) => {
  res.send("Hi from Terraform GCP Production-Lite Platform");
});

app.get("/healthz", (req, res) => {
  res.status(200).send("ok");
});

app.get("/metadata", (req, res) => {
  res.json({
    service: "terraform-gcp-production-lite-web-platform",
    environment: "dev",
    version: "1.0.0",
    hostname: os.hostname()
  });
});

app.listen(port, "0.0.0.0", () => {
  console.log(`App listening on port ${port}`);
});
EOF

cd "${APP_DIR}"
npm install --omit=dev

cat > /etc/systemd/system/prod-lite-app.service <<EOF
[Unit]
Description=Production Lite Node.js App
After=network.target

[Service]
Environment=PORT=${APP_PORT}
WorkingDirectory=${APP_DIR}
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable prod-lite-app
systemctl restart prod-lite-app