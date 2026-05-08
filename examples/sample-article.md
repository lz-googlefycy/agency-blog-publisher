# 示例：用 publish 一键多发的样板文章

> 这是一个 sample，演示推荐的文章结构和 frontmatter 用法。
> 把这文件复制到 `~/blog/<slug>/article.md`，改成你自己的内容，跑 `publish sync ./article.md zhihu,csdn`。

---

## 一段引子（hook）

3-5 行抓住读者。技术博客可以从一个具体问题开始，比如：

> 在 Jetson Orin 上跑 YOLO11 时，FP16 量化比 FP32 快了 **3.7 倍**，但精度只掉了 0.3%。我把整个流程踩坑记一并写出来。

## 主体（论证 / 步骤 / 案例）

### 二级标题 1：Why

为什么这个问题值得解决，行业现状。

### 二级标题 2：How

具体方案。这里展示一段代码：

```python
import torch
from ultralytics import YOLO

model = YOLO("yolo11n.pt")
model.export(format="onnx", half=True, dynamic=False, simplify=True)
```

### 二级标题 3：Outcome

结果数据 / 截图 / 对比表：

| 模型 | 精度 mAP@50 | 推理 (ms) | FPS |
|---|---|---|---|
| FP32 | 0.682 | 28.4 | 35 |
| FP16 | 0.679 | 7.6  | 131 |
| INT8 | 0.661 | 4.2  | 238 |

## 总结 + CTA

### 一两句概括
- 关键洞察 1
- 关键洞察 2

### CTA（按平台略改）
- 知乎版：「关注我，下一篇写 RKNN 部署对比」
- CSDN 版：「完整代码见 GitHub: ...」
- B站专栏版：「文章链接见简介，视频版本制作中」
