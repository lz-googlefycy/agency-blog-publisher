#!/usr/bin/env bash
# install-publishing-toolchain.sh
# 一键安装多平台博客发布工具链（Linux x86_64 / amd64）
#
# 安装内容：
#   1. @wechatsync/cli          — 主通道 CLI
#   2. Wechatsync MCP server    — 源码 build（对接 opencode/claude-code）
#   3. Wechatsync Chrome 扩展   — 源码 build，生成 dist 供你手动加载
#   4. xiaohongshu-mcp          — 小红书兜底（Go 二进制）
#   5. biliup                   — B 站视频投稿 CLI（Rust 二进制）
#   6. bilibili-api-python      — B 站专栏/动态 Python SDK
#   7. xhs (ReaJason/xhs)       — 小红书 API 逆向 Python 包（只读/搜索用）
#
# 所有工具装到 ~/tools/publishing-toolchain/bin/ 或系统路径
# 运行：bash install-publishing-toolchain.sh [组件名...]
#       不带参数 = 全装；带参数 = 只装指定的（wechatsync/xhs-mcp/biliup/bilibili-api）

set -euo pipefail

TOOLCHAIN_DIR="$HOME/tools/publishing-toolchain"
WECHATSYNC_SRC="$HOME/tools/Wechatsync"
BIN_DIR="$TOOLCHAIN_DIR/bin"
LOG="$TOOLCHAIN_DIR/install.log"

mkdir -p "$BIN_DIR"
: > "$LOG"

# ----- 颜色输出 -----
c_info()  { printf "\033[1;34m[INFO]\033[0m  %s\n" "$*" | tee -a "$LOG"; }
c_ok()    { printf "\033[1;32m[OK]\033[0m    %s\n" "$*" | tee -a "$LOG"; }
c_warn()  { printf "\033[1;33m[WARN]\033[0m  %s\n" "$*" | tee -a "$LOG"; }
c_err()   { printf "\033[1;31m[ERR]\033[0m   %s\n" "$*" | tee -a "$LOG"; }

# ----- 网络设置（代理 + 镜像）-----
setup_network() {
  c_info "配置网络代理和镜像..."
  # 使用全局已有的代理
  : "${HTTPS_PROXY:=http://127.0.0.1:41211}"
  : "${HTTP_PROXY:=http://127.0.0.1:41211}"
  export HTTPS_PROXY HTTP_PROXY https_proxy="$HTTPS_PROXY" http_proxy="$HTTP_PROXY"
  # npm 镜像
  npm config set registry https://registry.npmmirror.com/ >/dev/null 2>&1 || true
  # pip 镜像
  pip config set global.index-url https://mirrors.aliyun.com/pypi/simple/ >/dev/null 2>&1 || true
  c_ok "网络配置完成"
}

