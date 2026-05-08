# agency-blog-publisher

> 把一篇 Markdown 博客同步到 知乎 / 小红书 / CSDN / B 站 / 公众号 / 掘金 等 19+ 中文内容平台 — 集成 [agency-agents](https://github.com/msitarzewski/agency-agents) 的 185 个专业 agent，提供「AI 写作 + 平台风格化 + 一键多发」的端到端工作流。
>
> 主通道是社区项目 [Wechatsync](https://github.com/wechatsync/Wechatsync)，本仓库提供工具链整合、OpenCode skill、agent 编排、文档化工作流，以及小红书/B 站视频的兜底方案。

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Platform Coverage](https://img.shields.io/badge/platforms-19%2B-green.svg)](#supported-platforms)

---

## 这个项目解决了什么问题

写一篇技术文章想发到 知乎 + CSDN + B 站 + 小红书，目前痛点：

| 痛点 | agency-blog-publisher 怎么解决 |
|---|---|
| 4 个平台风格完全不同，复制粘贴很生硬 | 集成 agency-agents 的 zhihu-strategist / bilibili-strategist / xiaohongshu-specialist 自动做平台风格适配 |
| 每个平台都要登一次后台手动发 | Wechatsync 一条命令同步所有平台到草稿 |
| 小红书 cookie 风控、B 站没官方 API | 内置 xhs-mcp 兜底 + biliup 视频投稿 |
| AI 工具调不到这些发布能力 | 提供 OpenCode skill + agent + Wechatsync MCP server 配置，AI 直接驱动 |
| 工具链分散、文档难记 | 一个 `publish` 命令 + 完整 SOP 文档 |

---

## 快速开始

### 前置要求

- Linux / macOS / Windows（带桌面 Chrome）
- Node.js 18+，Python 3.9+，Go 1.21+（编译 xhs-mcp，可选）
- Chrome 浏览器（必装）

### 安装

```bash
git clone https://github.com/lz-googlefycy/agency-blog-publisher.git
cd agency-blog-publisher

# 一键装所有工具：Wechatsync CLI/MCP/扩展 + xiaohongshu-mcp + biliup + Python SDKs
bash scripts/install.sh

# 加 PATH
echo 'export PATH="$HOME/tools/publishing-toolchain/bin:$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### 配置（5 分钟）

详见 [docs/SETUP.md](docs/SETUP.md)。要点：

1. 装 Chrome 扩展「文章同步助手」（[Chrome 商店](https://chrome.google.com/webstore/detail/hchobocdmclopcbnibdnoafilagadion) 或本地 build 加载）
2. 在 Chrome 里登录你要发的所有平台（知乎/CSDN/B站/小红书 等）
3. 点扩展图标 → 启用「CLI / MCP 连接」→ 复制 Token
4. `echo 'export WECHATSYNC_TOKEN="<token>"' >> ~/.bashrc && source ~/.bashrc`

### 第一次发布

```bash
# 看登录状态
publish status

# 写篇文章
mkdir -p ~/blog/test && cd ~/blog/test
echo "# Hello Multi-Platform" > article.md

# 干跑预演
publish dry article.md zhihu

# 真同步（创建草稿，不会自动发布）
publish sync article.md zhihu,csdn,bilibili

# 到各平台后台审核草稿 → 满意点发布
```

### 集成 OpenCode / Claude Code

```bash
# 安装 agent + skill 到 OpenCode
mkdir -p ~/.config/opencode/{agents,skills}
cp agents/marketing-multi-platform-publisher.md ~/.config/opencode/agents/multi-platform-publisher.md
cp -r skills/multi-platform-publishing       ~/.config/opencode/skills/

# 在 ~/.config/opencode/opencode.json 的 mcp 节加入 wechatsync MCP server
# （配置示例见 docs/SETUP.md）
```

然后在 OpenCode 会话里：
```
@marketing-multi-platform-publisher
帮我从主题「YOLO11 边缘部署」写一篇技术博客，发到知乎+CSDN+B站草稿
```

---

## 支持的平台

### 主通道（Wechatsync，浏览器扩展驱动）

知乎 ✅ · 掘金 ✅ · 微博 ✅ · 哔哩哔哩专栏 ✅ · 百家号 ✅ · CSDN ✅ · 语雀 ✅ · 豆瓣 ✅ · 搜狐号 ✅ · 雪球 ✅ · 微信公众号 ✅ · 人人都是产品经理 ✅ · 51CTO ✅ · 慕课手记 ✅ · 开源中国 ✅ · 思否 ✅ · 博客园 ✅ · 东方财富 ✅ · Markdown 压缩包 ✅

### 兜底通道

- **小红书**：内置 `xpzouying/xiaohongshu-mcp`（13.3k★，Wechatsync v2.0.9 暂未含 xhs adapter）
- **B 站视频**：内置 `biliup`（5.1k★ 视频投稿专用）
- **B 站动态/专栏程序化**：内置 `Nemo2011/bilibili-api`（Python SDK）

---

## 架构

```
┌──────────────────────────────────────────────┐
│  你（写博客的人）                              │
└───────────┬──────────────────────────────────┘
            │
            ↓
┌──────────────────────────────────────────────┐
│  OpenCode / Claude Code 会话                  │
│  ├── skill: multi-platform-publishing        │
│  └── agent: @marketing-multi-platform-publisher
│       │                                      │
│       └─ 调度 agency-agents 团队（185 个）    │
│           @content-creator (主稿)            │
│           @zhihu-strategist (知乎风格)       │
│           @bilibili-content-strategist (B站) │
│           @xiaohongshu-specialist (小红书)   │
└───────────┬──────────────────────────────────┘
            │
            ↓
┌──────────────────────────────────────────────┐
│  publish CLI / Wechatsync MCP                │
│  ├── publish sync x.md zhihu,csdn,bilibili  │
│  ├── publish xhs   x.md "title" img.jpg      │
│  └── biliup upload video.mp4                 │
└───────────┬──────────────────────────────────┘
            │
            ↓
┌──────────────────────────────────────────────┐
│  Chrome 扩展（Wechatsync）                    │
│  本地 ws bridge (port 9527) ←→ MCP server   │
│  使用浏览器已登录的 cookie 调各平台 Web API   │
└───────────┬──────────────────────────────────┘
            │
            ↓
[知乎] [小红书] [CSDN] [B站] [掘金] [公众号] [...]
```

完整设计见 [docs/DESIGN.md](docs/DESIGN.md)。

---

## 项目结构

```
agency-blog-publisher/
├── README.md             ← 你正在看
├── LICENSE               ← Apache-2.0
├── SECURITY.md           ← Token 处理 / 风险说明
├── CONTRIBUTING.md       ← 怎么贡献
├── scripts/
│   ├── install.sh        ← 一键装所有工具
│   └── publish.sh        ← 发布瑞士军刀（推荐用这个）
├── skills/
│   └── multi-platform-publishing/
│       └── SKILL.md      ← OpenCode skill
├── agents/
│   └── marketing-multi-platform-publisher.md
│                         ← 编排 agent（兼容 agency-agents）
├── docs/
│   ├── SETUP.md          ← 首次配置详细步骤
│   ├── USAGE.md          ← 使用手册
│   ├── WORKFLOWS.md      ← 4 个典型工作流 SOP
│   ├── CHEATSHEET.md     ← 命令速查（贴墙上版）
│   └── DESIGN.md         ← 调研报告 + 架构设计
└── examples/             ← 示例文章和配置
```

---

## 文档导航

新手按这个顺序看：

| # | 文档 | 用途 |
|---|---|---|
| 1 | [docs/SETUP.md](docs/SETUP.md) | 首次安装与配置（一次性的事） |
| 2 | [docs/USAGE.md](docs/USAGE.md) | 日常使用手册 |
| 3 | [docs/CHEATSHEET.md](docs/CHEATSHEET.md) | 命令速查（贴墙） |
| 4 | [docs/WORKFLOWS.md](docs/WORKFLOWS.md) | 4 个 SOP 拷贝即用 |
| 5 | [docs/DESIGN.md](docs/DESIGN.md) | 想了解原理/为什么这么做的看这个 |

---

## 与 agency-agents 的关系

[agency-agents](https://github.com/msitarzewski/agency-agents) 是开源 AI agent 大全（185 个），覆盖营销、技术、销售、财务等。本仓库：

- ✅ **使用** agency-agents 已有的 marketing-zhihu-strategist 等做平台风格化
- ✅ **新增** marketing-multi-platform-publisher 做发布编排
- ⏳ **计划** 把 multi-platform-publisher 作为 PR 提交到 agency-agents 上游

详见 [CONTRIBUTING.md](CONTRIBUTING.md) 的「Upstream contribution」一节。

---

## 安全与风险

⚠️ **重要：本工具走逆向 Web API + 浏览器自动化**，不是官方 API。请阅读 [SECURITY.md](SECURITY.md)：

- 所有平台的官方 API 都不对个人创作者开放发布能力
- Wechatsync 通过你浏览器中已有的 cookie 调用各平台官方 Web 接口
- 默认同步为草稿，发布前由你确认
- 频率/原创性/合规性自负
- B 站社区警告：2026/01 SocialSisterYi/bilibili-API-collect 收过律师函，使用 SDK 仅限自用，勿公开传播接口、勿商用、勿滥用

---

## 致谢

本项目站在巨人肩膀上：

- [Wechatsync](https://github.com/wechatsync/Wechatsync) by @lljxx1 — 5.4k★ Chrome 扩展 + CLI + MCP，主通道
- [xiaohongshu-mcp](https://github.com/xpzouying/xiaohongshu-mcp) by @xpzouying — 13.3k★ 小红书 MCP，兜底
- [biliup](https://github.com/biliup/biliup) by @ForgQi — 5.1k★ B 站视频投稿
- [bilibili-api](https://github.com/Nemo2011/bilibili-api) by @Nemo2011 — 3.9k★ B 站 Python SDK
- [agency-agents](https://github.com/msitarzewski/agency-agents) by @msitarzewski — 185 个 AI agent

---

## License

Apache-2.0 © [contributors](https://github.com/lz-googlefycy/agency-blog-publisher/graphs/contributors)
