#!/bin/bash
# CI/CD 构建脚本：在编译时注入 API 密钥
# 用法：./Scripts/inject_secrets.sh

set -e

SECRETS_FILE="${SRCROOT}/personalos-ios-v2/Core/Security/CompileTimeSecrets.swift"

echo "🔐 Injecting secrets into CompileTimeSecrets.swift..."

# 从环境变量读取密钥（CI/CD 中配置）
STOCK_KEY="${STOCK_API_KEY:-PLACEHOLDER_STOCK_KEY}"
NEWS_KEY="${NEWS_API_KEY:-PLACEHOLDER_NEWS_KEY}"

# 替换占位符
sed -i '' "s/PLACEHOLDER_STOCK_KEY/${STOCK_KEY}/g" "$SECRETS_FILE"
sed -i '' "s/PLACEHOLDER_NEWS_KEY/${NEWS_KEY}/g" "$SECRETS_FILE"

echo "✅ Secrets injected successfully"

# 验证是否成功替换
if grep -q "PLACEHOLDER" "$SECRETS_FILE"; then
    echo "⚠️  Warning: Some placeholders were not replaced"
    exit 1
fi

echo "✅ All placeholders replaced"
