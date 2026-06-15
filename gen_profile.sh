#!/bin/bash
# =============================================================================
# gen_profile.sh — 交互式配置 profile（便携版，无加密）
# 用法: bash gen_profile.sh <profile_name>
# =============================================================================
set -e

PROFILE="${1}"
if [ -z "$PROFILE" ]; then
    echo "用法: bash gen_profile.sh <profile_name>"
    echo "已有 profile:"
    ls -1 "$HOME/.codex-pool/" 2>/dev/null || echo "  (尚无)"
    exit 1
fi

POOL_DIR="$HOME/.codex-pool/$PROFILE"
mkdir -p "$POOL_DIR"
chmod 700 "$POOL_DIR"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  🛠️  Profile 配置向导: $PROFILE"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ==========================================================================
# ① config.toml
# ==========================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ① config.toml — 端点与模型配置"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -f "$POOL_DIR/config.toml" ]; then
    echo -n "⚠️  已有 config.toml，覆盖？(y/n): "
    read -r OVERWRITE
    if [ "$OVERWRITE" != "y" ] && [ "$OVERWRITE" != "Y" ]; then
        SKIP_CONFIG=1
    fi
fi

if [ "$SKIP_CONFIG" != "1" ]; then
    echo "请粘贴 config.toml 内容，输入 ===END=== 结束："
    echo ""

    CONFIG_TMP="/dev/shm/config_$$"
    : > "$CONFIG_TMP"

    while IFS= read -r line; do
        if [ "$line" = "===END===" ]; then
            break
        fi
        echo "$line" >> "$CONFIG_TMP"
    done

    if [ -s "$CONFIG_TMP" ]; then
        cp "$CONFIG_TMP" "$POOL_DIR/config.toml"
        chmod 600 "$POOL_DIR/config.toml"
        echo ""
        echo "  ✅ config.toml 已保存 ($(wc -l < "$CONFIG_TMP") 行)"
        cat "$POOL_DIR/config.toml"
    else
        echo "  ⚠️  输入为空，跳过"
    fi
    rm -f "$CONFIG_TMP"
fi

# ==========================================================================
# ② auth.json
# ==========================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ② auth.json — API Key（可选）"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -f "$POOL_DIR/auth.json" ]; then
    echo -n "⚠️  已有 auth.json，覆盖？(y/n): "
    read -r OVERWRITE
    if [ "$OVERWRITE" != "y" ] && [ "$OVERWRITE" != "Y" ]; then
        SKIP_AUTH=1
    fi
fi

if [ "$SKIP_AUTH" != "1" ]; then
    echo -n "需要 auth.json？(y/n): "
    read -r NEED_AUTH

    if [ "$NEED_AUTH" = "y" ] || [ "$NEED_AUTH" = "Y" ]; then
        echo "请粘贴 auth.json 内容（一行 JSON），回车结束："
        read -r AUTH_JSON
        if [ -n "$AUTH_JSON" ]; then
            echo "$AUTH_JSON" > "$POOL_DIR/auth.json"
            chmod 600 "$POOL_DIR/auth.json"
            echo "  ✅ auth.json 已保存"
        else
            echo "  ⚠️  输入为空，跳过"
        fi
    else
        echo "  跳过"
    fi
fi

# ==========================================================================
echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  ✅ Profile [$PROFILE] 配置完成！           ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
ls -la "$POOL_DIR/"
echo ""
echo "使用: codex-use $PROFILE"
