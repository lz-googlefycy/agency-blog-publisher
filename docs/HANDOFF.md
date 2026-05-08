# 项目交接文档（给另一个 AI 对话用）

> 这是一个「跨会话交接」文档。把这份 .md 喂给另一个 OpenCode/Claude Code 会话，它能立刻接手这个项目的所有能力，知道怎么调用 agent + 怎么用 publish CLI + 怎么发博客。

**项目名**：agency-blog-publisher
**仓库**：https://github.com/lz-googlefycy/agency-blog-publisher
**状态**：v0.1.0 已发布，全链路已联调
**机器**：Ubuntu 20.04 x86_64，DISPLAY=:1 有 GUI，Chrome 144 已装

---

## 🎯 这个项目是什么

把一篇 Markdown 博客一键同步到 19+ 中文内容平台（知乎/CSDN/B 站/小红书/掘金/公众号 等），底层用 [Wechatsync](https://github.com/wechatsync/Wechatsync) 浏览器扩展 + CLI/MCP 桥接，上层用 [agency-agents](https://github.com/msitarzewski/agency-agents) 的 185 个 AI agent 做平台风格化适配。

---

## ✅ 已就绪的能力（你接手就能用）

### 1. CLI 工具

```bash
publish status                              # 查看登录状态 + 端口健康
publish refresh                             # 强制刷新登录态（登了新平台后用）
publish fix                                 # 端口冲突自动修复
publish dry FILE.md PLATFORMS               # 干跑预演（不实际发）
publish sync FILE.md PLATFORMS [COVER.png]  # 同步到草稿
publish extract [OUT.md]                    # 从当前 Chrome 标签页提取文章
publish xhs-server                          # 启 xhs-mcp 后台（小红书）
publish xhs FILE.md "title≤20字" img.jpg    # 发小红书
```

**所有命令都已加到 PATH**（在 `~/.bashrc` 里），新开 terminal 就能用。

### 2. 已登录的平台账号（用户的）

| 平台 ID | 平台 | 状态 | 账号 |
|---|---|---|---|
| `zhihu` | 知乎 | ✅ 已登 | 智驾机器人前瞻局 |
| `csdn` | CSDN | ✅ 已登 | 自动开摆的柚皮 |
| `bilibili` | B站专栏 | ✅ 已登 | bili_91529004340 |
| `weixin` | 微信公众号 | ✅ 已登 | （已登）|
| `juejin` | 掘金 | 🔲 未登 | — |
| `xiaohongshu` | 小红书 | ⚠️ 走 xhs-mcp | 需要 `xiaohongshu-login` 扫码 |

⚠️ **不要尝试用 Wechatsync 发小红书**——v2.0.9 build 里没有 xhs adapter。小红书必须走 `publish xhs` 命令（基于 xpzouying/xiaohongshu-mcp）。

### 3. 可用的 agency-agents（185 个）

写博客最常用的：

| Agent | 调用 | 用途 |
|---|---|---|
| **编排器** | `@marketing-multi-platform-publisher` | 统筹多平台发布的总指挥 |
| **主稿** | `@content-creator` | 多平台内容规划、品牌叙事 |
| **知乎风格** | `@zhihu-strategist` | 选题、回答结构、专栏运营、权威度建设 |
| **B站风格** | `@bilibili-content-strategist` | 视频选题、封面标题、弹幕互动设计 |
| **小红书风格** | `@xiaohongshu-specialist` | 标题≤20字、种草体、emoji 用法 |
| **公众号风格** | `@wechat-official-account-manager` | 公众号内容策略、自动回复、订阅者 |
| **CSDN/SEO** | `@seo-specialist` | 关键词、标签、搜索优化 |

完整索引见 `~/agency-agents/MY-AGENTS.md`。

### 4. OpenCode skill

```yaml
name: multi-platform-publishing
auto-load: true   # OpenCode 会在涉及"发博客"的任务时自动加载
```

skill 路径：`~/.config/opencode/skills/multi-platform-publishing/SKILL.md`

里面有完整的工作流图、错误处理表、风控规则。

### 5. MCP server

OpenCode 配置已加 wechatsync MCP server（在 `~/.config/opencode/opencode.json` 的 `mcp.wechatsync` 节）。重启 OpenCode 后，AI 可以直接调用：

| MCP 工具 | 功能 |
|---|---|
| `list_platforms` | 列所有支持的平台 |
| `check_auth` | 检查指定平台登录状态 |
| `sync_article` | 同步文章到指定平台 |
| `extract_article` | 从浏览器当前页提取 |
| `upload_image_file` | 上传图片到平台 |

⚠️ 需要环境变量 `WECHATSYNC_TOKEN` 已设。值在用户的 `~/.bashrc` 里，但**不要把这个值写进任何文档或代码**——它是私密的。

### 6. 兜底 / 专用工具（已装好）

| 工具 | 路径 | 何时用 |
|---|---|---|
| `xiaohongshu-mcp` | `~/tools/publishing-toolchain/bin/` | Wechatsync 发小红书失败 / 想用定时发布 |
| `xiaohongshu-login` | 同上 | 一次性给小红书扫码登录 |
| `biliup` | `~/.local/bin/biliup` | B 站视频投稿（不是专栏！）|
| `bilibili-api-python` | pip 装的 | B 站动态 / 程序化操作 B 站 |
| `xhs` (Python) | pip 装的 | 小红书数据爬取 / 搜索 |

---

## 🚀 快速使用模板（推荐这个工作流）

### 模板 A：用户给主题，全自动写并发

```
@marketing-multi-platform-publisher

主题：<用户的主题>
目标平台：<比如 zhihu,csdn,bilibili>
受众：<谁>
风格：<什么风格>
是否原创：是/否
封面图：<可选，路径或让 AI 生成>
```

编排 agent 会：
1. 平台匹配检查（拒绝不合适的平台并说明）
2. 让用户确认参数
3. 调 `@content-creator` 出主稿
4. 并行让 `@zhihu-strategist` / `@bilibili-content-strategist` 等做风格化
5. 调 `publish sync` 发草稿
6. 报告每平台的草稿 URL
7. 提醒用户手动到平台后台点发布

### 模板 B：用户已有 Markdown，只想发布

```bash
publish status                                                  # 先看登录状态
publish dry  ~/path/to/article.md zhihu,csdn,bilibili           # 干跑
publish sync ~/path/to/article.md zhihu,csdn,bilibili --cover cover.png
```

### 模板 C：写公众号文（适合本项目自己的推广）

```
@wechat-official-account-manager

主题：<主题>
目标：发到微信公众号草稿
受众：<谁>
长度：<800-1500 字 / 1500-3000 字>

写完后用 publish sync xxx.md weixin 推到草稿。
```

---

## 🚨 关键规则（每次必须遵守）

### 规则 1：永远只发草稿，不自动发布
- Wechatsync 默认就是发草稿，**这是 feature 不是 bug**
- 同步完后告诉用户「草稿已建好，URL 是 XXX，请到平台后台审核后手动点发布」
- 永远不要尝试帮用户点「发布」按钮

### 规则 2：发布前必预检
```bash
publish status   # 必跑！确认目标平台都登录了
```
如果用户要发的某个平台显示「未登录」，停下来让用户先登录。

### 规则 3：长度硬约束
| 平台 | 标题上限 | 正文 |
|---|---|---|
| 知乎 | 80 字 | 建议 ≥ 300 |
| CSDN | 80 字 | 不限 |
| B 站专栏 | 40 字 | ≤ 8000 较好 |
| 小红书 | **20 字** | **1000 字** |
| 公众号 | 64 字 | 不限 |

超过会被平台拒。在调 publish 之前先验证。

### 规则 4：小红书走兜底，不走 Wechatsync
错：`publish sync x.md xiaohongshu` ❌（会失败，因为 v2.0.9 build 没 xhs adapter）
对：`publish xhs x.md "短标题" img.jpg` ✅

### 规则 5：端口冲突时的修复套路
症状：CLI 报 "Invalid or missing token" 或卡在「启动服务...」
修法：
```bash
publish fix      # 自动 kill 残留进程
# 然后让用户：去 Chrome 扩展弹窗点 MCP 开关 关-开 一次（重启 ws server）
```

### 规则 6：账号别搞错
每次 `publish status` 输出会显示账号名（比如「智驾机器人前瞻局」）。在发文前**核对一次账号是不是用户期望的账号**。

---

## 📂 关键文件位置（你需要时去查）

```
项目仓库（已发 GitHub，脱敏版本）:
  ~/projects/agency-blog-publisher/

本地工作副本（含 token 等私密配置，不要 commit）:
  ~/tools/publishing-toolchain/        ← publish.sh 的来源
  ~/.config/opencode/agents/           ← OpenCode agent
  ~/.config/opencode/skills/multi-platform-publishing/  ← OpenCode skill
  ~/.claude/agents/                    ← Claude Code agent

agency-agents 团队（185 个 agent 源码）:
  ~/agency-agents/
  ~/agency-agents/MY-AGENTS.md         ← 用户的索引文件

OpenCode 配置:
  ~/.config/opencode/opencode.json     ← MCP server 配置在这

环境变量:
  ~/.bashrc                            ← WECHATSYNC_TOKEN, PATH 加的工具目录

文档（中文，给用户看的）:
  $REPO/docs/USAGE.md                  ← 日常使用手册
  $REPO/docs/WORKFLOWS.md              ← 4 个典型工作流 SOP
  $REPO/docs/CHEATSHEET.md             ← 命令速查
  $REPO/docs/SETUP.md                  ← 首次安装（用户已装好）
  $REPO/docs/DESIGN.md                 ← 调研报告 + 架构

GitHub:
  https://github.com/lz-googlefycy/agency-blog-publisher
  https://github.com/msitarzewski/agency-agents/pull/516  ← 给上游的 PR
```

---

## 🐛 常见问题（你接手后要会处理）

| 症状 | 诊断 | 修法 |
|---|---|---|
| `Invalid or missing token` | 9527 端口被占 | `publish fix` + 让用户重启 Chrome 扩展 MCP 开关 |
| 卡在「启动服务...」 | Chrome 不在前台 / 扩展失联 | 让用户打开 Chrome、确认扩展显示「已连接」|
| 某平台「未登录」但用户说登过 | cookie 缓存未刷新 | `publish refresh` |
| 同步成功但找不到草稿 | 账号搞错了 | 核对 `publish status` 显示的账号 |
| 标题被拒 | 长度超限 | 知乎/CSDN ≤ 80, B站 ≤ 40, 小红书 ≤ 20, 公众号 ≤ 64 |
| 小红书 sync 失败 | Wechatsync 这版没 build | 切到 `publish xhs ...` |
| 想发 B 站视频 | Wechatsync 不支持视频 | 用 `biliup login && biliup upload ...` |

---

## 🎬 推荐你接手后做的第一件事

如果用户对你说"开始用这个项目发博客"，**第一件事**是确认环境就绪：

```bash
# 用 Bash tool 跑这一段
echo "=== 工具就绪检查 ==="
which publish wechatsync biliup 2>&1
echo ""
echo "=== 平台登录状态 ==="
publish status 2>&1 | head -25
echo ""
echo "=== Chrome 扩展状态 ==="
ss -lntp 2>/dev/null | grep 9527 || echo "9527 未监听 (扩展可能没启用 MCP)"
```

根据输出决定下一步：
- 工具齐 + 平台都登 + 扩展连上 → 直接进入"用户想发什么"环节
- 有平台未登 → 提示用户去 Chrome 登一下 + 跑 `publish refresh`
- 端口未监听 → 提示用户开 Chrome 扩展 MCP 开关

---

## 💡 设计哲学（你写代码/agent 时要遵守）

1. **草稿优先**：永远只发草稿，等用户审核
2. **失败时给诊断，不给道歉**：错误信息里带"为什么"和"怎么修"
3. **状态用表格汇报**：平台 | 状态 | URL | 备注，扫一眼就能看完
4. **平台不是越多越好**：拒绝不匹配的平台，给理由
5. **不要假装调用了工具**：如果工具没装/没启动，停下来说"先装/先启动"
6. **token 是私密**：永远不要写进代码、文档、对话日志、commit message

---

## 📞 给当前 AI 会话的一句话指引

> 你刚接手了 agency-blog-publisher 这个项目。用户名是 lz-googlefycy（GitHub）。
> 已就绪的能力是：CLI 工具 `publish`、agency-agents 185 个 agent、OpenCode skill `multi-platform-publishing`、Wechatsync MCP server。
> 用户已经登了知乎/CSDN/B站/公众号，可以直接发；掘金未登；小红书走 `publish xhs` 兜底。
> 永远只发草稿，永远不要泄露 token。
> 用户的下一个请求大概率是"帮我用这个工具发一篇博客"——按上面的"模板 A"流程走。
