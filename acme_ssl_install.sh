#!/bin/bash

# 安装 acme.sh
echo "正在安装 acme.sh..."
curl https://get.acme.sh | sh

# 启用 acme.sh 自动更新
echo "启用 acme.sh 自动更新..."
~/.acme.sh/acme.sh --upgrade --auto-upgrade

# 获取用户输入的域名和 Cloudflare API Token
read -p "请输入要申请证书的域名（例如：example.com）: " DOMAIN
read -p "请输入Cloudflare的API Token: " CF_Token

# 配置环境变量
export CF_Token="$CF_Token"

# 检查并设置默认 CA 为 Let’s Encrypt（可选）
echo "设置默认 CA 为 Let’s Encrypt..."
~/.acme.sh/acme.sh --set-default-ca --server letsencrypt

# 申请证书（包括通配符）
echo "正在申请 $DOMAIN 和 *.${DOMAIN} 的证书..."
~/.acme.sh/acme.sh --issue --dns dns_cf -d "$DOMAIN" -d "*.${DOMAIN}" --keylength ec-256

# 检查申请是否成功
if [ $? -ne 0 ]; then
    echo "证书申请失败，请检查域名和 API Token 是否正确。"
    exit 1
fi

# 安装证书到 /etc/ssl/$DOMAIN 目录
CERT_DIR="/etc/ssl/$DOMAIN"
mkdir -p "$CERT_DIR"
echo "安装证书到 $CERT_DIR..."
~/.acme.sh/acme.sh --install-cert -d "$DOMAIN" \
    --ecc \
    --cert-file "$CERT_DIR/$DOMAIN.cer" \
    --key-file "$CERT_DIR/$DOMAIN.key" \
    --fullchain-file "$CERT_DIR/fullchain.cer"

# 创建 cron job，每天 0:00 检查并更新证书
echo "添加每日定时任务..."
(crontab -l 2>/dev/null; echo "0 0 * * * ~/.acme.sh/acme.sh --cron --home ~/.acme.sh > /dev/null") | crontab -

# 清除环境变量（增强安全性）
unset CF_Token

echo "证书申请和安装完成，每日自动检测更新证书已配置。"
