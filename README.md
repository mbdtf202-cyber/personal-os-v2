# Personal OS v2

> 一个全能的个人生活与工作管理系统，集成仪表盘、健康管理、知识库、投资交易、内容创作等多个核心功能模块。

![iOS](https://img.shields.io/badge/iOS-15.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-Latest-green)

---

## 🧩 功能模块详解

### 1. 仪表盘 (Dashboard)

**全览视图**
- 一屏掌握今日待办、健康打卡状态、最新资讯和社交发布计划

**数据可视化**
- 活动热力图：展示过去一段时间的活动频率
- 趋势分析图表：多维度数据趋势展示
- 进度环形图：直观展示各项目标的完成进度

**全局搜索**
- 快捷键：⌘/Ctrl + K 唤起全局命令中心
- 快速检索笔记、收藏、项目等资源
- 支持模糊搜索和高级过滤

---

### 2. 健康管理 (Health Center)

**每日日志**
- 睡眠质量：记录入睡时间、睡眠时长、睡眠质量评分
- 运动时长：记录运动类型、时长和强度
- 心情评分：每日心情打分（1-10）
- 能量水平：记录当日精力状态
- 压力指数：追踪压力水平变化

**习惯养成**
- 定义并追踪每日/每周/每月习惯
- 可视化打卡进度，支持连续打卡统计
- 习惯完成率分析和趋势预测

**趋势分析**
- 通过图表发现生活习惯与身心状态的关联
- 帮助用户优化生活方式

---

### 3. 技能与知识库 (Training System)

专为开发者和创作者设计的学习闭环系统。

**领域管理**
- 产品设计、前端开发、后端开发、DevOps、AI & 机器学习等多个技术领域

**知识笔记**
- 支持 Markdown 的深度技术笔记
- 支持代码高亮和语法着色
- 支持标签和分类管理

**代码片段 (Snippets)**
- 收藏和复用常用的代码块
- 支持多种编程语言
- 快速搜索和复制功能

**Bug 追踪**
- 记录遇到的 Bug 及其解决方案
- 形成个人经验库
- 支持标签分类和搜索

**资源库**
- 整理教程、文档、视频等学习资源
- 支持链接管理和分类
- 支持稍后阅读功能

---

### 4. 交易与投资 (Trading Journal)

**交易复盘**
- 入场理由：为什么进入这笔交易
- 出场理由：为什么退出这笔交易
- 情绪状态：交易时的心理状态
- 策略标签：使用的交易策略分类

**每日总结**
- 记录当日盈亏
- 市场感悟和经验总结
- 明日计划和策略调整

**资产分析**
- 支持多市场记录：A 股、美股、Crypto 等
- 自动生成盈亏曲线
- 投资组合分析和风险评估
- 收益率计算和对标分析

---

### 5. 内容创作与社媒 (Social & Blog)

**博客系统**
- 全功能 Markdown 编辑器
- 支持草稿、发布和归档管理
- 支持文章分类和标签
- SEO 优化支持

**社媒运营**
- 专为小红书/X/公众号等平台设计的内容日历
- 多平台内容管理
- 发布时间规划
- 内容预览和优化建议

**状态流转**
- Idea → 草稿 → 排期 → 已发布

**数据追踪**
- 记录各平台的阅读、点赞、收藏数据
- 分析爆款趋势
- 内容性能对比分析

---

### 6. 资讯聚合 (News Aggregator)

**多源订阅**
- 支持 RSS 订阅
- 支持 API 抓取
- 覆盖领域：AI、金融、Web3 等

**智能阅读**
- 自动提取摘要
- 支持稍后阅读功能
- 支持收藏和归档

**链接预览**
- 自动抓取分享链接的元数据
- 显示标题、封面、描述
- 支持快速分享到其他模块

---

### 7. 项目管理 (Project Hub)

**作品集展示**
- 管理个人项目
- 支持从 GitHub 链接自动抓取仓库信息
- 显示 Star 数、编程语言、最后更新时间等

**状态追踪**
- Idea → In Progress → Paused → Finished → Archived

---

### 8. 效率工具工作流 (Workflows)

**自动化工作流**
- 创建自定义自动化任务
- 定时任务支持（如定时抓取新闻）
- 缓存清理和数据同步

**书签管理**
- 替代浏览器收藏夹
- 结构化管理网络资源
- 支持分类、标签和搜索
- 支持导入/导出

**闪念笔记 (Quick Notes)**
- 随时记录瞬时灵感
- 支持置顶重要笔记
- 快速转换为其他内容类型
- 支持语音输入

---

## 🎨 架构特点

**设计系统**
- 毛玻璃效果 (Glassmorphism) UI
- 统一的色彩系统和排版规范
- 响应式布局支持

**数据持久化**
- UserDefaults 本地存储
- JSON 编解码
- 自动备份机制

**网络功能**
- URLSession 网络请求
- RESTful API 集成
- 异步并发处理

**性能优化**
- 增量更新
- 智能缓存策略
- 后台任务处理

---

## 🚀 快速开始

### 系统要求
- iOS 15.0+
- iPhone 12 或更新机型
- Xcode 14.0+

### 安装

```bash
# 克隆仓库
git clone https://github.com/mbdtf202-cyber/personal-os-v2.git

# 进入项目目录
cd personal-os-v2

# 使用 Xcode 打开项目
open personalos-ios-v2.xcodeproj
```

### 运行

1. 选择目标设备或模拟器
2. 按 Cmd+R 运行应用

### 首次使用

1. 完成应用初始化
2. 授予必要的权限（健康数据、日历等）
3. 配置个人信息和偏好设置
4. 开始使用各功能模块

---

## 📁 项目结构

```
personalos-ios-v2/
├── App/                              # 应用配置和委托
│   ├── AppConfig.swift              # 应用全局配置
│   └── AppDelegate.swift            # 应用生命周期
├── Core/                            # 核心模块
│   ├── DesignSystem/                # 设计系统
│   │   ├── Colors/                  # 颜色定义
│   │   ├── Components/              # 可复用 UI 组件
│   │   ├── Modifiers/               # SwiftUI 修饰符
│   │   └── Typography/              # 排版规范
│   ├── Navigation/                  # 导航和路由
│   │   ├── AppContainer.swift       # 应用容器
│   │   └── AppRouter.swift          # 路由管理
│   └── Utilities/                   # 工具函数
│       ├── DateExtensions.swift     # 日期扩展
│       └── HapticsManager.swift     # 触觉反馈
├── Data/                            # 数据层
│   ├── Models/                      # 数据模型
│   │   ├── BaseModel.swift          # 基础模型
│   │   └── DashboardModels.swift    # 仪表盘数据模型
│   ├── Networking/                  # 网络请求
│   │   └── APIClient.swift          # API 客户端
│   └── Persistence/                 # 本地存储
│       ├── DataManager.swift        # 数据管理器
│       └── SchemaV1.swift           # 数据架构
├── Features/                        # 功能模块
│   ├── Dashboard/                   # 仪表盘
│   │   ├── ViewModels/
│   │   ├── Views/
│   │   └── Components/
│   ├── HealthCenter/                # 健康管理
│   │   ├── ViewModels/
│   │   └── Views/
│   ├── TrainingSystem/              # 知识库
│   │   ├── Models/
│   │   ├── ViewModels/
│   │   └── Views/
│   ├── TradingJournal/              # 交易日志
│   │   ├── ViewModels/
│   │   └── Views/
│   ├── SocialBlog/                  # 社媒和博客
│   │   ├── ViewModels/
│   │   └── Views/
│   ├── NewsAggregator/              # 资讯聚合
│   │   ├── Models/
│   │   └── Views/
│   ├── ProjectHub/                  # 项目管理
│   │   └── Views/
│   └── Tools/                       # 效率工具
│       └── Views/
└── Resources/                       # 资源文件
    ├── Assets/                      # 图片和 Mock 数据
    └── Localization/                # 本地化文件
```

---

## 🛠️ 技术栈

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Architecture**: MVVM + Observation Pattern
- **Data Persistence**: UserDefaults + JSON Codable
- **Networking**: URLSession + Swift Concurrency
- **Async/Await**: Swift Concurrency
- **Design Pattern**: Glassmorphism UI

---

## 📊 开发路线图

### Phase 1（已完成）
- ✅ 核心架构搭建
- ✅ 基础 UI 组件库
- ✅ 数据模型设计

### Phase 2（进行中）
- 🔄 各功能模块实现
- 🔄 本地数据持久化
- 🔄 基础网络功能

### Phase 3（计划中）
- ⏳ iCloud 同步
- ⏳ 高级数据分析
- ⏳ AI 智能建议

---

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

### 代码规范
- 遵循 Swift 官方编码规范
- 使用 SwiftUI 进行 UI 开发
- 添加必要的代码注释

### 提交流程

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

---

## 📝 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

---

## 📧 联系方式

- 📧 Email: [your-email@example.com]
- 🐦 Twitter: [@your-handle]
- 💼 LinkedIn: [your-profile]

---

**Personal OS v2** - 让生活和工作更有序，让创意和思想更有价值。
