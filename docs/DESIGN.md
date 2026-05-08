# 多平台博客一键发布 — 调研报告与落地设计

**创建时间**：2026-05-08
**目标平台**：知乎、小红书、CSDN、B 站（专栏/动态/视频）
**Authors**: contributors of agency-blog-publisher

---

## 一、核心结论（TL;DR）

1. **官方 API 对个人创作者全部封闭**：知乎/小红书/CSDN/B 站都有"开放平台"，但都只对**企业/品牌/MCN** 开放，发布能力不给个人
2. **但 GitHub 上的 CLI / MCP 生态很成熟**，所有 4 个平台都有 2025-2026 年在维护的方案
3. **一站式主通道**：`wechatsync/Wechatsync`（5.4k star，Chrome 扩展 + CLI + MCP，覆盖 4 个目标平台的图文发布）
4. **专项兜底**：小红书用 `xiaohongshu-mcp`、B 站视频用 `biliup`
5. **整体路线是浏览器自动化 + Cookie 复用**，2026/01 B 站律师函事件后要注意**自用即可，勿公开传播接口、勿商用、勿滥用**

---

## 二、四大平台调研速查表

| 平台 | 官方 API | 推荐方案 | 类型 | Star | 登录方式 | 备注 |
|------|---------|---------|------|------|---------|------|
| **知乎** | ❌ | Wechatsync / delankesita/zhihu-publisher | MCP+CLI / pip | 5.4k / 3 | 扩展 cookie / cookie 字符串 | 支持封面/专栏/草稿 |
| **小红书** | ❌ | Wechatsync（弱） / **xpzouying/xiaohongshu-mcp**（强） | MCP+CLI / MCP+HTTP | 5.4k / 13.3k | 浏览器登录态 / 扫码 | 标题 ≤20 字，每日 ≤50 篇，支持定时 1h~14d |
| **CSDN** | ❌ | Wechatsync / koffuxu/md-publisher | MCP+CLI / Playwright | 5.4k / 9 | 扩展 cookie / browser-cookie3 自动抓 | MetaWeblog 2018 已下线 |
| **B 站（专栏）** | ❌ | Wechatsync / Nemo2011/bilibili-api | MCP+CLI / Python SDK | 5.4k / 3.9k | 扩展 cookie / `Credential(sessdata, bili_jct, buvid3)` | |
| **B 站（动态）** | ❌ | Nemo2011/bilibili-api (`dynamic.py` / `opus.py`) | Python SDK | 3.9k | 同上 | Wechatsync 不支持 |
| **B 站（视频）** | ❌ | **biliup/biliup** | Rust CLI | 5.1k | 扫码 → cookies.json | 支持线路选择/定时/追加 |

---

## 三、Wechatsync 深度说明（主通道）

### 架构

```
你的浏览器（已登录各平台）
    ↓  扩展读取 Cookie
    ↓  通过本地桥接暴露给 CLI/MCP
    ↓  调用平台官方 Web API（和你手动发布等价）
各平台（知乎/小红书/CSDN/B站专栏/公众号/掘金/...）
```

### 特性

- **GPL-3.0**，5.4k star，作者 @lljxx1 活跃维护（v2.0.9 @ 2026-03-24）
- 三种形态：
  - Chrome 扩展（必装，底层）
  - `@wechatsync/cli`（npm 全局包）
  - MCP server `sync-assistant`（stdio，接 Claude Code/Desktop/OpenCode）
- **默认同步为草稿**（安全）
- 数据不离开本地，代码开源可审计

### 支持的目标平台

| 平台 | ID | 状态 |
|---|---|---|
| 知乎 | zhihu | ✅ |
| 小红书 | xiaohongshu | ✅ |
| CSDN | csdn | ✅ |
| B 站专栏 | bilibili | ✅ |
| 掘金 | juejin | ✅ |
| 公众号 | weixin | ✅ |
| + 其它 23 个 | | ✅ |

### 不支持

- B 站视频投稿 → 用 `biliup`
- B 站动态（短文/图文动态）→ 用 `Nemo2011/bilibili-api`
- 服务器无 GUI 场景 → Wechatsync 需要 Chrome 扩展运行，必须图形环境

---

## 四、兜底 / 补强方案

