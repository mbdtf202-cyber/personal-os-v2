#!/bin/bash
# ✅ P2 EXTREME: CI/CD 构建脚本 - 安全注入并清理 API 密钥
# 用法：./Scripts/inject_secrets.sh

set -e

SECRETS_FILE="${SRCROOT}/personalos-ios-v2/Core/Security/CompileTimeSecrets.swift"
SECRETS_BACKUP="${SECRETS_FILE}.backup"

echo "🔐 Injecting secrets into CompileTimeSecrets.swift..."

# 备份原始文件（包含占位符）
if [ ! -f "$SECRETS_BACKUP" ]; then
    cp "$SECRETS_FILE" "$SECRETS_BACKUP"
    echo "📦 Backup created: $SECRETS_BACKUP"
fi

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

# ✅ P2 EXTREME: 注册清理钩子，确保构建后删除包含密钥的文件
cleanup_secrets() {
    echo "🧹 Cleaning up secrets file..."
    if [ -f "$SECRETS_BACKUP" ]; then
        mv "$SECRETS_BACKUP" "$SECRETS_FILE"
        echo "✅ Secrets file restored to placeholder version"
    else
        # 如果没有备份，至少覆盖敏感内容
        echo "⚠️  No backup found, overwriting with zeros..."
        dd if=/dev/zero of="$SECRETS_FILE" bs=1k count=1 2>/dev/null || true
        rm -f "$SECRETS_FILE"
    fi
}

# 注册退出时清理（仅在 CI 环境）
if [ "$CI" = "true" ]; then
    trap cleanup_secrets EXIT
    echo "🔒 Cleanup trap registered for CI environment"
fi
