# 命令速查卡（贴墙上版）

```
┌─────────────────────────────────────────────────────────────┐
│  发博客 一条命令搞定                                          │
└─────────────────────────────────────────────────────────────┘

  wechatsync sync FILE.md -p zhihu,csdn,bilibili

  ↑ 把 Markdown 同步到 知乎+CSDN+B站专栏 草稿箱
  ↑ 不会自动发布，需要你到平台手动点


┌─────────────────────────────────────────────────────────────┐
│  日常操作（按使用频率）                                        │
└─────────────────────────────────────────────────────────────┘

  ► 同步                wechatsync sync FILE.md -p PLATFORMS
  ► 检查登录            wechatsync auth
  ► 强制刷新登录        wechatsync auth -r        (登了新平台后用)
  ► 列平台              wechatsync platforms
  ► 提取浏览器文章      wechatsync extract -o saved.md
  ► 干跑预演            wechatsync sync x.md -p zhihu --dry-run


┌─────────────────────────────────────────────────────────────┐
│  目标平台 ID                                                 │
└─────────────────────────────────────────────────────────────┘

  zhihu      知乎
  csdn       CSDN
  bilibili   B 站专栏（不是视频！视频用 biliup）
  juejin     掘金
  weixin     公众号
  segmentfault 思否
  oschina    开源中国
  cnblogs    博客园

  ⚠ xiaohongshu 不在 Wechatsync 里 → 用 xhs-mcp


┌─────────────────────────────────────────────────────────────┐
│  小红书 兜底                                                 │
└─────────────────────────────────────────────────────────────┘

  xiaohongshu-login                 (一次性扫码)
  xiaohongshu-mcp -headless=false & (启 server)

  curl -X POST http://localhost:18060/api/v1/publish \
    -H 'Content-Type: application/json' \
    -d '{"title":"","content":"","images":[],"tags":[]}'

  ⚠ 标题 ≤ 20 字  正文 ≤ 1000 字  图 1-18 张


┌─────────────────────────────────────────────────────────────┐
│  B 站视频投稿                                                │
└─────────────────────────────────────────────────────────────┘

  biliup login                      (一次性扫码)
  biliup upload --title "..." \
                --tag "tag1,tag2" \
                --tid 171 \
                --cover cover.jpg \
                video.mp4


┌─────────────────────────────────────────────────────────────┐
│  应急修复                                                    │
└─────────────────────────────────────────────────────────────┘

  端口冲突              pkill -f "wechatsync\|mcp-server"
  扩展失联              Chrome → 扩展图标 → MCP 关-开
  Cookie 失效           wechatsync auth -r


┌─────────────────────────────────────────────────────────────┐
│  环境变量                                                    │
└─────────────────────────────────────────────────────────────┘

  WECHATSYNC_TOKEN=<YOUR_WECHATSYNC_TOKEN>
  PATH 含 ~/tools/publishing-toolchain/bin

  (已写入 ~/.bashrc，重开 terminal 自动生效)


┌─────────────────────────────────────────────────────────────┐
│  OpenCode AI 调用                                            │
└─────────────────────────────────────────────────────────────┘

  @marketing-multi-platform-publisher 写一篇<主题>发到<平台>
  @content-creator 帮我写<主题>
  @zhihu-strategist 适配知乎风格
  @bilibili-content-strategist 适配 B 站
  @xiaohongshu-specialist 适配小红书

  完整 agent 列表：~/agency-agents/MY-AGENTS.md (185 个)


┌─────────────────────────────────────────────────────────────┐
│  典型 1 分钟流程                                             │
└─────────────────────────────────────────────────────────────┘

  1. cd ~/blog/<主题>/
  2. wechatsync sync article.md -p zhihu,csdn,bilibili
  3. 在 Chrome 里打开各平台「草稿箱」
  4. 审核 → 点发布
```

## 已登录的账号（提醒：发文章前先看下用对账号了）

| 平台 | 账号 |
|---|---|
| 知乎 | <your-zhihu-account> |
| CSDN | <your-csdn-account> |
| B 站 | <your-bilibili-account> |
| 微信公众号 | （之前已登）|

## 重要文件位置

```
~/blog/                                博客文件
~/tools/publishing-toolchain/          工具链根目录
├── bin/                                xiaohongshu-mcp / biliup
├── USAGE.md                            使用手册
├── WORKFLOWS.md                        4 个工作流 SOP
├── CHEATSHEET.md                       本文件
└── SETUP.md                            首次安装指南（已完成）

~/agency-agents/MY-AGENTS.md            你的 185 agent 索引
~/.config/opencode/opencode.json        OpenCode 配置（含 wechatsync MCP）
~/.config/opencode/skills/multi-platform-publishing/SKILL.md
~/docs/plans/2026-05-08-multi-platform-publishing-design.md
```
