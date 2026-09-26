# Usage guide

This walks through a full run of Vela-JS-Skill from a cold start to a finished project, with the actual prompts you'll see at each step.

## Prerequisites

- Claude Code installed and running, signed in to an Anthropic account with an active [Claude plan or API access](https://claude.com/pricing).
- The plugin installed (see the [README installation section](../README.md#installation)).
- For best results, Claude Code's active model set to **Claude Opus 5.5** for the session (`/model`). See [Model recommendation](#model-recommendation) below.
- An empty or existing project directory to work in.

## Model recommendation

Vela-JS-Skill's three stages ask the model to do three different kinds of work in sequence: turning a vague request into a structured PRD, translating that PRD into an architecture that respects the Vela component/API whitelist, and then writing conformant `.ux` code against that architecture. Because each stage's quality compounds into the next, using Anthropic's most capable model — **Claude Opus 5.5** — for the session minimizes compounding errors and reduces how many `e` (edit) rounds you need. Faster/lower-cost models can be used for quick, well-specified apps, but complex or design-driven builds benefit noticeably from Opus 5.5.

Model access and billing are provided directly by Anthropic through your Claude subscription or API account — the skill itself has no separate licensing cost.

## 1. Starting the workflow

From inside your project directory, either describe what you want directly, or invoke the skill explicitly:

```
/vela-js-skill
```

You'll see:

```
👋 欢迎使用 Vela 快应用自动开发工作流！

📝 请确认你的需求：
  "{your requirement description}"

👉 输入 y 确认需求 / e 修改需求描述
```

- Type `y` to confirm and continue.
- Type `e` to revise the requirement text before continuing.

## 2. Design reference (optional)

```
🎨 是否有设计稿？
  [1] 提供 Figma 链接或设计图片
  [2] 没有设计稿，跳过

👉 输入 1 提供设计稿 / 2 跳过
```

- Choose `1` to paste a Figma link or an image path. Once received, the skill confirms and proceeds to design-driven generation (see [ARCHITECTURE.md](ARCHITECTURE.md#figma-integration)).
- Choose `2` to skip and generate purely from your written description.

## 3. Choosing a workflow mode

```
💡 请选择工作流模式：
  [1] 完整流程 — S1 PRD → S2 技术方案 → S3 代码生成（推荐）
  [2] 快速模式 — 跳过 PRD 和技术方案，直接生成代码

👉 输入 1 或 2 选择模式
```

- **Full workflow (`1`)** — recommended for anything beyond a trivial app. Produces a PRD and a technical design document you can review before any code is written.
- **Quick mode (`2`)** — skips straight to code generation. Best for small, well-understood requests where you don't need review artifacts.

## 4. Working through the stages

Each stage (PRD, technical design, code generation) ends with the same checkpoint pattern:

| Command | What happens |
|---|---|
| `y` | Approves the stage output and advances to the next stage |
| `e` | Prompts you for feedback, then regenerates the current stage with that feedback applied |
| `n` | Discards the output entirely and regenerates the stage from scratch |
| `q` | Saves the session and exits — see [Resuming a session](#resuming-a-session) |
| `status` | Prints progress across all three stages |
| `back` | Returns to the previous stage (not available from S1) |

If you use `e` repeatedly (more than ~5 rounds) without converging, consider `n` instead — extensive incremental edits are compressed to a summary internally after the third round, and a fresh regeneration is often faster than continuing to patch.

## 5. Completion

```
🎉 Vela 快应用开发工作流已全部完成！

📊 完成总结:
  ✅ S1 PRD 生成 — 01-prd.md
  ✅ S2 技术方案 — 02-tech-design.md
  ✅ S3 功能研发 — 代码已写入项目工程目录

📂 PRD 和技术方案保存在: .ai-workspace/sessions/{session_id}/
```

Your generated `.ux` project files are in your project's working directory, ready to be built and deployed with Xiaomi's `aiot-toolkit`. The PRD and technical design documents remain under `.ai-workspace/sessions/<session-id>/` for reference or for onboarding a teammate to the same context.

## Resuming a session

If you exit mid-workflow with `q`, or close Claude Code entirely, simply reinvoke the skill in the same project directory. It detects the unfinished session under `.ai-workspace/sessions/` and offers to resume from the last completed stage rather than starting over.

## Design-driven generation

When you provide a Figma link, the skill:

1. Parses the URL to extract the `file_key` and `node_id`.
2. Retrieves the design data through a configured Figma MCP connector.
3. Exports the relevant image assets into `src/common/images/`.
4. Threads the design data into the context for every subsequent stage, so layout, spacing, and visual details in the PRD, technical design, and generated code all trace back to the source design.

If no Figma MCP connector is configured in your environment, the skill degrades gracefully: it lets you know, and continues in description/screenshot-driven mode instead of failing outright.
