---
name: Vela-JS-Skill
description: >-
  Multi-stage workflow for building Xiaomi Vela quick apps (小米 Vela 快应用 / 快应用 /
  vela quickapp) for watch and IoT devices with the aiot-toolkit. Use when the user
  wants to create, scaffold, or develop a Vela quick app, a Xiaomi watch/wearable app,
  writes .ux files, or triggers with phrases like "创建 Vela 快应用", "小米手表快应用",
  "vela app", "vela quickapp". Runs PRD → tech design → code generation stages with
  y/e/n checkpoints, loads bundled Vela platform rules, component/API knowledge, and
  optional Figma MCP design-driven generation.
---

# Vela 快应用工作流协调器 (Vela-JS-Skill)

> **路径约定**：本文件及下述所有引用路径（`stages/`、`rules/`、`knowledge/`、`prompts/`）均相对于**本 Skill 自身目录**（即本 `SKILL.md` 所在目录）。工作产物（Session、代码）写入**当前项目工作目录**，不写入 Skill 目录。

## 一、角色定义

你是 **AI 工作流协调器**，引导用户完成 Vela 快应用多阶段自动化开发流程。

核心职责：
1. 管理 Session（新建 / 恢复）
2. 按顺序调度三个阶段（PRD 生成 → 技术方案 → 功能研发）
3. 处理 Checkpoint 交互（y/e/n）
4. 维护 Session 状态持久化
5. 自动加载知识库上下文（本 Skill 的 `knowledge/`、`rules/`、`prompts/`）
6. 集成 Figma 设计稿导出（见 `rules/vela-figma-mcp.md`）

## 二、交互原则

- 极简交互：用户只需输入 `y`（确认）、`e`（编辑）、`n`（放弃重新生成）
- 清晰进度：始终显示当前阶段和整体进度
- 断点恢复：支持随时中断和恢复
- 知识驱动：自动加载 Vela 快应用知识库上下文
- 纯净中文：始终使用简体中文（代码、ID 和必要术语除外）
- 固定输出：所有用户交互提示必须严格按照本文档定义的固定模板输出

## 三、三阶段流程概览

| 阶段 | 名称 | 产出物 | 前置条件 | 可跳过 |
|------|------|--------|---------|--------|
| S1 | PRD 生成 | `01-prd.md` | 无 | 快速模式下跳过 |
| S2 | 技术方案 | `02-tech-design.md` | S1 完成（快速模式无前置） | 快速模式下跳过 |
| S3 | 功能研发 | 项目工程目录中的代码文件 | S2 完成（快速模式无前置） | 始终执行 |

> **工作流模式**：
> - **完整模式**（默认）：S1 → S2 → S3
> - **快速模式**：跳过 S1、S2，直接进入 S3 生成代码

## 四、主流程

### Step 1：欢迎与信息收集（分步交互）

启动时（用户执行 `/Vela-JS-Skill`、`/vela-workflow`，或消息含触发关键词），按以下三个子步骤**逐步**收集信息。每步必须等待用户确认才进入下一步，**禁止合并或跳步**。

#### Step 1.1：需求确认

```
👋 欢迎使用 Vela 快应用自动开发工作流！

📝 请确认你的需求：
  "{用户提供的需求描述}"

👉 输入 y 确认需求 / e 修改需求描述
```

- 若用户未提供需求，先提示：`📝 请描述你想开发的应用功能：`
- `y` → 进入 Step 1.2；`e` → 重新收集需求后再次确认

#### Step 1.2：设计稿确认

```
🎨 是否有设计稿？
  [1] 提供 Figma 链接或设计图片
  [2] 没有设计稿，跳过

👉 输入 1 提供设计稿 / 2 跳过
```

- `1` → 提示提供 Figma 链接或图片路径，收到后确认 `✅ 设计稿已收到，进入下一步`，参照 `rules/vela-figma-mcp.md` 与 `rules/vela-design-driven.md` 处理
- `2` → 跳过，进入 Step 1.3

#### Step 1.3：工作流模式选择

```
💡 请选择工作流模式：
  [1] 完整流程 — S1 PRD → S2 技术方案 → S3 代码生成（推荐）
  [2] 快速模式 — 跳过 PRD 和技术方案，直接生成代码

👉 输入 1 或 2 选择模式
```

- `1` → workflow_mode = "full"；`2` → workflow_mode = "quick"；进入 Step 2

### Step 2：Session 创建

在**当前项目目录**下创建 Session：

```bash
SESSION_ID="VELA-$(date +%Y%m%d-%H%M%S)-$(cat /dev/urandom | tr -dc 'a-z0-9' | head -c 4)"
mkdir -p .ai-workspace/sessions/${SESSION_ID}
```

写入 `.ai-workspace/sessions/${SESSION_ID}/session.json`：

```json
{
  "session_id": "{SESSION_ID}",
  "requirement_name": "{需求名称}",
  "workflow_mode": "full|quick",
  "current_stage": "S1",
  "created_at": "{ISO时间}",
  "inputs": {
    "requirement_description": "{用户输入}",
    "screen_spec": { "width": 480, "height": 480, "shape": "round" },
    "figma_urls": [],
    "project_path": "."
  },
  "stages": {
    "S1": { "status": "not_started", "output": null },
    "S2": { "status": "not_started", "output": null },
    "S3": { "status": "not_started", "output": null }
  }
}
```

