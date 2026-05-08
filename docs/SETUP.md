# 多平台博客发布工具链 — 设置指南

**更新时间**：2026-05-08
**目标**：完成 Chrome 扩展安装 + 各平台登录 + Wechatsync MCP 激活

---

## ✅ 已自动装好的（无需操作）

| 工具 | 路径 | 验证命令 |
|---|---|---|
| `wechatsync` CLI | `~/.nvm/.../bin/wechatsync` | `wechatsync --version` → 1.0.0 |
| Wechatsync MCP server | `~/tools/Wechatsync/packages/mcp-server/dist/index.js` | 见下文 |
| Wechatsync Chrome 扩展 | `~/tools/Wechatsync/packages/extension/dist/` | 见下文 |
| `xiaohongshu-mcp` | `~/tools/publishing-toolchain/bin/xiaohongshu-mcp` | `~/tools/publishing-toolchain/bin/xiaohongshu-mcp -h` |
| `xiaohongshu-login` | `~/tools/publishing-toolchain/bin/xiaohongshu-login` | — |
| `biliup` (Python 1.1.29) | `~/.local/bin/biliup` | `biliup --help` |
| `bilibili-api-python` | pip user | `python -c 'import bilibili_api'` |
| `xhs` (Python) | pip user | `python -c 'import xhs'` |

---

## 🎯 你需要做的手动步骤

### 步骤 1：把工具目录加入 PATH

```bash
echo 'export PATH="$HOME/tools/publishing-toolchain/bin:$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# 验证
which biliup xiaohongshu-mcp xiaohongshu-login
```

### 步骤 2：安装 Wechatsync Chrome 扩展（本地已 build，推荐开发者模式加载）

打开 Chrome：

1. 地址栏输入 `chrome://extensions/`
2. 右上角打开「开发者模式」开关
3. 点击「加载已解压的扩展程序」
4. 选择目录：`$WECHATSYNC_HOME/packages/extension/dist`
5. 扩展栏应出现「文章同步助手」图标

> 或者：Chrome Web Store 装稳定版 → <https://chrome.google.com/webstore/detail/hchobocdmclopcbnibdnoafilagadion>
> 两种方式任选其一。本地 build 版是 v2.0.9，和商店最新版一致。

### 步骤 3：在扩展里登录所有目标平台

在 Chrome 里依次打开下面这些网页并登录（Wechatsync 会复用已登录的 Cookie）：

| 平台 | 创作中心地址 |
|---|---|
| 知乎 | <https://zhuanlan.zhihu.com/write> |
| 小红书 | <https://creator.xiaohongshu.com/> |
| CSDN | <https://mp.csdn.net/> |
| B 站（专栏） | <https://member.bilibili.com/platform/upload/text/apply> |
| 掘金 | <https://juejin.cn/editor/drafts/> |
| 公众号 | <https://mp.weixin.qq.com/> （可选） |

### 步骤 4：在扩展里开启 MCP 连接 + 生成 Token

1. 点击 Chrome 扩展栏的「文章同步助手」图标
2. 进入「设置」/「Settings」
3. 找到「MCP 连接」或「AI 集成」选项，开启
4. 点击「生成 Token」，**复制保存**

### 步骤 5：把 Token 配到环境变量

```bash
echo 'export WECHATSYNC_TOKEN="<刚才复制的 token>"' >> ~/.bashrc
source ~/.bashrc
```

### 步骤 6：在 opencode 的 MCP 配置里填 Token 并启用

编辑 `~/.config/opencode/opencode.json`，找到 `wechatsync` 块：

```json
"wechatsync": {
  "enabled": false,                    // ← 改成 true
  "type": "local",
  "command": [
    "node",
    "$WECHATSYNC_HOME/packages/mcp-server/dist/index.js"
  ],
  "environment": {
    "MCP_TOKEN": "CHANGE_ME_..."       // ← 换成你的 token
  }
}
```

或者用 sed 一键替换：

```bash
# 把 YOUR_TOKEN_HERE 换成你的 token
TOKEN="YOUR_TOKEN_HERE"
sed -i.bak -e "s|CHANGE_ME_AFTER_GENERATING_TOKEN_IN_CHROME_EXTENSION|$TOKEN|" \
           -e '/^    "wechatsync": {/,/^    }/s/"enabled": false/"enabled": true/' \
           ~/.config/opencode/opencode.json
```

