# MyFileBrowserQuantum

Deployment configuration, service definition, and management scripts for **FileBrowser Quantum (v2.0.1+)** on **Void Linux (ARM64 / Raspberry Pi 5)** using the **Runit init system** behind an **Nginx Reverse Proxy** with SSL/TLS.

---

## 📁 Repository Structure

```text
.
├── config.yaml          # FileBrowser Quantum v2.0.1 configuration file
├── Install.sh           # Deployment script to install and enable the Runit service
├── run                  # Runit service execution script
├── log/
│   └── run              # Runit svlogd logging service script
├── .gitignore           # Ignores databases, binaries, cache, and supervise dirs
└── README.md            # Documentation and deployment guide
```

---

## ⚙️ Specifications & Configuration

- **Application:** FileBrowser Quantum `v2.0.1-stable` (Linux ARM64)
- **Internal Port:** `3676` (reverse-proxied via Nginx HTTPS port `443`)
- **Database:** SQLite (`./filebrowser.sqlite`)
- **Storage Sources:**
  - `ssd_fus`: `/home/fus/` (System SSD storage)
  - `fus_hdd`: `/mnt/ExternalDisk` (External HDD mount)
- **Service Management:** Runit (`/etc/sv/FileBrowserQuantum` -> `/var/service/FileBrowserQuantum`)
- **Service Logs:** `/var/log/FileBrowserQuantum/current`

---

## 🚀 Installation & Deployment

### 1. Download FileBrowser Quantum Binary (ARM64)

Download the latest stable executable and grant execution permissions:

```bash
wget https://github.com/gtsteffaniak/filebrowser/releases/download/v2.0.1-stable/linux-arm64-filebrowser
chmod +x linux-arm64-filebrowser
```

### 2. Deploy Runit Service

Run the installation script with `sudo` privileges:

```bash
chmod +x Install.sh run log/run
./Install.sh
```

The script will automatically:
1. Safely stop any running instances of `FileBrowserQuantum`.
2. Clean up previous service links if present.
3. Install the service execution scripts into `/etc/sv/FileBrowserQuantum`.
4. Symlink `/etc/sv/FileBrowserQuantum` into `/var/service/` to enable automatic supervision.
5. Wait for `runsv` to register the new service and start it.

---

## 🛠️ Service Management (Runit Commands)

Manage the FileBrowser service using Void Linux's standard `sv` utility:

```bash
# Check service status
sudo sv status FileBrowserQuantum

# Restart the service
sudo sv restart FileBrowserQuantum

# Stop the service
sudo sv stop FileBrowserQuantum

# Start the service
sudo sv start FileBrowserQuantum

# View real-time service logs
tail -f /var/log/FileBrowserQuantum/current
```

---

## 👤 User & Password Management (CLI)

Use the built-in CLI commands to manage users directly:

```bash
# Update password for user 'admin'
./linux-arm64-filebrowser user set admin --password="your_new_password"

# Create or update another user
./linux-arm64-filebrowser user set <username> --password="password"

# Grant administrator permissions
./linux-arm64-filebrowser user promote <username>

# Add or update access rules for a specific source
./linux-arm64-filebrowser set rule --source=ssd_fus --path=/ --role=admin
```

> [!NOTE]
> In `config.yaml`, `auth.adminPassword` is kept commented out to prevent FileBrowser from resetting your custom password back to a default value on every service restart.

---

## 🌐 Nginx Reverse Proxy Setup (Reference)

Ensure `trustProxyHeaders: true` is enabled in `config.yaml` so FileBrowser recognizes HTTPS headers forwarded by Nginx:

```nginx
server {
    listen 80;
    server_name ngxxfus.io.vn 10.0.0.88 localhost;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name ngxxfus.io.vn 10.0.0.88 localhost;

    ssl_certificate      /etc/letsencrypt/live/ngxxfus.io.vn/fullchain.pem;
    ssl_certificate_key  /etc/letsencrypt/live/ngxxfus.io.vn/privkey.pem;

    ssl_session_cache    shared:SSL:1m;
    ssl_session_timeout  5m;
    ssl_ciphers          HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    location / {
        proxy_pass http://127.0.0.1:3676;

        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```
