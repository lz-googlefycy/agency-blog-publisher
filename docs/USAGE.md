# 多平台博客发布 — 使用手册

> Daily-use handbook for content creators。从写一篇博客到发布到知乎/CSDN/B站等的完整流程。
> 最后更新：2026-05-08

---

## 0. 当下状态（已就绪）

| 项 | 值 |
|---|---|
| Wechatsync CLI | `wechatsync` 命令全局可用，v1.0.0 |
| Wechatsync MCP server | 已编译 + opencode.json 已加载 |
| Chrome 扩展 | 装在你的 Chrome，已开 MCP，状态「已连接」|
| Token | `<YOUR_WECHATSYNC_TOKEN>`（写入 `~/.bashrc` + `opencode.json`）|
| **已登录账号** | 知乎「<your-zhihu-account>」、B 站「<your-bilibili-account>」、CSDN「<your-csdn-account>」、微信公众号 |
| 待登录 | 掘金（GitHub 一键登录最快）、其它非主力平台 |
| 小红书 | Wechatsync v2.0.9 build 暂未含 → 走 `xiaohongshu-mcp` 兜底 |
| B 站视频 | 不是图文场景 → 走 `biliup` |
| Agency-Agents 团队 | 185 个 agent 已装到 opencode + claude-code |

---

## 1. 写一篇博客的全流程（你日常会怎么用）

### 模式 A：你已经写好了 Markdown，只想发布

```bash
# 1. 把文章放到 ~/blog/<slug>/article.md，封面图放 cover.png（可选）
# 2. 一条命令同步成草稿：
wechatsync sync ~/blog/yolo-jetson/article.md \
  -p zhihu,csdn,bilibili \
  --cover ~/blog/yolo-jetson/cover.png
# 3. 在 Chrome 里打开各平台「草稿箱」检查
# 4. 满意就点发布
```

### 模式 B：让 AI 帮你写并发布（推荐）

直接在 OpenCode 会话里说人话：

```
@marketing-multi-platform-publisher
帮我写一篇关于「YOLO11 在 Jetson Orin 上的车牌识别部署经验」的技术博客，
然后发到知乎、CSDN、B 站专栏的草稿箱。
```

这个 agent 会：
1. 调 `@content-creator` 出主稿
2. 调 `@zhihu-strategist`/`@bilibili-content-strategist` 做平台风格化
3. 调 wechatsync MCP 同步成草稿
4. 把每个平台的草稿 URL 回报给你
5. **不会自动发布**（你要手动点发布按钮）

### 模式 C：从已发表文章扒下来发到其它平台

```bash
# 1. 在 Chrome 里打开你公众号已发的文章
# 2. CLI 提取
wechatsync extract -o ~/blog/article.md
# 3. 同步到其它平台
wechatsync sync ~/blog/article.md -p zhihu,csdn,juejin
```

---

## 2. 各场景命令速查

### 检查登录状态

```bash
wechatsync auth          # 看哪些平台登录了
wechatsync auth -r       # 强制刷新 cookie 状态（登录新平台后用）
wechatsync platforms     # 列所有支持的平台
```

### 同步文章

```bash
# 基本用法
wechatsync sync FILE.md -p PLATFORM[,PLATFORM...]

# 常用组合
wechatsync sync x.md -p zhihu                    # 只发知乎
wechatsync sync x.md -p zhihu,csdn,bilibili      # 发 3 平台
wechatsync sync x.md -p zhihu --cover cover.png  # 带封面
wechatsync sync x.md -p zhihu -t "自定义标题"     # 覆盖标题
wechatsync sync x.md -p zhihu --dry-run          # 预演不实际发
```

### 提取网页文章

```bash
wechatsync extract                          # 提取当前 Chrome 标签页文章
wechatsync extract -o ~/blog/saved.md       # 保存到文件
```

---

## 3. 小红书（兜底方案，因 Wechatsync 不支持）

### 一次性登录

```bash
xiaohongshu-login    # 弹 Chrome 窗口扫码登录，cookie 存本地
```

### 启动 MCP server

```bash
xiaohongshu-mcp -headless=false &     # 首次有头模式看登录状态
# 或者
xiaohongshu-mcp -headless=true &      # 后台无头跑
```

### HTTP 调用发布

```bash
curl -X POST http://localhost:18060/api/v1/publish \
  -H 'Content-Type: application/json' \
  -d '{
    "title": "小红书标题（≤20 字）",
    "content": "正文（≤1000 字）",
    "images": ["/abs/path/img1.jpg", "/abs/path/img2.jpg"],
    "tags": ["AI", "数码"],
    "is_original": true
  }'
```

⚠️ 小红书规则：标题 ≤ 20 字，正文 ≤ 1000 字，图 1-18 张。

---

## 4. B 站视频（走 biliup）

### 一次性登录

