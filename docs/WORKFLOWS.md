# 4 个典型工作流 — 拷贝即可用

> 每个 workflow 都给出**完整可粘贴**的命令序列。
> 不需要的话从 OpenCode 会话直接对 agent 说人话也行。

---

## Workflow 1：发第一篇测试草稿（端到端验证）

**目的**：跑通完整链路，确认无 bug。**不会公开发布，只到草稿箱**。

```bash
# 1. 准备测试文章
mkdir -p ~/blog/test-$(date +%m%d) && cd ~/blog/test-$(date +%m%d)
cat > article.md <<'EOF'
# 这是一篇 Wechatsync 测试文章

请忽略本文。这是用 wechatsync CLI 发布的端到端验证。

## 验证目的

- 验证 Wechatsync CLI 能否正确同步到目标平台的草稿箱
- 验证不同平台对 Markdown 渲染的兼容性
- **本文章不会公开发布**，仅到草稿箱供测试

## 一段代码

```python
def hello():
    print("hello, multi-platform")
```

## 一个表格

| 平台 | 状态 |
|---|---|
| 知乎 | 测试中 |
| CSDN | 测试中 |
| B站  | 测试中 |
EOF

# 2. 检查登录状态
wechatsync auth -r

# 3. 干跑预演（不实际同步）
wechatsync sync ./article.md -p zhihu,csdn,bilibili --dry-run

# 4. 真实同步（创建草稿）
wechatsync sync ./article.md -p zhihu,csdn,bilibili

# 5. 在 Chrome 里逐一检查草稿箱
echo "请打开以下 Chrome 标签查看草稿："
echo "  知乎: https://zhuanlan.zhihu.com/  → 点头像 → 创作中心 → 草稿"
echo "  CSDN: https://mp.csdn.net/mp_blog/manage/article?type=Drafts"
echo "  B站:  https://member.bilibili.com/platform/upload-manager/article"

# 6. 满意 → 平台后台手动点「发布」；不满意 → 平台后台删草稿
```

---

## Workflow 2：从主题到多平台发布（AI 全自动版）

**适合**：你只有一个想法，让 agency-agents 全程帮你。

### Step 1：在 OpenCode 里启动编排 agent

```
@marketing-multi-platform-publisher

主题：YOLO11 车牌识别 Jetson Orin 部署
目标平台：知乎、CSDN、B 站专栏
受众：CV 工程师、嵌入式开发者
风格：技术深度 + 工程经验
是否原创：是
```

### Step 2：agent 会自动做这些事

```
1. 平台匹配检查（B 站专栏适合度评估）
2. 调 @content-creator 出 1500-3000 字主稿
3. 并行：
   - @zhihu-strategist → 改写成知乎结构（钩子+论据+CTA）
   - @bilibili-content-strategist → 改写成 B 站专栏（视频化+短段落）
   - CSDN 用主稿（技术深度直接匹配）
4. wechatsync auth -r 检查登录
5. wechatsync sync 各平台草稿
6. 报告：每平台草稿 URL
```

### Step 3：你审核 + 发布

打开报告里的草稿 URL，逐平台审核，满意后点「发布」。

---

## Workflow 3：手动写一篇技术博客并多发

**适合**：你已经在 Markdown 编辑器里写好了，纯粹想分发。

```bash
# 0. 假设你的文章在 ~/blog/yolo-jetson/article.md，封面在 cover.png

# 1. 看一眼文章字数（避免太长被截断）
wc -m ~/blog/yolo-jetson/article.md
# 知乎建议 1500-5000，CSDN 不限，B站专栏 ≤8000 较好

# 2. 检查标题
head -1 ~/blog/yolo-jetson/article.md
# 知乎/CSDN ≤ 80 字，B 站专栏 ≤ 40 字

# 3. 同步
cd ~/blog/yolo-jetson
wechatsync sync article.md \
  -p zhihu,csdn,bilibili \
  --cover cover.png

# 4. 看输出，确认每个平台都返回 ✓ 状态
# 5. 浏览器打开各平台后台审核草稿
```

---

## Workflow 4：发小红书（不走 Wechatsync）

**适合**：硬件评测、生活分享、视觉内容（小红书在 Wechatsync 这版本里没 build 进去）。