### 4.1 小红书兜底：xpzouying/xiaohongshu-mcp

**场景**：Wechatsync 发小红书偶发风控/失败时；或需要定时发布、带货绑定等高级功能

- URL：https://github.com/xpzouying/xiaohongshu-mcp
- 13.3k star，Go 语言，作者生产稳跑 1 年无封号
- 13 个 MCP 工具：登录/图文发布/视频发布/搜索/评论/点赞/收藏
- 支持：定时（1h~14d）、带货商品绑定、可见性控制、原创标记
- 部署：预编译二进制 / Docker / 源码

```bash
./xiaohongshu-login-darwin-arm64   # 一次性扫码登录
./xiaohongshu-mcp-darwin-arm64     # 启动 MCP server (port 18060)

# 接入 Claude Code
claude mcp add --transport http xiaohongshu-mcp http://localhost:18060/mcp

# 纯 HTTP 调用
curl -X POST http://localhost:18060/api/v1/publish \
  -d '{"title":"...","content":"...","images":["/abs/path.jpg"],"tags":["xx"]}'
```

### 4.2 B 站视频投稿：biliup/biliup

**场景**：发 B 站视频（Wechatsync 只支持专栏）

- URL：https://github.com/biliup/biliup（原 `biliup-rs` 已 archive 迁移至此）
- 5.1k star，Rust 写，MIT，v1.1.29 @ 2026-03
- 5 种登录方式（扫码/cookie/浏览器/账密/短信），cookie 持久化
- 支持 bda2/ws/qn/bldsa 等多条上传线路

```bash
biliup login                                    # 扫码登录
biliup upload --title "..." --desc "..." --tag "t1,t2" \
              --tid 171 --cover cover.jpg --copyright 1 \
              --dtime 1728000 --line bda2 video.mp4
```

### 4.3 B 站专栏/动态（程序化）：Nemo2011/bilibili-api

**场景**：需要 Python 一体化调用（不想装两套工具）

- URL：https://github.com/Nemo2011/bilibili-api
- 3.9k star，Python 异步，v17.4.1 @ 2025-12
- 模块：`article.py`（专栏）、`dynamic.py` / `opus.py`（动态）、`video_uploader.py`（视频）、`creative_center.py`

```python
from bilibili_api import article, Credential
credential = Credential(sessdata="...", bili_jct="...", buvid3="...")
# 从浏览器 F12 → Application → Cookies → bilibili.com 拿
```

### 4.4 知乎独立方案（备选）

如果不想装 Chrome 扩展，只发知乎：

- **delankesita/zhihu-publisher**：`pip install zhihu-publisher`，cookie + API 逆向，支持热点抓取
- **happydog-intj/zhihu-autoposter**：Playwright 扫码登录，macOS only

---

## 五、风控与合规注意事项

### 共性规则

1. **频率控制**：每平台每天 ≤5 篇（知乎/CSDN），≤50 篇（小红书个人号）
2. **间隔抖动**：避免整点、同分钟批量发；单次发布加 30~180s 随机抖动
3. **原图策略**：小红书/B 站会做图片 MD5 检测，建议原图或做微调（裁剪/色彩）
4. **账号安全**：cookie 存本地 `chmod 600`，不要上传到公开仓库
5. **单 IP 账号数**：同 IP ≤3 账号

### 小红书特别注意

- 标题 ≤20 字（超过报错）
- 正文 ≤1000 字
- 图片 1-18 张
- 新号先实名，否则弹实名提醒
- **同账号不可多端同时登录**（自动化端登录后不要在其他浏览器登同账号）

### B 站特别注意

- **2026/01 律师函事件**：`SocialSisterYi/bilibili-API-collect` 被 archive
- 使用逆向 SDK 自用风险有限，但**不要公开传播接口细节，不要商用，不要高频滥用**
- cookie 每 7-30 天刷新一次

### 知乎/CSDN

- 知乎有严格内容审核，首发避免纯引流内容
- CSDN 对搬运党打击较严，建议原创标注清楚

---

## 六、落地架构设计

### 层次图

