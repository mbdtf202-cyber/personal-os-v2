# 极限优化快速启动指南

5 分钟快速上手 PersonalOS 的极限优化功能。

## 🚀 快速开始

### 1. 查看当前配置对比

```bash
./Scripts/compare_configurations.sh
```

这会显示 Debug 和 Release 模式的配置差异。

### 2. 配置 Feature Flags

#### 选项 A：使用完整配置（所有功能）
```bash
./Scripts/generate_feature_flags.sh feature-flags.json
```

#### 选项 B：使用最小配置（仅 Dashboard）
```bash
./Scripts/generate_feature_flags.sh feature-flags.minimal.json
```

#### 选项 C：自定义配置
编辑 `feature-flags.json`：
```json
{
  "dashboard": true,
  "trading": true,
  "social": false,
  "news": false,
  "health": true,
  "projectHub": false,
  "training": false,
  "tools": true
}
```

然后运行：
```bash
./Scripts/generate_feature_flags.sh feature-flags.json
```

### 3. 构建优化版本

#### Debug 构建（快速迭代）
```bash
xcodebuild clean build \
  -project personalos-ios-v2.xcodeproj \
  -scheme personalos-ios-v2 \
  -configuration Debug \
  -xcconfig .xcconfig/Debug.xcconfig
```

#### Release 构建（极限优化）
```bash
xcodebuild clean build \
  -project personalos-ios-v2.xcodeproj \
  -scheme personalos-ios-v2 \
  -configuration Release \
  -xcconfig .xcconfig/Release.xcconfig
```

### 4. 分析包体积

```bash
./Scripts/analyze_binary_size.sh build/Release-iphoneos/personalos-ios-v2.app
```

### 5. 验证优化设置

```bash
# 设置环境变量模拟 Release 构建
CONFIGURATION=Release \
LLVM_LTO=YES_THIN \
SWIFT_REFLECTION_METADATA_LEVEL=none \
STRIP_INSTALLED_PRODUCT=YES \
SWIFT_COMPILATION_MODE=wholemodule \
DEAD_CODE_STRIPPING=YES \
SWIFT_OPTIMIZATION_LEVEL=-O \
./Scripts/validate_build_settings.sh
```

---

## 📊 优化效果预期

| 指标 | Debug | Release | 改善 |
|------|-------|---------|------|
| 包体积 | ~100MB | ~60MB | **-40%** |
| 启动时间 | 2s | 0.8s | **-60%** |
| 编译时间 | 3min | 5min | +67% |
| 逆向难度 | ⭐ | ⭐⭐⭐⭐⭐ | +400% |

---

## 🎯 常见场景

### 场景 1：日常开发
```bash
# 使用 Debug 配置，快速迭代
xcodebuild -configuration Debug
```

### 场景 2：性能测试
```bash
# 使用 Release 配置，测试真实性能
xcodebuild -configuration Release
./Scripts/analyze_binary_size.sh
```

### 场景 3：App Store 发布
```bash
# 1. 生成完整 Feature Flags
./Scripts/generate_feature_flags.sh feature-flags.json

# 2. Release 构建
xcodebuild -configuration Release -xcconfig .xcconfig/Release.xcconfig

# 3. 验证优化
./Scripts/validate_build_settings.sh

# 4. 分析包体积
./Scripts/analyze_binary_size.sh
```

### 场景 4：定制版本（仅特定功能）
```bash
# 1. 创建定制配置
cat > feature-flags.custom.json << EOF
{
  "dashboard": true,
  "trading": true,
  "social": false,
  "news": false,
  "health": false,
  "projectHub": false,
  "training": false,
  "tools": false
}
EOF

# 2. 生成 Feature Flags
./Scripts/generate_feature_flags.sh feature-flags.custom.json

# 3. 构建
xcodebuild -configuration Release
```

---

## 🔧 故障排查

### 问题：编译失败 "LTO error"
```bash
# 解决方案：使用 Thin LTO 而不是 Monolithic
# 编辑 .xcconfig/Release.xcconfig
LLVM_LTO = YES_THIN  # 而不是 YES
```

### 问题：运行时崩溃 "Mirror reflection failed"
```bash
# 解决方案：保留反射元数据
# 编辑 .xcconfig/Release.xcconfig
SWIFT_REFLECTION_METADATA_LEVEL = without-names  # 而不是 none
```

### 问题：包体积没有减小
```bash
# 检查优化是否生效
./Scripts/validate_build_settings.sh

# 分析哪些文件占用空间
./Scripts/analyze_binary_size.sh
```

---

## 📚 进阶阅读

- [完整优化指南](EXTREME_OPTIMIZATION_GUIDE.md)
- [架构文档](ARCHITECTURE_COMPLETE.md)
- [CI/CD 配置](.github/workflows/ios-ci.yml)

---

## ✅ 检查清单

在发布前确保：

- [ ] 运行 `./Scripts/validate_build_settings.sh` 通过
- [ ] 运行 `./Scripts/analyze_binary_size.sh` 包体积 < 50MB
- [ ] 所有单元测试通过
- [ ] 性能测试通过（`CompilationPerformanceTests`）
- [ ] 在真机上测试启动时间 < 1s
- [ ] 检查崩溃日志可以正确符号化

---

## 💡 提示

1. **开发时使用 Debug 配置** - 编译快，调试方便
2. **测试时使用 Release 配置** - 真实性能
3. **定期监控包体积** - 每个 Sprint 检查一次
4. **保存 dSYM 文件** - 用于崩溃分析
5. **渐进式优化** - 先 Thin LTO，再考虑 Monolithic

---

## 🎉 完成！

现在你已经掌握了 PersonalOS 的极限优化技巧。

记住：**过早优化是万恶之源**。先保证功能正确，再追求极致性能。
