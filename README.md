# MyFileBrowserQuantum

Cấu hình triển khai và script quản lý dịch vụ **FileBrowser Quantum (v2.0.1+)** trên **Void Linux (ARM64 / Raspberry Pi 5)** sử dụng **Runit init system** kết hợp **Nginx Reverse Proxy**.

---

## 📁 Cấu trúc thư mục

```text
.
├── config.yaml          # File cấu hình FileBrowser Quantum v2
├── Install.sh           # Script triển khai & kích hoạt service runit
├── run                  # Script khởi chạy service cho runit
├── log/
│   └── run              # Script ghi log service (svlogd)
├── .gitignore           # Bỏ qua database, cache, binary và supervise runit
└── README.md            # Hướng dẫn chi tiết
```

---

## ⚙️ Thông số hệ thống & Cấu hình

- **Application:** FileBrowser Quantum `v2.0.1-stable` (ARM64)
- **Port nội bộ:** `3676` (Reverse proxy qua Nginx cổng `443` HTTPS)
- **Database:** SQLite (`./filebrowser.sqlite`)
- **Nguồn lưu trữ (Sources):**
  - `ssd_fus`: `/home/fus/` (Ổ SSD hệ thống)
  - `fus_hdd`: `/mnt/ExternalDisk` (Ổ cứng ngoài)
- **Service Init:** Runit (`/etc/sv/FileBrowserQuantum` -> `/var/service/FileBrowserQuantum`)
- **Log Service:** `/var/log/FileBrowserQuantum/current`

---

## 🚀 Hướng dẫn cài đặt & Triển khai

### 1. Tải binary FileBrowser Quantum (ARM64)

```bash
wget https://github.com/gtsteffaniak/filebrowser/releases/download/v2.0.1-stable/linux-arm64-filebrowser
chmod +x linux-arm64-filebrowser
```

### 2. Triển khai dịch vụ với Runit

Chạy script cài đặt (yêu cầu quyền `sudo`):

```bash
./Install.sh
```

Script sẽ tự động:
1. Sao chép thư mục dịch vụ vào `/etc/sv/FileBrowserQuantum`
2. Tạo symbolic link vào `/var/service/FileBrowserQuantum` để kích hoạt
3. Khởi động lại service `FileBrowserQuantum`

---

## 🛠️ Quản lý dịch vụ (Runit Commands)

```bash
# Kiểm tra trạng thái service
sudo sv status FileBrowserQuantum

# Khởi động lại service
sudo sv restart FileBrowserQuantum

# Dừng service
sudo sv stop FileBrowserQuantum

# Bật service
sudo sv start FileBrowserQuantum

# Xem log thời gian thực
tail -f /var/log/FileBrowserQuantum/current
```

---

## 👤 Quản lý người dùng qua CLI

```bash
# Đặt lại mật khẩu cho tài khoản admin
./linux-arm64-filebrowser user set admin --password="your_new_password"

# Nâng quyền quản trị viên cho tài khoản
./linux-arm64-filebrowser user promote <username>

# Cấu hình rule truy cập
./linux-arm64-filebrowser set rule --source=ssd_fus --path=/ --role=admin
```

---

## 🌐 Cấu hình Nginx Reverse Proxy (Tham khảo)

FileBrowser Quantum v2 cần bật `trustProxyHeaders: true` trong `config.yaml` để nhận diện đúng giao thức HTTPS và IP từ Nginx:

```nginx
server {
    listen 443 ssl;
    server_name ngxxfus.io.vn 10.0.0.88 localhost;

    ssl_certificate     /etc/letsencrypt/live/ngxxfus.io.vn/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/ngxxfus.io.vn/privkey.pem;

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

