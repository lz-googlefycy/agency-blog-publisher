---
name: multi-platform-publishing
description: Use when user wants to publish a blog article to multiple Chinese content platforms (知乎/小红书/CSDN/B站专栏/B站视频/公众号/掘金). Orchestrates Wechatsync CLI+MCP as the main channel, with xiaohongshu-mcp and biliup as specialized fallbacks. Covers content adaptation per platform (via subagents), draft-first publishing, and anti-risk-control best practices.
---

# Multi-Platform Blog Publishing

Orchestrates one-click blog publishing to 知乎 / 小红书 / CSDN / B站 using Wechatsync as the main CLI+MCP channel, with specialized fallbacks.

## Default Environment Layout

- **Quick CLI**: `publish` (alias of `~/tools/publishing-toolchain/publish.sh`)
- **Wechatsync CLI**: `wechatsync` v1.0.0
- **Token**: `<YOUR_WECHATSYNC_TOKEN>` (in env `WECHATSYNC_TOKEN`)
- **Wechatsync MCP**: enabled in `~/.config/opencode/opencode.json` → tools `list_platforms` / `check_auth` / `sync_article` / `extract_article` / `upload_image_file`
- **Already-logged-in** (verified): 知乎「<your-zhihu-account>」、CSDN「<your-csdn-account>」、B 站「<your-bilibili-account>」、微信公众号
- **Pending**: 掘金
- **小红书 fallback path**: `~/tools/publishing-toolchain/bin/xiaohongshu-mcp` (port 18060)
- **B 站视频**: `biliup` (Python 1.1.29 via pip, in PATH)
- **Default blog dir**: `~/blog/<slug>/article.md`

⚠️ **Wechatsync v2.0.9 build 没有 xhs adapter** — 不要用 Wechatsync 发小红书，直接 `publish xhs-server` + `publish xhs ...` 走兜底。

**Companion docs**:
- `~/tools/publishing-toolchain/USAGE.md` — 使用手册
- `~/tools/publishing-toolchain/WORKFLOWS.md` — 4 个工作流 SOP
- `~/tools/publishing-toolchain/CHEATSHEET.md` — 命令速查
- `~/docs/plans/2026-05-08-multi-platform-publishing-design.md` — 调研与架构

---

## Quick Matrix

| Platform | Main Tool | Fallback | Notes |
|----------|-----------|----------|-------|
| 知乎 | `publish sync x.md zhihu` | `delankesita/zhihu-publisher` (pip) | title+body+cover, draft by default |
| **小红书** | **`publish xhs ...`** (xiaohongshu-mcp) | — | Wechatsync 这版没 build；title ≤20 chars, content ≤1000 |
| CSDN | `publish sync x.md csdn` | — | supports category/tag/cover |
| B站专栏 | `publish sync x.md bilibili` | `Nemo2011/bilibili-api` (Python) | |
| B站动态 | `Nemo2011/bilibili-api` (`dynamic.py`/`opus.py`) | — | Wechatsync doesn't cover |
| B站视频 | **`biliup`** (Python via pip) | `Nemo2011/bilibili-api` | Wechatsync doesn't cover |
| 公众号 | `publish sync x.md weixin` | — | already logged in |
| 掘金 | `publish sync x.md juejin` | — | needs login first (推荐 GitHub 一键) |

## Rules

1. **Always draft first**: never auto-publish. Wechatsync defaults to drafts; confirm with user before anything goes live
2. **Verify prerequisites before invoking tools**:
   - `command -v wechatsync` exists
   - `echo $WECHATSYNC_TOKEN` non-empty
   - `wechatsync platforms --auth` shows target platforms as authed
3. **Respect per-platform constraints**:
   - 小红书 title ≤ 20 chars, body ≤ 1000 chars, 1-18 images
   - 知乎/CSDN 每日 ≤ 5 篇建议
   - Add 30~180s jitter between posts if batching
4. **Don't fabricate MCP calls**: if a tool isn't installed, output the exact install command instead of claiming to call it
5. **Content adaptation is mandatory**: the same article goes through platform-specific subagents before publishing (see workflow below)
6. **Use TodoWrite for multi-platform jobs** (≥2 platforms)

## Parameters (collect before execution)

| Param | Required | Example |
|-------|----------|---------|
| `source_markdown` | ✅ | `/path/to/article.md` or inline content |
| `target_platforms` | ✅ | `zhihu,csdn,bilibili,xiaohongshu` |
| `mode` | ✅ | `draft` (default) / `publish-after-confirm` |
| `cover_image` | optional | `/path/to/cover.png` |
| `tags` | optional | `AI,Python` |
| `category` | optional | `人工智能` (CSDN/B站) |

**Present in table, ask for missing, never guess.**

---

## End-to-End Workflow

```
┌──────────────────────────────────────────────────────┐
│ Step 1. Confirm topic + scope                        │
│   - Collect params above                             │
│   - Show as table, user confirms                     │
└─────────────────┬────────────────────────────────────┘
                  ↓
┌──────────────────────────────────────────────────────┐
│ Step 2. Produce master draft                         │
│   @content-creator generates source_article.md       │
│   (unless user provides one)                         │
└─────────────────┬────────────────────────────────────┘
                  ↓
┌──────────────────────────────────────────────────────┐
│ Step 3. Per-platform adaptation (parallel subagents) │
│   @zhihu-strategist          → zhihu.md              │
│   @bilibili-content-strategist → bilibili.md         │
│   @xiaohongshu-specialist    → xhs.md (≤20 title!)  │
│   CSDN: use master directly (tech depth works)       │
└─────────────────┬────────────────────────────────────┘
                  ↓
┌──────────────────────────────────────────────────────┐
│ Step 4. Preflight check                              │
│   - wechatsync platforms --auth                      │
│   - Validate title/body length per platform          │
│   - Confirm images accessible                        │
└─────────────────┬────────────────────────────────────┘
                  ↓
┌──────────────────────────────────────────────────────┐
│ Step 5. Sync as drafts (never auto-publish)          │
│   wechatsync sync zhihu.md    -p zhihu               │
│   wechatsync sync bilibili.md -p bilibili            │
│   wechatsync sync csdn.md     -p csdn                │
│   wechatsync sync xhs.md      -p xiaohongshu         │
│     └─ if xiaohongshu fails: fall back to xhs-mcp    │
└─────────────────┬────────────────────────────────────┘
                  ↓
┌──────────────────────────────────────────────────────┐
│ Step 6. Report + manual publish                      │
│   - Give user URLs of each platform's draft          │
│   - User reviews and clicks publish on each          │
└──────────────────────────────────────────────────────┘
```

