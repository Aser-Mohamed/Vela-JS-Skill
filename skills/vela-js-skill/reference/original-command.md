# Vela 快应用开发工作流

启动 Vela 快应用多阶段自动化开发工作流。

## 使用方式

用户输入 `/vela-workflow` 启动工作流。

## 执行指令

请严格按照以下步骤执行：

1. 读取 `the skill root SKILL.md` 获取工作流协调器完整指令
2. 检查 `.ai-workspace/sessions/` 目录是否存在未完成的 Session
   - 若有未完成 Session：提示用户选择恢复或新建
   - 若无：开始新工作流
3. 按 SKILL.md 中定义的主流程执行：
   - Step 1: 欢迎与模式选择
   - Step 2: Session 创建
   - Step 3: 阶段调度（读取对应阶段的 SKILL.md 执行）
   - Step 4: 阶段流转
   - Step 5: 工作流完成

## 阶段 Skill 路径

| 阶段 | Skill 路径 |
|------|-----------|
| S1 PRD | `stages/s1-prd.md` |
| S2 技术方案 | `stages/s2-tech.md` |
| S3 功能研发 | `stages/s3-coding.md` |

## 知识库路径

| 知识域 | 路径 |
|--------|------|
| 开发指南 | `knowledge/vela-js-app.md` |
| 平台约束 | `rules/vela-platform.md` |
| 代码质量 | `rules/vela-quality.md` |
| 布局规范 | `rules/vela-layout.md` |
| 格式规范 | `rules/vela-format.md` |
| CSS 规范 | `rules/vela-css.md` |
| 初始化规范 | `rules/project-init.md` |
| 设计驱动 | `rules/vela-design-driven.md` |
| 编码规范 | `rules/vela-coding-convention.md` |

## 快捷命令

工作流启动后，用户可随时使用以下快捷命令：

- `y` — 确认通过当前阶段
- `e` — 编辑修改
- `n` — 放弃重做
- `q` — 退出保存进度
- `status` — 查看进度
- `back` — 返回上一阶段

## 约束

- 始终使用简体中文交互
- 每个 Checkpoint 必须阻塞等待用户输入
- 代码产出直接写入项目工程目录，非 Session 目录
- 严格遵守 `rules/` 下所有规则