```
┌─────────────────────────────────────────────────────┐
│  User (you, the content creator)                    │
└─────────────────┬───────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────┐
│  OpenCode / Claude Code 会话                         │
│  ├── skill: multi-platform-publishing               │
│  │   （工作流：选题 → 多平台适配 → 发布）             │
│  └── agents:                                         │
│      @content-creator（总策划）                      │
│      @zhihu-strategist                               │
│      @bilibili-content-strategist                    │
│      @xiaohongshu-specialist                         │
│      @marketing-multi-platform-publisher（编排发布） │
└─────────────────┬───────────────────────────────────┘
                  │
      ┌───────────┴────────────┬──────────────┐
      ▼                        ▼              ▼
┌─────────────┐        ┌──────────────┐  ┌──────────┐
│ Wechatsync  │        │ xiaohongshu- │  │ biliup   │
│ CLI + MCP   │        │ mcp（兜底）   │  │ (视频)   │
│ (5 平台图文) │        │              │  │          │
└──────┬──────┘        └──────┬───────┘  └────┬─────┘
       │                      │               │
       ▼                      ▼               ▼
  Chrome 扩展（读 cookie 调平台官方 Web API）
       │                      │               │
       └──────────────────────┴───────────────┘
                   ↓
   [知乎]  [小红书]  [CSDN]  [B站专栏]  [B站视频]
```

### 工作流（端到端）

```
Step 1  用户提供主题 → @content-creator 产出主文稿 (Markdown)
Step 2  @zhihu-strategist 把主文稿改写为知乎风格（结构化+深度）
Step 3  @bilibili-content-strategist 改写为 B 站专栏风格（视频化+趣味）
Step 4  @xiaohongshu-specialist 改写为小红书风格（短+种草+emoji）
Step 5  CSDN 直接用主文稿（技术深度正合适）
Step 6  @marketing-multi-platform-publisher 调用：
          wechatsync sync zhihu.md    -p zhihu
          wechatsync sync bilibili.md -p bilibili
          wechatsync sync csdn.md     -p csdn
          wechatsync sync xhs.md      -p xiaohongshu (可选：或用 xhs-mcp)
Step 7  人工审核草稿 → 各平台编辑器里点"发布"
```

### 配置与 Secrets

```
~/.config/opencode/
├── agents/
│   └── marketing-multi-platform-publisher.md
├── skills/
│   └── multi-platform-publishing/
│       └── SKILL.md
└── mcp.json  # 或 opencode.json 里加 Wechatsync MCP

~/.wechatsync/
└── token         # Wechatsync 的 MCP_TOKEN，chmod 600

~/.biliup/
└── cookies.json  # biliup 登录态

~/.mcp/xiaohongshu/
└── cookies/      # xhs-mcp 登录态
```

---

## 七、安装步骤（给用户的清单）

### 7.1 前置要求

- macOS / Windows / Linux 桌面（需要图形 Chrome）
- Node.js 18+（Wechatsync CLI）
- Python 3.9+（小红书 xhs-mcp / Nemo bilibili-api）
- Rust 或直接下二进制（biliup 可选）

### 7.2 Wechatsync（主通道，必装）

```bash
# 1. 装 Chrome 扩展
# 访问 https://chrome.google.com/webstore/detail/hchobocdmclopcbnibdnoafilagadion
# 安装后在 Chrome 里**登录**：知乎、小红书、CSDN、B 站（保持登录态）

# 2. 在扩展设置里启用「MCP 连接」→ 生成 Token → 复制保存

# 3. 装 CLI
npm install -g @wechatsync/cli

# 4. 设置 token
export WECHATSYNC_TOKEN="你刚才复制的token"
# 建议写入 ~/.zshrc 或 ~/.bashrc

# 5. 验证
wechatsync platforms --auth
# 应该看到知乎/小红书/CSDN/B站等 ✓ 已登录
```

### 7.3 Wechatsync MCP（集成 OpenCode/Claude Code）

Wechatsync 2.0+ 的 MCP server 需要从源码构建：

```bash
git clone https://github.com/wechatsync/Wechatsync.git
cd Wechatsync
pnpm install && pnpm build

# 在 OpenCode 的 MCP 配置里添加：
```

```json
{
  "mcpServers": {
    "wechatsync": {
      "command": "node",
      "args": ["/absolute/path/to/Wechatsync/packages/mcp-server/dist/index.js"],
      "env": {
        "MCP_TOKEN": "your-secret-token-here"
      }
    }
  }
}
```

