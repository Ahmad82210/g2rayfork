#!/bin/bash
# --- 1. نصب Xray-core ---
echo " >> در حال نصب Xray..."
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install --version 1.8.23

# --- 2. تولید مقادیر تصادفی برای کانفیگ ---
echo " >> در حال تولید مقادیر امنیتی..."
UUID=$(cat /proc/sys/kernel/random/uuid)
# تولید کلیدهای Reality
KEYS=$(xray x25519)
PRIVATE_KEY=$(echo "$KEYS" | grep "Private key" | awk '{print $3}')
PUBLIC_KEY=$(echo "$KEYS" | grep "Public key" | awk '{print $3}')
SHORT_ID=$(openssl rand -hex 4)
# دریافت IP عمومی
SERVER_IP=$(curl -s https://ipinfo.io/ip)

# --- 3. ایجاد فایل کانفیگ Xray ---
echo " >> در حال ایجاد فایل config.json..."
cat > /usr/local/etc/xray/config.json << EOF
{
  "log": { "loglevel": "warning" },
  "inbounds": [{
    "port": 443,
    "protocol": "vless",
    "settings": {
      "clients": [{ "id": "$UUID", "flow": "xtls-rprx-vision" }],
      "decryption": "none"
    },
    "streamSettings": {
      "network": "tcp",
      "security": "reality",
      "realitySettings": {
        "show": false,
        "dest": "www.microsoft.com:443",
        "serverNames": ["www.microsoft.com", "microsoft.com", "windowsupdate.com"],
        "privateKey": "$PRIVATE_KEY",
        "shortIds": ["$SHORT_ID"]
      }
    }
  }],
  "outbounds": [{ "protocol": "freedom", "tag": "direct" }]
}
EOF

# --- 4. راه‌اندازی مجدد و فعال‌سازی Xray ---
echo " >> در حال راه‌اندازی سرویس Xray..."
systemctl enable xray
systemctl restart xray

# --- 5. تولید لینک VLESS و نمایش آن ---
echo " ✅ نصب با موفقیت انجام شد!"
echo "-------------------------------"
VLESS_LINK="vless://$UUID@$SERVER_IP:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.microsoft.com&fp=chrome&pbk=$PUBLIC_KEY&sid=$SHORT_ID&type=tcp&headerType=none#My-GitHub-VPN"
echo " >> لینک VLESS شما:"
echo "$VLESS_LINK"
echo "-------------------------------"