### 步骤 7：验证

```bash
# 1. CLI 能看到所有平台登录状态
wechatsync auth
# 期望：zhihu ✓, xiaohongshu ✓, csdn ✓, bilibili ✓, juejin ✓, weixin ✓

# 2. 用 --dry-run 试一下
echo '# Test\n\nHello 测试' > /tmp/test.md
wechatsync sync /tmp/test.md -p zhihu,csdn --dry-run

# 3. 重启 opencode，应该能看到 @wechatsync MCP 工具（list_platforms / sync_article 等）
```

---

## 🧰 可选：小红书兜底 / B 站视频使用

### 小红书 xhs-mcp（兜底，Wechatsync 小红书失败时用）

```bash
# 一次性扫码登录（用你手机上的小红书 App 扫）
xiaohongshu-login

# 启动 MCP server（后台）
xiaohongshu-mcp -headless=false &   # 首次建议有头模式看登录状态
# 正常使用后可以 -headless=true

# HTTP 调用验证
curl http://localhost:18060/api/v1/feeds/list
```

### B 站视频 biliup

```bash
# 扫码登录（生成 ~/cookies.json）
biliup login

# 上传视频
biliup upload \
  --title "标题" \
  --desc "简介" \
  --tag "Python,AI" \
  --tid 171 \
  --cover cover.jpg \
  --copyright 1 \
  --line bda2 \
  video.mp4
```

### B 站专栏（Python）

```python
from bilibili_api import article, Credential
# 从你已登录的 Chrome 里复制：
# F12 → Application → Cookies → bilibili.com → SESSDATA / bili_jct / buvid3
credential = Credential(
    sessdata="你的SESSDATA",
    bili_jct="你的bili_jct",
    buvid3="你的buvid3",
)
# 调用 article 模块的 API（见 https://nemo2011.github.io/bilibili-api/）
```

---

## 🚨 常见问题

### Q: `wechatsync auth` 显示所有平台都 ✗
A: Chrome 扩展没装好 / 或者 Chrome 没开。先打开 Chrome，加载扩展，然后再试。

### Q: `WECHATSYNC_TOKEN` 环境变量设了但 CLI 还是报错
A: CLI 实际不走环境变量，它通过**本地扩展桥接**自动获取（只要 Chrome 开着、扩展装了、MCP 连接开着就行）。环境变量 `MCP_TOKEN` 只给 MCP server 用。

### Q: opencode 里看不到 `@wechatsync` 工具
A: 检查 3 点：
1. `opencode.json` 里 `wechatsync.enabled` 是否为 `true`
2. `MCP_TOKEN` 是否和 Chrome 扩展里的 token 一致
3. 重启 opencode（`/exit` + 重开）

### Q: 小红书用 Wechatsync 同步失败
A: 小红书风控最严。试 3 次都失败 → 切到 xhs-mcp 兜底（见上）。

### Q: B 站视频用 biliup 提示 `-352` / `-101`
A: Cookie 过期。重跑 `biliup login` 扫码。

### Q: 扩展 build 报错 / 无法加载
A: 用 Chrome Web Store 装稳定版，和本地 build 效果一样。

---

## 📚 参考

- 工作流设计：`~/docs/plans/2026-05-08-multi-platform-publishing-design.md`
- OpenCode skill：`~/.config/opencode/skills/multi-platform-publishing/SKILL.md`
- Agent：`@marketing-multi-platform-publisher`
- 一键安装脚本：`~/tools/publishing-toolchain/install-publishing-toolchain.sh`

## 🎬 全流程示例（设置完成后）

在 opencode 里：

```
User: @marketing-multi-platform-publisher
       帮我把 ~/blog/yolo-jetson.md 发到知乎、CSDN、B 站专栏

Agent: (平台匹配检查 → 参数确认 → 调用 @zhihu-strategist / @bilibili-content-strategist 改写 →
       wechatsync sync ... → 报告每个平台的草稿 URL)

User: 打开 Chrome 看草稿 → 微调 → 点发布
```