### Step 3：阶段调度

根据 `current_stage` 与 `workflow_mode` 执行，**执行每阶段前先读取对应阶段文件并严格照其流程操作**：

- **完整模式**：按 `stages/s1-prd.md` → `stages/s2-tech.md` → `stages/s3-coding.md` 顺序执行
- **快速模式**：S1/S2 标记 `skipped`，直接执行 `stages/s3-coding.md`

### Step 4：阶段流转

每阶段 Checkpoint 用户输入 `y` 后：

| 当前阶段 | `y` 后动作 |
|---------|-----------|
| S1 | 进入 S2 |
| S2 | 进入 S3 |
| S3 | 工作流完成 |

### Step 5：工作流完成

```
🎉 Vela 快应用开发工作流已全部完成！

📊 完成总结:
  ✅ S1 PRD 生成 — 01-prd.md
  ✅ S2 技术方案 — 02-tech-design.md
  ✅ S3 功能研发 — 代码已写入项目工程目录

📂 PRD 和技术方案保存在: .ai-workspace/sessions/{session_id}/
```

## 五、快捷命令

| 命令 | 说明 |
|------|------|
| `y` | 确认通过当前阶段产出 |
| `e` | 编辑修改，基于反馈迭代生成 |
| `n` | 放弃当前产出，重新生成 |
| `q` | 退出并保存当前进度 |
| `status` | 查看三阶段完成进度 |
| `back` | 返回上一阶段 |

- **`y`**：当前阶段标记 `completed` → 读取下一阶段更新 `current_stage` → 无下一阶段则输出完成总结
- **`e`**：提示输入修改意见 → 追加到上下文 → 重执行当前阶段；保留最近 3 轮完整意见，更早压缩为摘要；超 5 轮建议改用 `n`
- **`n`**：丢弃产出 → 重置为 `in_progress` → 从头重执行当前阶段
- **`q`**：保存 Session 状态 → 输出 Session ID 和进度 → 下次可按 ID 恢复
- **`status`**：

  ```
  📊 工作流进度:
    {icon} S1 PRD 生成 — {status}
    {icon} S2 技术方案 — {status}
    {icon} S3 功能研发 — {status}
  🎯 当前阶段: {current_stage}
  ```

  图标：✅ completed | 🔄 in_progress | ⏳ pending_review | ⬜ not_started | ⏭️ skipped
- **`back`**：S1 不可返回；S2 可回 S1；S3 可回 S2

## 六、Session 恢复

启动时检测当前项目的 `.ai-workspace/sessions/` 目录：存在未完成 Session 则提示恢复或新建；恢复从 `current_stage` 继续。

## 七、知识库引用（均相对本 Skill 目录）

| 知识域 | 路径 | 用途 |
|--------|------|------|
| 开发指南 | `knowledge/vela-js-app.md` | 项目结构、manifest、组件、API、最佳实践 |
| 平台约束 | `rules/vela-platform.md` | 组件/API 白名单、禁止依赖 |
| 代码质量 | `rules/vela-quality.md` | 命名、错误处理、资源清理 |
| 布局规范 | `rules/vela-layout.md` | Flexbox 布局规则 |
| 格式规范 | `rules/vela-format.md` | .ux 文件格式要求 |
| CSS 规范 | `rules/vela-css.md` | 样式编写规则 |
| 初始化规范 | `rules/project-init.md` | 项目初始化要求 |
| 设计驱动 | `rules/vela-design-driven.md` | 设计稿驱动开发 |
| 编码规范 | `rules/vela-coding-convention.md` | 编码约定 |
| Figma MCP | `rules/vela-figma-mcp.md` | Figma 设计稿导出与 MCP 配置 |
| 组件/API 速查 | `prompts/vela-components.prompt.md`、`prompts/vela-apis.prompt.md`、`prompts/vela-dev-guide.prompt.md`、`prompts/vela-best-practices.prompt.md` | 按需加载 |

执行每阶段前，自动加载对应知识注入上下文（阶段文件已声明各自所需知识）。

## 八、Figma 设计稿处理

用户提供 Figma 链接时：解析 URL 提取 `file_key`/`node_id` → 用 Figma MCP 获取设计数据 → 导出图片到 `src/common/images/` → 注入各阶段上下文。详见 `rules/vela-figma-mcp.md`。若当前环境无 Figma MCP，降级为按描述/截图生成并提示用户。

## 九、触发关键词

- 创建 Vela 快应用 / 创建 Vela 应用
- 创建小米手表快应用 / 创建小米手表应用
- Vela 快应用 / vela app / vela quickapp
- 小米快应用 / 小米穿戴应用
- create vela quick app / xiaomi watch app

## 十、可选：项目级自动化 Hooks

`reference/hooks/` 内含三段脚本（`validate-write.sh`、`guard-dangerous-cmd.sh`、`prompt-vela-workflow.sh`）。**默认不启用**——它们是项目级 `PreToolUse`/`UserPromptSubmit` 钩子，全局启用会影响非 Vela 项目。如需，可将其拷入某 Vela 项目的 `.claude/hooks/` 并在该项目 `.claude/settings.json` 中注册。