### 7.4 小红书兜底（可选）

```bash
# macOS Apple Silicon 示例（其它平台选对应二进制）
curl -LO https://github.com/xpzouying/xiaohongshu-mcp/releases/latest/download/xiaohongshu-login-darwin-arm64
curl -LO https://github.com/xpzouying/xiaohongshu-mcp/releases/latest/download/xiaohongshu-mcp-darwin-arm64
chmod +x xiaohongshu-*

./xiaohongshu-login-darwin-arm64          # 一次性扫码
./xiaohongshu-mcp-darwin-arm64 &          # 后台 MCP server
```

### 7.5 B 站视频（可选）

```bash
# macOS
brew install biliup   # 或 cargo install biliup

biliup login          # 扫码
```

---

## 八、已规避的坑

| 决策 | 理由 |
|-----|------|
| 不选官方 API | 知乎/小红书/CSDN/B 站开放平台全部不给个人 |
| 不选 MetaWeblog | CSDN 2018 下线，其它平台从未支持 |
| 不选纯 cookie HTTP API | `mp.csdn.net/mdeditor/saveArticle` 风控加签，ReaJason/xhs 签名逆向不稳 |
| 不选 SocialSisterYi/bilibili-API-collect 引用 | 2026/01 已 archive（律师函），改用 Nemo2011 fork |
| 不选 Selenium（优先 Playwright/CDP） | 反爬检测友好度 Playwright > Selenium |
| 不选商业 SaaS（蚁小二/简媒等） | 闭源+账号托管风险+月费 |
| 不选现有 CSDN MCP（都是空仓库） | 实际可用的只有 Wechatsync/md-publisher |

---

## 九、验证计划

### 阶段 1：Wechatsync 单平台验证

每个平台发一篇**测试文章**（草稿），确认扩展能正常工作：
- [ ] 知乎：标题+正文+封面 → 草稿
- [ ] CSDN：标题+正文+分类+标签 → 草稿
- [ ] B 站专栏：标题+正文+封面 → 草稿
- [ ] 小红书：标题（≤20 字）+ 正文 + 图片 → 草稿

### 阶段 2：CLI 自动化

- [ ] `wechatsync sync test.md -p zhihu` 成功
- [ ] `wechatsync sync test.md -p zhihu,csdn,bilibili` 批量成功
- [ ] `wechatsync platforms --auth` 显示所有目标平台已登录

### 阶段 3：MCP 集成

- [ ] 在 opencode/claude-code 会话里：
  - "检查 Wechatsync 各平台登录状态" → 正确返回
  - "把这个文件同步到知乎和 CSDN" → 正确创建草稿

### 阶段 4：Agent 编排

- [ ] `@content-creator` → `@zhihu-strategist` 改写 → `@marketing-multi-platform-publisher` 发布流水线跑通

---

## 十、后续优化方向

1. **定时发布**：目前 Wechatsync 默认立即同步为草稿，定时功能要靠 xhs-mcp（小红书）或 biliup（B 站视频）原生支持
2. **发布状态追踪**：写一个本地 SQLite 记录每篇文章在各平台的发布状态 + URL
3. **封面自动生成**：集成火山引擎豆包 API 或 ComfyUI 做平台化封面（知乎 3:4、B 站 16:9、小红书 3:4）
4. **敏感词预检**：接入中文敏感词库在发布前做一轮扫描
5. **数据回流**：每日抓取各平台阅读/点赞数，反馈到 `@analytics-reporter` 做内容优化

---

## 附录：调研原始数据来源

- Wechatsync README：https://github.com/wechatsync/Wechatsync
- xiaohongshu-mcp：https://github.com/xpzouying/xiaohongshu-mcp（13.3k star）
- biliup：https://github.com/biliup/biliup（5.1k star）
- Nemo2011 bilibili-api：https://github.com/Nemo2011/bilibili-api（3.9k star）
- zhihu-publisher：https://github.com/delankesita/zhihu-publisher
- md-publisher：https://github.com/koffuxu/md-publisher
- blog-auto-publishing-tools：https://github.com/ddean2009/blog-auto-publishing-tools（275 star，2024-05 后停滞）
