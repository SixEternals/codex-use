#!/bin/bash
# =============================================================================
# codex-use 便携版 — 一键部署
# 适用：个人电脑，无需加密，纯 profile 切换
# 用法：bash setup.sh
# =============================================================================
set -e

echo "============================================"
echo "  codex-use 便携版 — 部署"
echo "============================================"
echo ""

# 检测 codex
if command -v codex >/dev/null 2>&1; then
    REAL_CODEX="$(command -v codex)"
    echo "✅ codex: $REAL_CODEX"
else
    echo "❌ 未找到 codex，请先安装"
    exit 1
fi

# 创建目录
mkdir -p "$HOME/bin"
mkdir -p "$HOME/.codex-pool"
chmod 700 "$HOME/bin"

# ---- codex wrapper ----
cat > "$HOME/bin/codex" << WRAPPER_EOF
#!/bin/bash
# codex wrapper — 直接透传
exec $REAL_CODEX "\$@"
WRAPPER_EOF
chmod 700 "$HOME/bin/codex"
echo "✅ codex wrapper"

# ---- codex-use ----
cat > "$HOME/bin/codex-use" << 'SCRIPT_EOF'
#!/bin/bash
# =============================================================================
# codex-use — profile 切换（便携版，无加密）
# 用法: codex-use <profile>
#
# 1. 备份 ~/.codex/config.toml 和 auth.json
# 2. 从 ~/.codex-pool/<profile>/ 复制配置
# 3. 启动子 shell，exit 后自动恢复
# =============================================================================
set -e

POOL_DIR="$HOME/.codex-pool"
CODX_DIR="$HOME/.codex"
CODX_CONFIG="$CODX_DIR/config.toml"
CODX_AUTH="$CODX_DIR/auth.json"

PROFILE="${1}"

if [ -z "$PROFILE" ]; then
    echo "用法: codex-use <profile>"
    echo "可用配置:"
    ls -1 "$POOL_DIR/" 2>/dev/null || echo "  (无)"
    exit 1
fi

PROFILE_DIR="$POOL_DIR/$PROFILE"

if [ ! -d "$PROFILE_DIR" ]; then
    echo "❌ 配置 [$PROFILE] 不存在"
    echo "可用: $(ls -1 "$POOL_DIR/" 2>/dev/null | tr '\n' ' ')"
    exit 1
fi

# 备份当前配置
BACKUP_CONFIG=""
if [ -f "$CODX_CONFIG" ]; then
    BACKUP_CONFIG="$CODX_CONFIG.bak.$$"
    cp "$CODX_CONFIG" "$BACKUP_CONFIG"
fi

BACKUP_AUTH=""
if [ -f "$CODX_AUTH" ]; then
    BACKUP_AUTH="$CODX_AUTH.bak.$$"
    cp "$CODX_AUTH" "$BACKUP_AUTH"
fi

# cleanup
cleanup() {
    echo ""
    echo "🧹 正在恢复..."
    if [ -n "$BACKUP_CONFIG" ] && [ -f "$BACKUP_CONFIG" ]; then
        mv "$BACKUP_CONFIG" "$CODX_CONFIG"
        echo "   🔄 config.toml 已恢复"
    else
        rm -f "$CODX_CONFIG"
    fi
    if [ -n "$BACKUP_AUTH" ] && [ -f "$BACKUP_AUTH" ]; then
        mv "$BACKUP_AUTH" "$CODX_AUTH"
        echo "   🔄 auth.json 已恢复"
    else
        rm -f "$CODX_AUTH"
    fi
}
trap cleanup EXIT

# 复制 profile 配置
mkdir -p "$CODX_DIR"
if [ -f "$PROFILE_DIR/config.toml" ]; then
    cp "$PROFILE_DIR/config.toml" "$CODX_CONFIG"
    chmod 600 "$CODX_CONFIG"
fi
if [ -f "$PROFILE_DIR/auth.json" ]; then
    cp "$PROFILE_DIR/auth.json" "$CODX_AUTH"
    chmod 600 "$CODX_AUTH"
fi

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  ✅ 已切换至 [$PROFILE]                ║"
echo "║  直接运行 codex 即可                   ║"
echo "║  输入 exit 退出并自动恢复原配置        ║"
echo "╚══════════════════════════════════════════╝"
echo ""

export PS1="(codex:$PROFILE) \$PS1"
bash
echo ""
echo "👋 已退出，原配置已恢复"
SCRIPT_EOF
chmod 700 "$HOME/bin/codex-use"
echo "✅ codex-use"

# ---- bashrc / zshrc ----
MARKER="# >>> CODEX_USE_SETUP >>>"
if [ -f "$HOME/.bashrc" ]; then
    if ! grep -q "$MARKER" "$HOME/.bashrc" 2>/dev/null; then
        cat >> "$HOME/.bashrc" << 'BASHRC_EOF'

# >>> CODEX_USE_SETUP >>>
export PATH="$HOME/bin:$PATH"
# <<< CODEX_USE_SETUP <<<
BASHRC_EOF
        echo "✅ ~/.bashrc"
    else
        echo "⏭️  ~/.bashrc (已有)"
    fi
fi

if [ -f "$HOME/.zshrc" ]; then
    if ! grep -q "$MARKER" "$HOME/.zshrc" 2>/dev/null; then
        cat >> "$HOME/.zshrc" << 'ZSHRC_EOF'

# >>> CODEX_USE_SETUP >>>
export PATH="$HOME/bin:$PATH"
# <<< CODEX_USE_SETUP <<<
ZSHRC_EOF
        echo "✅ ~/.zshrc"
    else
        echo "⏭️  ~/.zshrc (已有)"
    fi
fi

# ---- 示例 profile ----
if [ ! -d "$HOME/.codex-pool/example" ]; then
    mkdir -p "$HOME/.codex-pool/example"
    cat > "$HOME/.codex-pool/example/config.toml" << 'TEMPLATE_EOF'
model_provider = "my-provider"
model = "gpt-5.2"
model_reasoning_effort = "high"
disable_response_storage = true

[model_providers.my-provider]
name = "my-provider"
base_url = "https://your-relay.com/v1"
wire_api = "responses"
requires_openai_auth = true
TEMPLATE_EOF
    echo "{}" > "$HOME/.codex-pool/example/auth.json"
    chmod 600 "$HOME/.codex-pool/example/config.toml" "$HOME/.codex-pool/example/auth.json"
    echo "✅ ~/.codex-pool/example/ (模板)"
fi

echo ""
echo "============================================"
echo "  🎉 部署完成"
echo "============================================"
echo ""
echo "使用:"
echo "  1. 把各中转站的 config.toml + auth.json 放到 ~/.codex-pool/<名称>/"
echo "  2. source ~/.bashrc (或新开终端)"
echo "  3. codex-use <名称>"
echo "  4. exit 恢复默认"
echo ""
echo "添加新配置:"
echo "  mkdir -p ~/.codex-pool/新名称"
echo "  nano ~/.codex-pool/新名称/config.toml"
echo "  nano ~/.codex-pool/新名称/auth.json"
