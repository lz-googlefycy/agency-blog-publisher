# 我开源了一个一键多平台发博客的项目，把 AI 当编辑用

> 写一次，自动适配风格发到知乎、CSDN、B 站、小红书、公众号

最近一直被一个问题困扰：写一篇技术文章，想发到知乎建立专业形象，发到 CSDN 攒搜索流量，再发到 B 站专栏做长尾，最后还想剪个小红书种草版本。

**结果就是同一篇内容复制粘贴四次。每次都得手动调标题、改格式、换排版。**

写一篇博客两小时，分发到四个平台又两小时。

这周末我把这件事彻底解决了——做了个开源项目 [`agency-blog-publisher`](https://github.com/lz-googlefycy/agency-blog-publisher)，**一条命令把一篇 Markdown 推到 19+ 中文内容平台的草稿箱**。

更进一步：因为集成了开源 AI agent 库 [agency-agents](https://github.com/msitarzewski/agency-agents) 的 185 个专业 agent，**还能让 AI 自动按平台风格改写**——知乎版加结构钩子，B 站专栏加视频化短句，小红书加 emoji 种草体，CSDN 保留技术深度。

写一次，AI 适配，一键多发。

## 先看效果

```bash
# 准备一篇 Markdown
cd ~/blog/yolo-jetson
ls
# article.md  cover.png

# 一条命令同步到 4 个平台的草稿箱
publish sync ./article.md zhihu,csdn,bilibili,weixin --cover cover.png
```

输出：

```
✔ Chrome Extension 已连接
- 同步中...

✓ 知乎    草稿已保存 → https://zhuanlan.zhihu.com/...
✓ CSDN    草稿已保存 → https://mp.csdn.net/...
✓ 哔哩哔哩 草稿已保存 → https://member.bilibili.com/...
✓ 公众号  草稿已保存 → https://mp.weixin.qq.com/...

🎉 同步完成：4/4 平台成功
```

打开 Chrome 看每个平台的草稿箱，**已经按各平台风格排好版了**，扫一眼没问题就点发布。

我做了一个简单计时：从 `publish sync` 敲下回车到全部草稿建好，**平均 1 分 47 秒**。比我开 4 个浏览器标签页手工复制粘贴节省 90% 时间。

## 这个项目解决的真正痛点

如果你只关心"工具好不好用"，跳到下一节。这一节解释为什么市面上其他工具我都没选。

**痛点 1：官方 API 对个人封闭**

知乎、小红书、CSDN、B 站全部有「开放平台」，但全部只对**企业 / 品牌 / MCN** 开放，个人创作者根本拿不到 API。

我去申请过一次。流程是这样的：

> 上传公司营业执照 → 等 5-7 个工作日 → 拒绝（"个人开发者暂不开放"）

死路一条。

**痛点 2：MetaWeblog 老协议早就废了**

CSDN 在 2018 年下线了 MetaWeblog 接口，知乎从来没支持过。Typora / MWeb 直接发 CSDN 的时代过去了。

**痛点 3：第三方逆向 SDK 维护噩梦**

GitHub 上有不少 `xhs-sdk`、`zhihu-api` 之类，但这些走签名逆向的路线，**每次平台更新签名算法（小红书每月一次）就废一次**。维护成本远高于使用价值。

**痛点 4：现有"多平台发布工具"都不够**

试过几个：
- `ArtiPub`（3.2k★ 老牌）：2026 重构后**反而不支持公众号/小红书/B 站**
- `blog-auto-publishing-tools`（275★）：纯 Selenium，2024 年后停滞，**不支持小红书/B 站**
- 商业 SaaS（蚁小二、简媒）：闭源 + 月费 ¥30-200 + 账号要托管给第三方

直到我找到 [Wechatsync](https://github.com/wechatsync/Wechatsync)（5.4k★，活跃维护中）。

## Wechatsync 是什么

它是一个 **Chrome 扩展**，原理特别巧妙：

```
你的浏览器（已经登录了知乎/CSDN/B 站等）
    ↓
扩展直接读取浏览器里的 cookie
    ↓
调用各平台「网页编辑器」用的同一套官方 Web API
    ↓
和你手动在网页发布完全等价
```

不是爬虫，不是模拟登录，**就是用你已经有的浏览器登录态去调官方 Web 接口**。所以它非常稳定——只要浏览器能正常发文章，扩展就能。

更妙的是 Wechatsync 提供了三种用法：
1. 浏览器扩展（点点鼠标）
2. CLI 工具 `@wechatsync/cli`（命令行）
3. **MCP server**（让 Claude / OpenCode 之类的 AI 编辑器直接调用）

第三种是关键——**意味着我们可以让 AI agent 替我们发文章**。

## 我的项目在 Wechatsync 上加了什么

如果只用 Wechatsync，你已经能解决"一键多发"的问题。但要把它升级为"AI 编辑助理"，还差几块拼图。这就是 `agency-blog-publisher` 做的事：

### 第 1 块：填补平台缺口

Wechatsync 当前 v2.0.9 build 没有把小红书 adapter 编译进去。我打包了 `xpzouying/xiaohongshu-mcp`（13.3k★ 的小红书 MCP）作为兜底；B 站视频也不在 Wechatsync 范围里，加了 `biliup`（5.1k★ 的 Rust CLI）。现在覆盖范围是：

- **图文一键多发**：知乎 / 小红书 / CSDN / B 站专栏 / 掘金 / 公众号 / 思否 / 博客园 / 51CTO / 开源中国 / 微博 / 雪球 / 豆瓣 / 语雀 / 百家号 / 等 19+ 平台
- **B 站视频投稿**：用 biliup
- **B 站动态/程序化操作**：用 bilibili-api-python

### 第 2 块：AI agent 团队

集成了开源项目 [agency-agents](https://github.com/msitarzewski/agency-agents) 的 185 个 AI agent。这些 agent 用 markdown 定义角色提示词，可以装到 OpenCode / Claude Code 等 AI 编辑器里，对话时 `@` 一下就能调用。

写博客最常用的几个：

| Agent | 用途 |
|---|---|
| `@content-creator` | 主稿产出（多平台内容规划） |
| `@zhihu-strategist` | 知乎风格化（结构钩子 + 论据 + CTA） |
| `@bilibili-content-strategist` | B 站专栏风格（视频化 + 短段落） |
| `@xiaohongshu-specialist` | 小红书种草体（标题≤20 字 + emoji） |
| `@wechat-official-account-manager` | 公众号风格（这篇文章就是它写的） |
| `@seo-specialist` | CSDN 关键词标签优化 |

### 第 3 块：编排器 agent

我自己写了个 `@marketing-multi-platform-publisher` agent，作为「总指挥」。它的职责：

1. 看用户给的主题，判断**哪些平台合适**（消费品种草不发 CSDN，深度技术教程不发小红书）
2. 调主稿 agent 出 1500-3000 字基础稿
3. 并行让各平台 agent 做风格化改写
4. 调 `publish sync` 发草稿
5. 把每个平台的草稿 URL 报给用户
6. **永远停在草稿，不会自动发布**

这个 agent 已经提交 PR 到 agency-agents 上游 ([PR #516](https://github.com/msitarzewski/agency-agents/pull/516))。

### 第 4 块：一条命令的瑞士军刀

把所有底层工具包装成一个 `publish` 命令：

```bash
publish status              # 看登录 + 端口健康
publish sync x.md PLATFORMS # 多平台同步
publish dry  x.md PLATFORMS # 干跑预演
publish refresh             # 刷新登录态
publish fix                 # 端口冲突自动修
publish extract             # 从浏览器当前页提取
publish xhs-server          # 启 xhs-mcp 后台
publish xhs   x.md "标题" img.jpg  # 发小红书
```

### 第 5 块：完整的工作流文档

写代码两小时，写文档两天。仓库里有：

- `SETUP.md` — 首次配置（一次性）
- `USAGE.md` — 日常使用手册
- `WORKFLOWS.md` — 4 个典型工作流 SOP（拷贝即用）
- `CHEATSHEET.md` — 命令速查
- `DESIGN.md` — 调研报告 + 架构设计（解释"为什么这么做"）
- `SECURITY.md` — 风险披露 + 合规说明
- `HANDOFF.md` — 跨 AI 会话交接说明

## 完整的「我用」流程

我现在写一篇技术博客的工作流是这样：

**第 1 步：在 OpenCode 里启动**

```
@marketing-multi-platform-publisher

主题：YOLO11 在 Jetson Orin 部署的 5 个坑
目标平台：知乎,CSDN,B站
受众：CV 工程师 / 嵌入式开发者
风格：技术深度 + 工程经验
是否原创：是
```

**第 2 步：AI 干完所有重活**

- `@content-creator` 出 2000 字主稿
- `@zhihu-strategist` 改写成知乎版（加引子钩子、改段落结构、补 CTA）
- `@bilibili-content-strategist` 改写成 B 站专栏版（视频化短段落、加表情）
- CSDN 用主稿（技术深度本就匹配）
- 调 `publish sync` 发到 3 个平台的草稿箱

**第 3 步：我审核**

打开 3 个浏览器标签页，扫一眼草稿，哪里不对调一下，没问题点「发布」。

**全程**：从我说"我想写"到 3 个平台都发出去——以前 4 小时，现在 30 分钟。其中我亲自做的事只有"提供主题"和"审核草稿"。

## 这套东西怎么用

仓库地址：https://github.com/lz-googlefycy/agency-blog-publisher

### 一次性安装（5 分钟）

```bash
git clone https://github.com/lz-googlefycy/agency-blog-publisher.git
cd agency-blog-publisher
bash scripts/install.sh
```

脚本会装：Wechatsync CLI/MCP/扩展、xiaohongshu-mcp、biliup、bilibili-api-python、xhs Python SDK。

### 配置（再 5 分钟）

按 `docs/SETUP.md` 走：

1. 装 Chrome 扩展「文章同步助手」
2. 在 Chrome 里登录你要发的平台
3. 扩展弹窗启用 MCP，复制 token
4. `echo 'export WECHATSYNC_TOKEN="<token>"' >> ~/.bashrc`

### 试一下

```bash
publish status   # 看哪些平台登了
echo "# Hello" > test.md
publish dry test.md zhihu          # 干跑
publish sync test.md zhihu         # 真同步成草稿
```

## 几个对工程师的提示

**1. 默认草稿，不会自动发布**：哪怕你 `publish sync` 跑了 100 次，到平台后台它还是草稿。这是 Wechatsync 的设计选择，也是这个项目继承的。永远是你点最后那个「发布」。

**2. 你的账号信息不上传任何服务器**：所有操作在你本地浏览器里完成。Token、Cookie、文章内容都不出你的电脑。代码完全开源可审计。

**3. 它不是对抗平台的工具**：它**用**平台官方 Web 接口，**用**你已登录的 cookie。和你手动在网页发布完全等价，不绕过任何风控。频率控制还是要遵守。

**4. 有局限**：
   - 必须有 Chrome（扩展跑在浏览器里）
   - 必须有桌面环境（要弹扫码登录窗口）
   - 不支持视频号 / 抖音视频（视频还是要专用工具）
   - 小红书每天 ≤50 篇、其它平台 ≤5-10 篇

**5. 给别人用要看 SECURITY.md**：B 站社区 2026 年初有过律师函事件（针对 API 文档汇总仓库）。**自用没事，但不要公开传播 SDK 接口细节，也不要拿来做商业批量发布服务**。

## 最后

这个项目站在很多巨人肩膀上：

- **Wechatsync** by [@lljxx1](https://github.com/lljxx1) — 最核心的引擎
- **xiaohongshu-mcp** by [@xpzouying](https://github.com/xpzouying) — 小红书兜底
- **biliup** by [@ForgQi](https://github.com/biliup) — B 站视频
- **bilibili-api** by [@Nemo2011](https://github.com/Nemo2011) — B 站 Python SDK
- **agency-agents** by [@msitarzewski](https://github.com/msitarzewski) — AI agent 团队

我做的事是「把这些工具粘起来 + 加 AI 编排层 + 写完整文档」。

如果你也写技术博客 / 自媒体 / 公众号——欢迎试试。

**仓库**：https://github.com/lz-googlefycy/agency-blog-publisher

觉得好用的话，**点个 Star 是最好的鼓励**。有问题或建议直接在 GitHub 上开 Issue。

---

P.S. 这篇推送本身就是用项目里的 `@wechat-official-account-manager` agent 写的，然后通过 `publish sync` 发到公众号草稿箱的。

Dogfooding 一气呵成。

---

**项目链接**（长按复制）：
https://github.com/lz-googlefycy/agency-blog-publisher
