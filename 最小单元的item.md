

最小单元的item

你的理解**只对了一半**，需要稍微纠正一下。

## `CapsuleCollapsedContentView` 是什么

它是**胶囊按钮收起态里的内容区**，不是完整的「小长方形格子」。

```text
一个格子（最小可点击单元）=
  MorphingCapsuleButton / MultipleCapsuleButton   ← 这才是最小单元
    ├─ CapsuleChromeBackground                    ← 毛玻璃 / 黄底背景
    ├─ CapsuleCollapsedContentView                ← 收起时显示的内容（icon、标题、badge…）
    └─ 展开态 option 区域                          ← 展开后才出现
```

`CapsuleCollapsedContentView` 只负责：**胶囊还没展开时，里面画什么**（比例 badge、倒计时、toggle icon 等）。它不管背景、不管展开、也不管格子宽度。

---

## 和小长方形 view 的关系

| 概念 | 实际对应 |
|------|---------|
| 小长方形 view | `SmallSettingRowView` 里的**一个格子**，即 `MorphingCapsuleButton` / `MultipleCapsuleButton` |
| `CapsuleCollapsedContentView` | 上面这个胶囊**收起时**的内部内容 |

小格和大格**共用**同一套 `CapsuleCollapsedContentView`，区别只是外层格子宽度不同（1/3 vs 1/2 屏宽），由 `columnCount` 决定。

---

## 正确理解

- **最小单元 item** = 胶囊组件（`MorphingCapsuleButton` / `MultipleCapsuleButton`）
- **`CapsuleCollapsedContentView`** = 胶囊内部的「收起态 UI 路由器」，是子组件，不是完整格子

如果你说「小长方形 = 一行 3 个里的那一个按钮」，那对应的是**整个胶囊**，不是单独的 `CapsuleCollapsedContentView`。