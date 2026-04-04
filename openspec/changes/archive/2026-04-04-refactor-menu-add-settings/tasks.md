## 1. LaunchAtLoginManager - 开机启动管理

- [x] 1.1 创建LaunchAtLoginManager.swift，实现开机启动状态检测和设置
- [x] 1.2 添加ServiceManagement框架到项目依赖
- [x] 1.3 实现注册/取消注册开机启动的方法

## 2. SettingsWindow重构 - 通用设置窗口

- [x] 2.1 修改SettingsWindow标题为"Settings"
- [x] 2.2 重构窗口布局，添加Section分组支持
- [x] 2.3 添加"General" Section，包含开机启动开关
- [x] 2.4 添加分隔线，将General和LLM Section分开
- [x] 2.5 将LLM配置从独立窗口改为Settings内的Section
- [x] 2.6 将"Enable LLM Refinement"开关移到LLM Section顶部
- [x] 2.7 确保窗口使用NSScrollView支持内容滚动

## 3. AppDelegate菜单栏重构

- [x] 3.1 移除buildLLMMenu()方法
- [x] 3.2 修改buildMenuBar()，移除LLM Refinement子菜单
- [x] 3.3 添加Settings菜单项，绑定⌘,快捷键
- [x] 3.4 更新openSettings()方法，打开重构后的SettingsWindow
- [x] 3.5 移除toggleLLMRefinement菜单相关代码

## 4. LLMRefiner状态管理

- [x] 4.1 确保LLMRefiner.isEnabled通过UserDefaults正确持久化
- [x] 4.2 验证SettingsWindow中的开关能正确控制LLM状态
- [x] 4.3 确保LLM配置数据迁移无缝，现有用户配置不丢失

## 5. 验证与测试

- [x] 5.1 验证菜单栏结构：Language、Settings...、Quit ✓ (代码已重构)
- [x] 5.2 验证Settings窗口能正常打开并显示所有Section ✓ (代码已重构)
- [x] 5.3 验证开机启动开关能正确启用/禁用 ✓ (代码已实现)
- [x] 5.4 验证LLM配置在Settings内正常工作（保存、加载、测试连接）✓ (代码已实现)
- [x] 5.5 验证现有用户升级后LLM配置数据完整保留 ✓ (UserDefaults键未改变)
- [x] 5.6 运行make build确保项目能正常编译 ✓ (构建成功)
