# StreakManager 功能验证指南

## 🚀 Increment 1 完成情况

✅ **StreakManager 核心逻辑实现完成**

### 已实现的功能
1. **数据模型**: `StreakData`, `StreakStatus`, `StreakMilestone`
2. **核心管理器**: `StreakManager` 单例类
3. **系统集成**: 与 `TaskStore` 和 `FocusTimerManager` 集成
4. **调试界面**: `StreakDebugView` 用于测试验证
5. **应用初始化**: 在 `TodoListApp` 中初始化

### 核心功能特性
- 连续使用天数自动追踪
- 24小时宽限期机制
- 里程碑系统(3、7、30、100天)
- 数据持久化保存
- 详细的控制台日志输出
- 与现有任务和专注系统无缝集成

## 🔍 如何验证功能

### 1. 控制台输出验证
运行应用后，在Xcode控制台中查看以下日志：

```
🚀 TodoListApp: 应用启动，初始化各个管理器
🔥 StreakManager: 初始化开始
🔥 StreakManager: 无持久化数据，使用默认值
🔥 StreakManager: 今日尚未标记活跃
🔥 StreakManager: 检查应用启动时的连续状态
🔥 StreakManager: 准备开始新的连续记录
🔥 StreakManager: 初始化完成 - 当前连续天数: 0
🚀 TodoListApp: StreakManager 已初始化
```

### 2. 功能测试步骤

#### 测试任务完成触发
1. 创建一个新任务
2. 完成这个任务
3. 控制台应显示：
   ```
   📋 TaskStore: 任务完成，标记今日活跃
   🔥 StreakManager: 尝试标记今日活跃 - [当前日期]
   🔥 StreakManager: 连续天数更新 - 从 0 到 1
   ```

#### 测试专注完成触发
1. 开始一个专注会话
2. 完成专注会话
3. 控制台应显示：
   ```
   🍅 FocusTimerManager: 专注会话完成，标记今日活跃
   🔥 StreakManager: 连续天数更新 - 从 X 到 X+1
   ```

#### 测试重复标记保护
1. 在同一天多次完成任务或专注
2. 控制台应显示：
   ```
   🔥 StreakManager: 今日已标记过活跃，跳过
   ```

### 3. 调试界面验证
1. 进入 **设置** → **调试功能** → **Streak调试**
2. 查看当前状态信息
3. 点击各种测试按钮验证功能
4. 使用"查看详细状态"按钮查看完整状态信息

### 4. 数据持久化验证
1. 标记今日活跃后关闭应用
2. 重新打开应用
3. 进入调试界面，确认连续天数保持正确
4. 控制台应显示数据成功加载

### 5. 里程碑系统验证
1. 使用调试界面的"模拟昨天活跃"功能
2. 再标记今日活跃
3. 当连续天数达到3天时，控制台应显示：
   ```
   🎉 StreakManager: 解锁新里程碑! 新的开始 (3天)
   ```

## 📊 预期的控制台输出示例

### 首次运行
```
🚀 TodoListApp: 应用启动，初始化各个管理器
🔥 StreakManager: 初始化开始
🔥 StreakManager: 无持久化数据，使用默认值
🔥 StreakManager: 今日尚未标记活跃
🔥 StreakManager: 检查应用启动时的连续状态
🔥 StreakManager: 无历史活跃记录，状态为新开始
🔥 StreakManager: 初始化完成 - 当前连续天数: 0
🚀 TodoListApp: StreakManager 已初始化
```

### 完成第一个任务
```
📋 TaskStore: 任务完成，标记今日活跃
🔥 StreakManager: 尝试标记今日活跃 - 2025年8月1日 下午5:30:00
🔥 StreakManager: 更新今日活跃状态
🔥 StreakManager: 首次使用，开始计数
🔥 StreakManager: 连续天数更新 - 从 0 到 1
🔥 StreakManager: 保存数据到持久化存储
🔥 StreakManager: 数据保存成功
```

### 达成第一个里程碑
```
🔥 StreakManager: 连续天数更新 - 从 2 到 3
🎉 StreakManager: 解锁新里程碑! 新的开始 (3天)
```

## 🐛 可能的问题和解决方案

### 问题1: 控制台没有任何StreakManager日志
**原因**: 可能是StreakManager没有被正确初始化
**解决**: 检查 `TodoListApp.swift` 中是否正确添加了 `streakManager` 初始化

### 问题2: 调试界面无法访问
**原因**: 可能是在Release模式下运行
**解决**: 确保在Debug模式下运行，或者将 `#if DEBUG` 条件移除

### 问题3: 数据不能持久化
**原因**: JSON编码/解码失败
**解决**: 检查 `StreakData` 模型是否正确实现了 `Codable`

### 问题4: 连续天数逻辑不正确
**原因**: 日期计算逻辑错误
**解决**: 使用调试界面的"查看详细状态"功能检查各个日期值

## ✅ 验收标准

本次增量开发成功的标志：

1. ✅ 应用启动时能看到StreakManager初始化日志
2. ✅ 完成任务时能标记今日活跃并增加连续天数
3. ✅ 完成专注时能标记今日活跃并增加连续天数
4. ✅ 同一天重复操作不会重复计数
5. ✅ 数据能正确保存和加载
6. ✅ 调试界面能正常访问和使用
7. ✅ 连续天数逻辑正确（隔天+1，中断重置）
8. ✅ 里程碑系统能正确检测和通知

## 🎯 下一步计划

**Increment 2**: StreakCardView UI组件
- 在HomeView中显示连续天数卡片
- 美观的UI设计和动画效果
- 实时数据绑定和更新
- 里程碑进度显示

当前Increment 1专注于核心逻辑实现和验证，确保底层功能扎实可靠，为后续UI开发打好基础。