# ----- 选择要装的组件 -----
declare -A WANT
if [[ $# -eq 0 ]]; then
  WANT[wechatsync]=1
  WANT[xhs-mcp]=1
  WANT[biliup]=1
  WANT[bilibili-api]=1
  WANT[xhs-py]=1
else
  for arg in "$@"; do WANT[$arg]=1; done
fi

# ============================================================
# 1. Wechatsync CLI（npm 全局）
# ============================================================
install_wechatsync_cli() {
  c_info "==> 1. 安装 @wechatsync/cli"
  if command -v wechatsync >/dev/null 2>&1; then
    c_ok "已安装: $(wechatsync --version)"
    return
  fi
  npm install -g @wechatsync/cli 2>&1 | tee -a "$LOG" | tail -5
  command -v wechatsync >/dev/null && c_ok "wechatsync CLI OK" || c_err "wechatsync 安装失败"
}

# ============================================================
# 2. Wechatsync MCP server（源码 build）
# ============================================================
install_wechatsync_mcp() {
  c_info "==> 2. Build Wechatsync MCP server"

  # 克隆源码（如不存在）
  if [[ ! -d "$WECHATSYNC_SRC" ]]; then
    c_info "克隆 Wechatsync 源码到 $WECHATSYNC_SRC..."
    git clone --depth 1 -b v2 https://github.com/wechatsync/Wechatsync.git "$WECHATSYNC_SRC" 2>&1 | tail -3
  fi

  # 拉最新
  (cd "$WECHATSYNC_SRC" && git fetch --depth 1 origin v2 2>&1 | tail -2 && git reset --hard origin/v2 2>&1 | tail -2) || c_warn "git update 失败，使用现有版本"

  # pnpm 依赖 + build
  if ! command -v pnpm >/dev/null 2>&1; then
    corepack enable 2>/dev/null || npm install -g pnpm 2>&1 | tail -3
  fi

  (cd "$WECHATSYNC_SRC" && pnpm config set registry https://registry.npmmirror.com/ >/dev/null 2>&1 || true)

  # 单独 build mcp-server（避开 workspace 问题）
  local MCP_SRC="$WECHATSYNC_SRC/packages/mcp-server"
  local MCP_DIST="$MCP_SRC/dist/index.js"
  if [[ -f "$MCP_DIST" ]]; then
    c_ok "mcp-server 已 build: $MCP_DIST"
  else
    c_info "Build mcp-server..."
    (cd "$WECHATSYNC_SRC" && pnpm install --ignore-scripts 2>&1 | tail -5) || true
    (cd "$MCP_SRC" && npx tsup 2>&1 | tail -10)
  fi

  if [[ -f "$MCP_DIST" ]]; then
    c_ok "MCP server: $MCP_DIST"
    echo "$MCP_DIST" > "$TOOLCHAIN_DIR/wechatsync-mcp-path.txt"
  else
    c_err "MCP server build 失败"
  fi
}

# ============================================================
# 3. Wechatsync Chrome 扩展（源码 build → 你手动加载到 Chrome）
# ============================================================
install_wechatsync_extension() {
  c_info "==> 3. Build Wechatsync Chrome 扩展"
  local EXT_SRC="$WECHATSYNC_SRC/packages/extension"
  local EXT_DIST="$EXT_SRC/dist"
  if [[ -f "$EXT_DIST/manifest.json" ]]; then
    c_ok "扩展已 build: $EXT_DIST"
    return
  fi
  (cd "$WECHATSYNC_SRC" && pnpm --filter @wechatsync/extension build 2>&1 | tail -10) || true
  if [[ -f "$EXT_DIST/manifest.json" ]]; then
    c_ok "扩展 dist: $EXT_DIST"
    echo "$EXT_DIST" > "$TOOLCHAIN_DIR/wechatsync-extension-path.txt"
  else
    c_warn "扩展 build 失败，改用 Chrome Web Store 方式（见 SETUP.md）"
  fi
}

# ============================================================
# 4. xiaohongshu-mcp（小红书兜底，Go 二进制）
# ============================================================
install_xhs_mcp() {
  c_info "==> 4. 安装 xiaohongshu-mcp（Go 二进制）"
  local TARGET_LOGIN="$BIN_DIR/xiaohongshu-login"
  local TARGET_MCP="$BIN_DIR/xiaohongshu-mcp"

  if [[ -x "$TARGET_MCP" ]]; then
    c_ok "已安装: $TARGET_MCP"
    return
  fi

  # 从 GitHub Releases 下载 Linux amd64
  local API_URL="https://api.github.com/repos/xpzouying/xiaohongshu-mcp/releases/latest"
  local TAG
  TAG=$(curl -sSL "$API_URL" | grep -oP '"tag_name":\s*"\K[^"]+' | head -1)
  if [[ -z "$TAG" ]]; then
    c_warn "获取 release tag 失败，尝试源码编译"
    install_xhs_mcp_from_source
    return
  fi
  c_info "latest tag: $TAG"

  local BASE_URL="https://github.com/xpzouying/xiaohongshu-mcp/releases/download/$TAG"
  # 常见命名：xiaohongshu-mcp-linux-amd64, xiaohongshu-login-linux-amd64
  for name in "xiaohongshu-mcp-linux-amd64" "xiaohongshu-mcp_linux_amd64"; do
    if curl -fsSL -o "$TARGET_MCP" "$BASE_URL/$name" 2>>"$LOG"; then
      chmod +x "$TARGET_MCP" && break
    fi
  done
  for name in "xiaohongshu-login-linux-amd64" "xiaohongshu-login_linux_amd64"; do
    if curl -fsSL -o "$TARGET_LOGIN" "$BASE_URL/$name" 2>>"$LOG"; then
      chmod +x "$TARGET_LOGIN" && break
    fi
  done

  if [[ -x "$TARGET_MCP" ]]; then
    c_ok "xiaohongshu-mcp: $TARGET_MCP"
  else
    c_warn "二进制下载失败，fallback 源码编译"
    install_xhs_mcp_from_source
  fi
}

install_xhs_mcp_from_source() {
  if ! command -v go >/dev/null 2>&1; then
    c_warn "未装 go，跳过 xiaohongshu-mcp。可手动装 go 后重跑"
    return
  fi
  local WORK="$TOOLCHAIN_DIR/xiaohongshu-mcp-src"
  [[ -d "$WORK" ]] || git clone --depth 1 https://github.com/xpzouying/xiaohongshu-mcp.git "$WORK" 2>&1 | tail -3
  (cd "$WORK" && go build -o "$BIN_DIR/xiaohongshu-mcp" . 2>&1 | tail -5 && c_ok "源码编译完成")
}

# ============================================================
# 5. biliup（B 站视频投稿 CLI）
# ============================================================
install_biliup() {
  c_info "==> 5. 安装 biliup（B 站视频）"
  if command -v biliup >/dev/null 2>&1; then
    c_ok "已安装: $(biliup --version 2>&1 | head -1)"
    return
  fi

  # 下载预编译 Linux 二进制
  local API="https://api.github.com/repos/biliup/biliup-rs/releases/latest"
  local TAG URL
  TAG=$(curl -sSL "$API" | grep -oP '"tag_name":\s*"\K[^"]+' | head -1)
  if [[ -z "$TAG" ]]; then
    c_warn "获取 biliup tag 失败"
    return
  fi
  URL="https://github.com/biliup/biliup-rs/releases/download/$TAG/biliupR-$TAG-x86_64-linux.tar.xz"
  c_info "下载 $URL"

  local TMP="$(mktemp -d)"
  if curl -fsSL -o "$TMP/biliup.tar.xz" "$URL" 2>>"$LOG"; then
    tar -xf "$TMP/biliup.tar.xz" -C "$TMP" 2>&1 | tee -a "$LOG"
    local BIN
    BIN=$(find "$TMP" -name biliup -type f | head -1)
    if [[ -n "$BIN" ]]; then
      cp "$BIN" "$BIN_DIR/biliup" && chmod +x "$BIN_DIR/biliup"
      c_ok "biliup: $BIN_DIR/biliup"
    else
      c_warn "解压后未找到 biliup 二进制"
    fi
  else
    c_warn "biliup 下载失败，请手动从 https://github.com/biliup/biliup-rs/releases 下载"
  fi
  rm -rf "$TMP"
}

# ============================================================
# 6. bilibili-api-python（B 站专栏/动态/视频 Python SDK）
# ============================================================
install_bilibili_api_python() {
  c_info "==> 6. 安装 bilibili-api-python"
  if pip show bilibili-api-python >/dev/null 2>&1; then
    c_ok "已安装: $(pip show bilibili-api-python | grep Version)"
    return
  fi
  pip install --user bilibili-api-python 2>&1 | tail -5
  pip show bilibili-api-python >/dev/null 2>&1 && c_ok "bilibili-api-python OK" || c_err "失败"
}

# ============================================================
# 7. xhs (ReaJason/xhs, 小红书 Python 包，主要用于搜索/读)
# ============================================================
install_xhs_py() {
  c_info "==> 7. 安装 xhs (ReaJason/xhs) Python 包"
  if pip show xhs >/dev/null 2>&1; then
    c_ok "已安装: $(pip show xhs | grep Version)"
    return
  fi
  pip install --user xhs 2>&1 | tail -5
  pip show xhs >/dev/null 2>&1 && c_ok "xhs OK" || c_warn "失败（可选，不影响主流程）"
}

# ============================================================
# Main
# ============================================================
setup_network
c_info "安装日志: $LOG"
c_info "组件选择: ${!WANT[*]}"

[[ -n "${WANT[wechatsync]:-}" ]] && install_wechatsync_cli
[[ -n "${WANT[wechatsync]:-}" ]] && install_wechatsync_mcp
[[ -n "${WANT[wechatsync]:-}" ]] && install_wechatsync_extension
[[ -n "${WANT[xhs-mcp]:-}" ]] && install_xhs_mcp
[[ -n "${WANT[biliup]:-}" ]] && install_biliup
[[ -n "${WANT[bilibili-api]:-}" ]] && install_bilibili_api_python
[[ -n "${WANT[xhs-py]:-}" ]] && install_xhs_py

# ============================================================
# 总结
# ============================================================
echo
c_info "========================================"
c_info "安装完成总结"
c_info "========================================"
printf "%-28s %s\n" "wechatsync CLI:" "$(command -v wechatsync 2>/dev/null || echo '未装')"
printf "%-28s %s\n" "wechatsync MCP server:" "$([[ -f $WECHATSYNC_SRC/packages/mcp-server/dist/index.js ]] && echo $WECHATSYNC_SRC/packages/mcp-server/dist/index.js || echo '未装')"
printf "%-28s %s\n" "wechatsync extension dist:" "$([[ -f $WECHATSYNC_SRC/packages/extension/dist/manifest.json ]] && echo $WECHATSYNC_SRC/packages/extension/dist || echo '未 build（用 Chrome Web Store 装）')"
printf "%-28s %s\n" "xiaohongshu-mcp:" "$([[ -x $BIN_DIR/xiaohongshu-mcp ]] && echo $BIN_DIR/xiaohongshu-mcp || echo '未装')"
printf "%-28s %s\n" "biliup:" "$([[ -x $BIN_DIR/biliup ]] && echo $BIN_DIR/biliup || echo '未装')"
printf "%-28s %s\n" "bilibili-api-python:" "$(pip show bilibili-api-python 2>/dev/null | grep Version | awk '{print $2}' || echo '未装')"
printf "%-28s %s\n" "xhs (Python):" "$(pip show xhs 2>/dev/null | grep Version | awk '{print $2}' || echo '未装')"
echo
c_info "把 $BIN_DIR 加入 PATH 以便使用 xiaohongshu-mcp 和 biliup:"
echo "  export PATH=\"$BIN_DIR:\$PATH\""
echo
c_info "下一步：阅读 $TOOLCHAIN_DIR/SETUP.md 完成手动配置（Chrome 扩展、扫码登录、token）"
