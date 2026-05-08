#!/usr/bin/env bash
# publish.sh — 发博客的瑞士军刀
# 用法：
#   publish.sh status                          # 看登录状态
#   publish.sh refresh                         # 强制刷新登录
#   publish.sh fix                             # 端口冲突自动修复
#   publish.sh dry FILE.md zhihu,csdn          # 干跑预演
#   publish.sh sync FILE.md zhihu,csdn,bilibili # 真同步
#   publish.sh extract URL_OR_BLANK            # 提取当前浏览器文章
#   publish.sh xhs-server                      # 启 xhs-mcp 后台
#   publish.sh xhs FILE.md "title" img1[,img2]  # 发小红书
#   publish.sh help                            # 显示帮助
set -euo pipefail

# Token must be set via env or ~/.bashrc — see docs/SETUP.md
if [[ -z "${WECHATSYNC_TOKEN:-}" ]]; then
  echo "[!] WECHATSYNC_TOKEN not set." >&2
  echo "    1. Open Chrome → Wechatsync extension → toggle CLI/MCP connection" >&2
  echo "    2. Copy the generated token" >&2
  echo "    3. echo 'export WECHATSYNC_TOKEN=\"<your-token>\"' >> ~/.bashrc && source ~/.bashrc" >&2
  echo "    See docs/SETUP.md for the full guide." >&2
  exit 1
fi

# Toolchain bin on PATH (override INSTALL_DIR if you put binaries elsewhere)
INSTALL_DIR="${INSTALL_DIR:-$HOME/tools/publishing-toolchain}"
export PATH="$INSTALL_DIR/bin:$HOME/.local/bin:$PATH"

cmd="${1:-help}"; shift || true

c_blue()  { printf "\033[1;34m%s\033[0m\n" "$*"; }
c_green() { printf "\033[1;32m%s\033[0m\n" "$*"; }
c_red()   { printf "\033[1;31m%s\033[0m\n" "$*"; }

case "$cmd" in
  status)
    c_blue "[1/2] 检查 9527 端口状态..."
    if ss -lntp 2>/dev/null | grep -q ':9527'; then
      c_red "  端口 9527 被占用（如 CLI 报错请运行 publish.sh fix）"
    else
      c_green "  端口干净"
    fi
    c_blue "[2/2] 平台登录状态..."
    timeout 30 wechatsync auth 2>&1
    ;;

  refresh)
    c_blue "强制刷新登录状态..."
    timeout 60 wechatsync auth -r 2>&1
    ;;

  fix)
    c_blue "清理残留进程..."
    pkill -f "wechatsync" 2>/dev/null || true
    pkill -f "mcp-server" 2>/dev/null || true
    sleep 2
    if ss -lntp 2>/dev/null | grep -q ':9527'; then
      c_red "  端口仍被占用："
      ss -lntp 2>/dev/null | grep ':9527'
      c_red "  请手动 kill 进程，或重启 Chrome 扩展"
      exit 1
    fi
    c_green "✓ 已清理。请到 Chrome 扩展弹窗 MCP 开关 关-开 重启 ws"
    ;;

  dry)
    file="${1:?用法: publish.sh dry FILE.md PLATFORMS}"
    platforms="${2:?指定平台}"
    c_blue "[预演] $file → $platforms"
    timeout 60 wechatsync sync "$file" -p "$platforms" --dry-run
    ;;

  sync)
    file="${1:?用法: publish.sh sync FILE.md PLATFORMS [COVER]}"
    platforms="${2:?指定平台}"
    cover="${3:-}"
    c_blue "[同步] $file → $platforms"
    if [[ -n "$cover" ]]; then
      timeout 120 wechatsync sync "$file" -p "$platforms" --cover "$cover"
    else
      timeout 120 wechatsync sync "$file" -p "$platforms"
    fi
    ;;

  extract)
    out="${1:-/tmp/extracted-$(date +%H%M%S).md}"
    c_blue "[提取] 浏览器当前页 → $out"
    timeout 60 wechatsync extract -o "$out"
    c_green "✓ 已保存到 $out"
    ;;

  xhs-server)
    c_blue "启动 xiaohongshu-mcp..."
    if pgrep -f "xiaohongshu-mcp" >/dev/null; then
      c_green "已在运行"
      exit 0
    fi
    nohup xiaohongshu-mcp -headless=false > /tmp/xhs-mcp.log 2>&1 &
    sleep 3
    if pgrep -f "xiaohongshu-mcp" >/dev/null; then
      c_green "✓ xhs-mcp 已启动 (port 18060)，日志: /tmp/xhs-mcp.log"
    else
      c_red "启动失败，看日志: tail /tmp/xhs-mcp.log"
    fi
    ;;

  xhs)
    file="${1:?用法: publish.sh xhs FILE.md \"title\" img1.jpg[,img2.jpg]}"
    title="${2:?标题（≤20字）}"
    images_csv="${3:-}"
    if [[ ${#title} -gt 20 ]]; then
      c_red "标题超过 20 字（${#title} 字），小红书会拒绝"; exit 1
    fi
    content="$(cat "$file")"
    if [[ ${#content} -gt 1000 ]]; then
      c_red "正文超过 1000 字（${#content} 字），小红书会拒绝"; exit 1
    fi
    images_json="[]"
    if [[ -n "$images_csv" ]]; then
      images_json=$(echo "$images_csv" | tr ',' '\n' | jq -R . | jq -sc .)
    fi
    payload=$(jq -n \
      --arg title "$title" \
      --arg content "$content" \
      --argjson images "$images_json" \
      '{title: $title, content: $content, images: $images, tags: [], is_original: true}')
    c_blue "[小红书] $title → $images_csv"
    curl -X POST http://localhost:18060/api/v1/publish \
      -H 'Content-Type: application/json' \
      -d "$payload"
    ;;

  help|*)
    cat <<HELP
publish.sh — 发博客瑞士军刀

📊 状态查询
  publish.sh status         登录状态 + 端口检查
  publish.sh refresh        强制刷新登录态
  publish.sh fix            修端口冲突

📤 发文（Wechatsync）
  publish.sh dry  FILE.md PLATFORMS         干跑（不实际发）
  publish.sh sync FILE.md PLATFORMS [COVER] 同步到草稿
                                            COVER 可选，封面图路径
📥 提取
  publish.sh extract [OUT.md]               从浏览器当前页提取

🌸 小红书（独立工具）
  publish.sh xhs-server                     启 xhs-mcp 后台
  publish.sh xhs FILE.md "title" img.jpg[,img2] 发图文笔记

📚 帮助
  publish.sh help                           本帮助

平台 ID: zhihu csdn juejin bilibili weixin segmentfault oschina cnblogs ...
完整文档: ~/tools/publishing-toolchain/USAGE.md / WORKFLOWS.md / CHEATSHEET.md
HELP
    ;;
esac
