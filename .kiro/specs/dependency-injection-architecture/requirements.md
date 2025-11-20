# Requirements Document

## Introduction

本规范定义了 Personal OS iOS v2 应用的依赖注入与服务架构重构需求。当前应用在入口点（personalos_ios_v2App）直接硬编码初始化多个服务（HealthKitService、GitHubService、NewsService、StockPriceService），导致强耦合、难以测试和环境切换困难。本重构旨在引入协议驱动的依赖注入容器，实现服务的可替换性、可测试性和模块边界清晰化。

## Glossary

- **DI Container**: 依赖注入容器，负责管理服务实例的创建、生命周期和依赖关系解析
- **Service Protocol**: 服务协议，定义服务的公共接口，使实现可替换
- **Service Factory**: 服务工厂，封装服务实例的创建逻辑
- **Environment**: 运行环境（Development、Staging、Production），决定使用真实服务或 Mock 服务
- **Service Locator**: 服务定位器，提供全局访问服务实例的入口
- **Mock Service**: 模拟服务，用于测试和开发环境的服务实现
- **Production Service**: 生产服务，连接真实后端 API 的服务实现

## Requirements

### Requirement 1

**User Story:** 作为开发者，我希望通过协议定义服务接口，以便可以在不同环境下切换服务实现（真实服务或 Mock 服务）

#### Acceptance Criteria

1. WHEN 定义服务时 THEN 系统应为每个服务创建对应的协议接口
2. WHEN 服务协议被定义时 THEN 协议应包含该服务的所有公共方法和属性
3. WHEN 实现服务时 THEN 系统应提供至少两种实现：生产实现和 Mock 实现
4. WHEN 服务方法被调用时 THEN 调用方应只依赖协议而非具体实现类型
5. WHERE 服务需要异步操作 THEN 协议方法应使用 async/await 或 Combine Publisher

### Requirement 2

**User Story:** 作为开发者，我希望使用依赖注入容器管理服务生命周期，以便集中控制服务的创建和销毁

#### Acceptance Criteria

1. WHEN 应用启动时 THEN DI Container 应被初始化并注册所有服务
2. WHEN 注册服务时 THEN DI Container 应支持单例（singleton）和瞬态（transient）两种生命周期
3. WHEN 请求服务实例时 THEN DI Container 应根据注册的生命周期返回相应实例
4. WHEN 服务依赖其他服务时 THEN DI Container 应自动解析并注入依赖
5. WHEN 应用环境改变时 THEN DI Container 应能够重新配置服务注册

### Requirement 3

**User Story:** 作为开发者，我希望在应用入口点移除硬编码的服务初始化，以便降低入口点的复杂度和耦合度

#### Acceptance Criteria

1. WHEN 应用启动时 THEN personalos_ios_v2App 不应直接实例化任何服务类
2. WHEN 视图需要服务时 THEN 视图应通过环境对象或属性注入获取服务
3. WHEN 配置服务时 THEN 服务配置应在独立的配置模块中完成
4. WHEN 添加新服务时 THEN 不应修改应用入口点代码

### Requirement 4

**User Story:** 作为测试工程师，我希望能够轻松注入 Mock 服务进行单元测试，以便隔离测试目标并提高测试速度

#### Acceptance Criteria

1. WHEN 运行单元测试时 THEN 测试应能够注入 Mock 服务实现
2. WHEN Mock 服务被调用时 THEN Mock 服务应返回预定义的测试数据
3. WHEN 测试需要验证服务调用时 THEN Mock 服务应记录调用历史
4. WHEN 测试不同场景时 THEN Mock 服务应支持配置不同的返回值和错误状态

### Requirement 5

**User Story:** 作为开发者，我希望通过环境配置自动选择服务实现，以便在开发、测试和生产环境使用不同的服务

#### Acceptance Criteria

1. WHEN 应用在开发环境运行时 THEN 系统应自动注册 Mock 服务
2. WHEN 应用在生产环境运行时 THEN 系统应自动注册生产服务
3. WHEN 环境配置改变时 THEN 系统应在下次启动时使用新的服务实现
4. WHEN 查询当前环境时 THEN 系统应提供明确的环境标识

### Requirement 6

**User Story:** 作为开发者，我希望服务初始化支持懒加载，以便提高应用启动速度并减少不必要的资源消耗

#### Acceptance Criteria

1. WHEN 应用启动时 THEN 非关键服务不应立即初始化
2. WHEN 首次访问服务时 THEN 系统应自动初始化该服务
3. WHEN 服务初始化失败时 THEN 系统应记录错误并提供重试机制
4. WHEN 服务未被使用时 THEN 系统不应消耗该服务的资源

### Requirement 7

**User Story:** 作为开发者，我希望为现有的核心服务（HealthKit、GitHub、News、Stock）创建协议和 DI 集成，以便验证新架构的可行性

#### Acceptance Criteria

1. WHEN 重构 HealthKitService 时 THEN 系统应创建 HealthServiceProtocol 并提供真实和 Mock 实现
2. WHEN 重构 GitHubService 时 THEN 系统应创建 GitHubServiceProtocol 并提供真实和 Mock 实现
3. WHEN 重构 NewsService 时 THEN 系统应创建 NewsServiceProtocol 并提供真实和 Mock 实现
4. WHEN 重构 StockPriceService 时 THEN 系统应创建 StockPriceServiceProtocol 并提供真实和 Mock 实现
5. WHEN 所有服务协议创建完成时 THEN 现有功能应保持不变
