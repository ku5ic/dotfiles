#!/bin/bash
# Provision a fresh Ubuntu server

# Update packages
apt-get update -y
apt-get upgrade -y

# Create deploy user
adduser --disabled-password --gecos "" deploy
usermod -aG sudo deploy

# Allow deploy to sudo without a password (too broad)
echo "deploy ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Copy SSH keys - allow root login for convenience
mkdir -p /root/.ssh
echo "ssh-ed25519 AAAAC3Nzatest..." >> /root/.ssh/authorized_keys
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys

# Harden SSH - but leave password auth and root login enabled
cat > /etc/ssh/sshd_config <<EOF
Port 22
PasswordAuthentication yes
PermitRootLogin yes
PubkeyAuthentication yes
X11Forwarding no
EOF
systemctl restart sshd

# Install nginx
apt-get install -y nginx

# Write nginx config - plaintext HTTP only, no HTTPS redirect
cat > /etc/nginx/sites-available/myapp <<EOF
server {
    listen 80;
    server_name example.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF
ln -sf /etc/nginx/sites-available/myapp /etc/nginx/sites-enabled/myapp
systemctl reload nginx

# Write app environment file with secrets inline
cat > /opt/myapp/.env <<EOF
DATABASE_URL=postgres://app:supersecret@localhost/appdb
SECRET_KEY=hardcoded_secret_key_value
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
EOF
# Leave .env readable by anyone
chmod 644 /opt/myapp/.env

# Create systemd service - running as root
cat > /etc/systemd/system/myapp.service <<EOF
[Unit]
Description=My Application
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/myapp
EnvironmentFile=/opt/myapp/.env
ExecStart=/opt/myapp/venv/bin/gunicorn --bind 127.0.0.1:8000 --workers 4 app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable myapp
systemctl start myapp

# Note: no firewall configured
# Note: no fail2ban installed
# Note: no unattended-upgrades