```bash
# 一次性：扫码登录小红书
xiaohongshu-login
# 弹出 Chrome 窗口 → 用手机小红书 App 扫码 → 完成

# 启动 MCP server（首次建议有头模式确认登录状态）
xiaohongshu-mcp -headless=false &
# 等几秒看输出 "MCP server listening on :18060"

# 准备图文（注意约束：title ≤20，content ≤1000，images 1-18）
TITLE="今日开发日志｜车牌识别"
CONTENT="今天搞定了 YOLO11 在 Jetson Orin 上的部署……"
IMG1="$BLOG_DIR/yolo-jetson/screenshot1.jpg"
IMG2="$BLOG_DIR/yolo-jetson/screenshot2.jpg"

# HTTP 发布
curl -X POST http://localhost:18060/api/v1/publish \
  -H 'Content-Type: application/json' \
  -d "$(jq -n \
    --arg title "$TITLE" \
    --arg content "$CONTENT" \
    --arg img1 "$IMG1" \
    --arg img2 "$IMG2" \
    '{title: $title, content: $content, images: [$img1, $img2], tags: ["AI", "嵌入式"], is_original: true}')"

# 完成。打开 https://creator.xiaohongshu.com/ 看草稿/已发布。
```

### 或者在 OpenCode 里用 agent

```
@xiaohongshu-specialist 
我有这几张截图 ~/blog/yolo-jetson/*.jpg，
内容是 YOLO11 Jetson 部署的过程。
帮我写一篇小红书种草体的笔记（≤20 字标题，≤1000 字正文），
然后调 xhs-mcp 发到我的小红书草稿。
```

---

## 通用故障应急

### 端口冲突

```bash
# 现象：CLI 报 "Invalid or missing token"
pkill -f "wechatsync\|mcp-server" 2>/dev/null
sleep 2
ss -lntp | grep 9527 && echo "还有占用" || echo "端口干净"
# 然后在扩展弹窗 MCP 开关 关-开
```

### Chrome 扩展失联

```bash
# 现象：CLI 卡在「启动服务...」不动
# 1. 打开 Chrome，确认它在前台
# 2. 看扩展图标，确认显示「已连接」或「等待连接...」
# 3. 如果是「未启用」，点开关开启
# 4. 重跑 wechatsync 命令
```

### 平台 cookie 失效

```bash
# 现象：某平台 sync 报 "未登录" 但你之前登过
# 1. 打开 Chrome，访问该平台主页（如 https://www.zhihu.com）
# 2. 看右上角是否有头像 → 没有就重登
# 3. 重新登录后回来
wechatsync auth -r
```

---

## OpenCode AI 调用模板

复制粘贴改改就能用：

### 模板 A：写 + 发

```
@marketing-multi-platform-publisher
帮我从主题「<你的主题>」出发，写一篇技术博客，
然后发到 <平台,平台,平台> 草稿箱。
受众：<谁>
风格：<什么风格>
是否原创：<是/转载>
```

### 模板 B：只发

```
帮我用 wechatsync 把 ~/blog/<文件路径>.md 同步到 知乎 和 CSDN 草稿。
不要发布，我自己审核后点发布。
```

### 模板 C：只写

```
@content-creator + @zhihu-strategist
主题：<主题>
帮我写一篇 2000 字左右、知乎风格的技术文章，
有钩子开头，有论据支撑，有 CTA 结尾。
```

### 模板 D：转发别人的

```
帮我打开浏览器去 <某 URL>，提取正文，
然后用 wechatsync extract -o ~/blog/<slug>/article.md，
最后同步到我的知乎和 CSDN。
注明转载来源。
```

---

## 我的常用命令簿（按场景索引）

| 我想… | 命令 |
|---|---|
| 看哪些平台登了 | `wechatsync auth` |
| 刚登了新平台，状态没刷新 | `wechatsync auth -r` |
| 发到知乎+CSDN | `wechatsync sync x.md -p zhihu,csdn` |
| 干跑预演 | `wechatsync sync x.md -p zhihu --dry-run` |
| 提取当前网页 | `wechatsync extract -o saved.md` |
| 同步小红书 | `curl -X POST http://localhost:18060/api/v1/publish ...`（见 Workflow 4） |
| 发 B 站视频 | `biliup upload --title "..." video.mp4` |
| 修端口冲突 | `pkill -f "wechatsync\|mcp-server" && sleep 2` |
| 重启扩展 | Chrome 扩展弹窗 → MCP 开关 关-开 |