---

## Command Reference

### Recommended: `publish` swiss-army CLI

```bash
publish status                         # auth + port health
publish refresh                        # force-refresh login state (after login new platform)
publish fix                            # auto-clear stuck port 9527
publish dry FILE.md zhihu              # preview without actual sync
publish sync FILE.md zhihu,csdn,bilibili [cover.png]
publish extract [out.md]               # from current Chrome tab
publish xhs-server                     # start xiaohongshu-mcp daemon (port 18060)
publish xhs FILE.md "title ≤20 chars" img.jpg[,img2.jpg]
```

### Lower-level: Wechatsync CLI direct

```bash
wechatsync auth [-r]                                # check auth
wechatsync sync article.md -p zhihu,csdn,bilibili --cover cover.png
wechatsync extract -o article.md
wechatsync platforms                                 # list supported
```

### xiaohongshu-mcp (xhs fallback)

```bash
# One-time login
./xiaohongshu-login-darwin-arm64     # or linux-amd64 / windows

# Start MCP server
./xiaohongshu-mcp-darwin-arm64 &     # listens on :18060

# HTTP publish
curl -X POST http://localhost:18060/api/v1/publish \
  -H 'Content-Type: application/json' \
  -d '{
    "title": "标题（≤20字）",
    "content": "正文",
    "images": ["/abs/path/img1.jpg"],
    "tags": ["AI", "Python"],
    "schedule_at": "2026-05-09T10:00:00+08:00",
    "visibility": "public",
    "is_original": true
  }'
```

### biliup (B 站视频)

```bash
biliup login                         # scan QR once → cookies.json
biliup upload --title "标题" --desc "简介" \
              --tag "Python,AI" --tid 171 \
              --cover cover.jpg --copyright 1 \
              --dtime 1728000 --line bda2 \
              video.mp4
```

### Nemo2011/bilibili-api (B 站专栏/动态 Python)

```python
from bilibili_api import article, dynamic, Credential
credential = Credential(sessdata="...", bili_jct="...", buvid3="...")
# See module docs for publish() / addupdate() signatures
```

---

## Error Handling

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| `wechatsync` command not found | CLI not installed | `npm install -g @wechatsync/cli` |
| `platforms --auth` shows ✗ for a platform | Not logged in browser | Open Chrome → login to that platform → retry |
| `MCP_TOKEN mismatch` | Token in env ≠ token in extension settings | Reset one to match the other |
| 小红书 sync fails repeatedly | Platform risk control | Switch to xhs-mcp fallback, add 5+ min delay |
| CSDN title too long | CSDN has title length limit | Truncate to ≤ 80 chars |
| 小红书 title error | `title > 20 chars` | Truncate ruthlessly |
| B 站 cookie expired | SESSDATA rotates every 7-30 days | Re-scan QR or refresh via bilibili-api |

---

## Rate & Risk Rules

- **Per day**: 知乎/CSDN ≤5, 小红书 ≤50, 掘金 ≤10
- **Between posts**: 30-180s random jitter
- **Avoid**: round hours, same-minute batch, same image MD5 across posts (小红书)
- **Same account, single endpoint**: don't login 小红书 in two browser tabs while xhs-mcp is running (kicks each other out)
- **Cookie hygiene**: `chmod 600` on all cookie files, never commit to public repo

## Prerequisites Checklist

Before first use, verify these are done:

```bash
# Required (Wechatsync main channel)
command -v node >/dev/null                          # Node 18+
command -v wechatsync >/dev/null                    # npm i -g @wechatsync/cli
test -n "$WECHATSYNC_TOKEN"                         # token set
# Chrome extension installed + logged in to target platforms

# Optional (fallbacks)
test -f ~/.biliup/cookies.json                      # biliup login once
test -x ~/.local/bin/xiaohongshu-mcp                # xhs-mcp binary
python -c "import bilibili_api"                      # Nemo bilibili-api
```

If any required item missing → emit exact install commands, don't proceed.

---

## Integration with agency-agents

Pair this skill with:
- `@content-creator` → source draft
- `@zhihu-strategist` → 知乎 adaptation
- `@bilibili-content-strategist` → B 站 adaptation
- `@xiaohongshu-specialist` → 小红书 adaptation (enforces title ≤20)
- `@marketing-multi-platform-publisher` → orchestrates the above + this skill's CLI calls
- `@seo-specialist` → CSDN keyword/tag optimization

## References

- Design doc: `~/docs/plans/2026-05-08-multi-platform-publishing-design.md`
- Wechatsync: https://github.com/wechatsync/Wechatsync
- xiaohongshu-mcp: https://github.com/xpzouying/xiaohongshu-mcp
- biliup: https://github.com/biliup/biliup
- bilibili-api: https://github.com/Nemo2011/bilibili-api
