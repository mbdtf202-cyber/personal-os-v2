#!/bin/bash
# 验证极限优化实施完整性

# 不使用 set -e，因为我们需要继续检查所有项目

echo "🔍 验证极限优化实施..."
echo "================================"
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查计数
PASSED=0
FAILED=0

# 检查函数
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✅${NC} $1"
        ((PASSED++))
    else
        echo -e "${RED}❌${NC} $1 (缺失)"
        ((FAILED++))
    fi
}

check_executable() {
    if [ -x "$1" ]; then
        echo -e "${GREEN}✅${NC} $1 (可执行)"
        ((PASSED++))
    else
        echo -e "${RED}❌${NC} $1 (不可执行)"
        ((FAILED++))
    fi
}

echo "📁 检查核心文件..."
echo "---"

# 1. Perfect Architecture
echo ""
echo "1️⃣  Perfect Architecture (Atomic Split)"
check_file "Packages/PersonalOSFoundation/Package.swift"
check_file "Packages/PersonalOSFoundation/Sources/PersonalOSFoundation/Logging/LoggerProtocol.swift"
check_file "Packages/PersonalOSModels/Package.swift"
check_file "Packages/PersonalOSCore/Package.swift"
check_file "Packages/PersonalOSDesignSystem/Package.swift"
check_file "Packages/PersonalOSDashboard/Package.swift"
check_file "PERFECT_ARCHITECTURE.md"

# 2. Feature Modularization
echo ""
echo "2️⃣  Feature Modularization"
check_file "Packages/PersonalOSDashboard/Sources/PersonalOSDashboard/DashboardFeature.swift"
check_file "personalos-ios-v2/Core/Configuration/FeatureFlags.swift"
check_file "feature-flags.json"
check_file "feature-flags.minimal.json"

# 3. Build Optimization
echo ""
echo "3️⃣  Build Optimization"
check_file ".xcconfig/Debug.xcconfig"
check_file ".xcconfig/Release.xcconfig"

# 4. Compile-Time DI
echo ""
echo "4️⃣  Compile-Time Dependency Injection"
check_file "personalos-ios-v2/Core/DependencyInjection/CompileTimeDI.swift"

# 5. Scripts
echo ""
echo "5️⃣  Automation Scripts"
check_executable "Scripts/generate_feature_flags.sh"
check_executable "Scripts/validate_build_settings.sh"
check_executable "Scripts/analyze_binary_size.sh"
check_executable "Scripts/compare_configurations.sh"

# 6. Tests
echo ""
echo "6️⃣  Performance Tests"
check_file "personalos-ios-v2Tests/CompilationPerformanceTests.swift"

# 7. Documentation
echo ""
echo "7️⃣  Documentation"
check_file "EXTREME_OPTIMIZATION_GUIDE.md"
check_file "QUICK_START_OPTIMIZATION.md"
check_file "EXTREME_OPTIMIZATIONS_SUMMARY.md"

# 8. CI/CD
echo ""
echo "8️⃣  CI/CD Integration"
if grep -q "build-optimization-check" .github/workflows/ios-ci.yml; then
    echo -e "${GREEN}✅${NC} CI/CD 已集成优化检查"
    ((PASSED++))
else
    echo -e "${RED}❌${NC} CI/CD 未集成优化检查"
    ((FAILED++))
fi

# 总结
echo ""
echo "================================"
echo "📊 验证结果"
echo "================================"
echo -e "通过: ${GREEN}$PASSED${NC}"
echo -e "失败: ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 所有检查通过！极限优化实施完整。${NC}"
    echo ""
    echo "📚 下一步："
    echo "  1. 运行 ./Scripts/compare_configurations.sh 查看配置对比"
    echo "  2. 运行 ./Scripts/generate_feature_flags.sh feature-flags.json 生成 Feature Flags"
    echo "  3. 阅读 QUICK_START_OPTIMIZATION.md 快速上手"
    exit 0
else
    echo -e "${RED}⚠️  有 $FAILED 项检查失败，请修复后重试。${NC}"
    exit 1
fi