```bash
biliup login    # 扫码登录，cookies.json 存当前目录
```

### 投稿

```bash
biliup upload --title "标题" \
              --desc "简介" \
              --tag "Python,AI" \
              --tid 171 \
              --cover cover.jpg \
              --copyright 1 \
              video.mp4
```

`--tid` 是分区 ID（171=单机游戏，76=美食，95=数码…），完整列表见 https://biliup.github.io/biliup-rs/。

---

## 5. 在 OpenCode AI 会话里调用（推荐工作流）

OpenCode 已经配好了 `wechatsync` MCP。重启 OpenCode 后，在任意会话里都可以：

### 直接用工具

AI 可以直接调用以下工具（你不用记，AI 会用）：
- `list_platforms` — 列平台 + 登录状态
- `check_auth` — 检查指定平台
- `sync_article` — 同步到指定平台
- `extract_article` — 从浏览器提取
- `upload_image_file` — 上传图片

### 用 agent 编排（最自然）

```
@marketing-multi-platform-publisher 
我有一篇文章 ~/blog/abc.md，帮我发到知乎和 CSDN 草稿箱。
```

```
@zhihu-strategist
看下我这篇文章 ~/blog/abc.md 适合在知乎发哪个话题、用什么标题钩子？
```

```
@content-creator
我想写「车牌识别从训练到 Jetson 部署」这个主题，
帮我出一份大纲，要发到知乎和 CSDN。
```

---

## 6. 故障排查

| 症状 | 原因 | 解决 |
|---|---|---|
| `Invalid or missing token` | 9527 端口被残留进程占用 | `pkill -f wechatsync; pkill -f mcp-server`，再到扩展弹窗把 MCP 开关 关-开 |
| 「Chrome 扩展未连接」 | 扩展 MCP 开关没开 / Chrome 没在前台 | 打开 Chrome，点扩展图标确认显示「已连接」或「等待连接」|
| 某个平台显示「未登录」但其实登了 | cookie 缓存未刷新 | `wechatsync auth -r` 强制刷新 |
| 同步成功但草稿里看不到 | 草稿在哪个平台账号下？ | 看 `wechatsync auth` 显示的账号名是不是你想要的 |
| 标题/正文被截断 | 平台有长度限制 | 知乎标题≤80，小红书标题≤20，B站专栏标题≤40 |
| 小红书发不了 | Wechatsync 这版没 build 进 xhs adapter | 用 `xiaohongshu-mcp` 兜底（见上） |

---

## 7. 安全守则

1. **Token 不要外泄**：`<YOUR_WECHATSYNC_TOKEN>` 已经在 `~/.bashrc` 和 `opencode.json`，不要复制粘贴到聊天/文档
2. **Cookie 在浏览器**：不上传到任何服务器，本地 storage 加密
3. **Wechatsync 默认草稿**：不会自动发布，你不点「发布」就永远只是草稿
4. **频率控制**：每平台每天 ≤ 5 篇为宜，别批量发
5. **小红书原创**：图片做微调（裁剪/亮度），避免被 MD5 检测为搬运

---

## 8. 快捷脚本

`~/tools/publishing-toolchain/publish.sh` 提供了快捷命令（详见 CHEATSHEET.md）。

```bash
publish.sh ~/blog/abc.md zhihu csdn bilibili        # 直接发
publish.sh dry ~/blog/abc.md zhihu                  # 预演
publish.sh status                                    # 看登录状态
publish.sh fix                                       # 端口冲突自动修复
```

---

## 9. 下一步建议

| 优先级 | 任务 |
|---|---|
| P0 | 跑一篇真·测试发布（见 WORKFLOWS.md 第 1 节）|
| P1 | 把掘金登录补上（`https://juejin.cn/login` GitHub 登录最快）|
| P2 | 小红书 xhs-mcp 扫码登录（`xiaohongshu-login`）|
| P3 | 写第一篇正式博客 |

---

## 10. 相关文档

| 文件 | 作用 |
|---|---|
| `~/tools/publishing-toolchain/USAGE.md` | 本文件 |
| `~/tools/publishing-toolchain/WORKFLOWS.md` | 4 个典型场景的逐步 SOP |
| `~/tools/publishing-toolchain/CHEATSHEET.md` | 单页命令速查 |
| `~/tools/publishing-toolchain/SETUP.md` | 安装与首次配置（已完成）|
| `~/docs/plans/2026-05-08-multi-platform-publishing-design.md` | 调研报告 + 架构设计 |
| `~/.config/opencode/skills/multi-platform-publishing/SKILL.md` | OpenCode skill 自动加载 |
| `~/agency-agents/marketing/marketing-multi-platform-publisher.md` | 编排 agent 源 |
| `~/agency-agents/MY-AGENTS.md` | 你的 agent 团队索引 |
