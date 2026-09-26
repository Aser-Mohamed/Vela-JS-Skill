# Architecture

This document describes how Vela-JS-Skill is put together internally, for anyone extending it or auditing what it does.

## Overview

Vela-JS-Skill is a single Claude Code **skill** (`skills/vela-js-skill/SKILL.md`), packaged as a **plugin** so it can be distributed and installed through a marketplace. The `SKILL.md` file acts purely as a **workflow coordinator**: it doesn't contain the actual stage logic or platform knowledge inline. Instead, it dispatches to separate stage files and loads knowledge files on demand, which keeps any single piece of context small and focused.

```
User request
     │
     ▼
SKILL.md  (coordinator: session management, checkpoint handling, stage dispatch)
     │
     ├──► stages/s1-prd.md        (loads knowledge/, rules/ as needed for PRD writing)
     ├──► stages/s2-tech.md       (loads rules/vela-platform.md, rules/vela-layout.md, etc.)
     └──► stages/s3-coding.md     (loads prompts/*.prompt.md, rules/vela-format.md, rules/vela-css.md, etc.)
```

All paths referenced inside `SKILL.md` and the stage files (`stages/`, `rules/`, `knowledge/`, `prompts/`) are relative to **the skill's own installed directory**, not the user's project. Generated work product — session state and code — is written to the **current project's working directory** instead, under `.ai-workspace/sessions/` and the project's own source tree respectively. This separation means the skill's own files are never mutated by a run, and multiple projects can use the same installed skill without cross-contamination.

## Session model

Each invocation of the workflow creates a session:

```json
{
  "session_id": "VELA-20260926-153000-a1b2",
  "requirement_name": "step-counter-app",
  "workflow_mode": "full",
  "current_stage": "S1",
  "created_at": "2026-09-26T15:30:00Z",
  "inputs": {
    "requirement_description": "...",
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

This is written to `.ai-workspace/sessions/<session_id>/session.json` in the project directory. The coordinator reads `current_stage` and `workflow_mode` on every turn to decide which stage file to dispatch to next, and updates stage status (`not_started` → `in_progress` → `pending_review` → `completed`, or `skipped` in Quick mode) as the user progresses through checkpoints.

Because the session lives in the project directory rather than in the skill or in Claude Code's own conversation state, a session survives across Claude Code restarts — reinvoking the skill in the same project directory picks the unfinished session back up.

## Stage dispatch

| Mode | Sequence |
|---|---|
| Full (default) | `stages/s1-prd.md` → `stages/s2-tech.md` → `stages/s3-coding.md` |
| Quick | S1 and S2 marked `skipped`; jumps straight to `stages/s3-coding.md` |

Before executing any stage, the coordinator reads that stage's file in full and follows its process exactly — stage files are self-contained instruction sets, not just prompts.

## Knowledge base loading

Knowledge is split across three directories by purpose, and loaded selectively rather than all at once:

- **`knowledge/`** — descriptive development guidance (project structure, manifest format, general best practices).
- **`rules/`** — prescriptive platform constraints (component/API whitelist, layout rules, `.ux` format rules, CSS rules, coding conventions, project initialization requirements, design-driven development rules, Figma MCP configuration).
- **`prompts/`** — dense, on-demand quick-reference material for components, APIs, and dev-guide/best-practice lookups, pulled in specifically during S3 code generation rather than kept in context throughout the whole workflow.

Each stage file declares which of these it needs, so, for example, S1 (PRD writing) doesn't load the `.ux` formatting rules that are only relevant once S3 starts generating code.

## Figma integration

When a Figma URL is supplied during the initial information-gathering step:

1. The URL is parsed to extract `file_key` and `node_id`.
2. Figma MCP is used to fetch the corresponding design data.
3. Referenced images are exported to `src/common/images/` in the project.
4. The resulting design data is injected into the context for S1–S3, so requirements, architecture, and generated markup/styles are all grounded in the actual design rather than a text description alone.

If no Figma MCP server is available in the current environment, this step degrades to description/screenshot-driven generation and the user is informed rather than the workflow failing.

## Interaction contract

The coordinator enforces a fixed, minimal interaction surface at every checkpoint (`y` / `e` / `n` / `q` / `status` / `back`) rather than open-ended chat at each step. This is a deliberate design choice: it keeps the workflow predictable and scriptable, and keeps the model from re-litigating already-approved output when the user just wants to move forward.

Feedback given via `e` is retained in full for the three most recent rounds and compressed to a summary beyond that, to bound context growth across long edit cycles.

## Optional hooks

`reference/hooks/` contains three standalone shell scripts that are **not wired up automatically**:

- `guard-dangerous-cmd.sh` — a `PreToolUse` hook that blocks destructive `rm` invocations and unapproved package-manager mutations.
- `validate-write.sh` — a `PostToolUse` hook that restricts file writes to an allow-listed set of project directories.
- `prompt-vela-workflow.sh` — a `UserPromptSubmit` hook that detects Vela-related trigger phrases and reminds the user to supply a requirement doc and/or design reference before generation starts.

These are provided as reference implementations for teams that want project-level guardrails around AI-driven code generation; they are intentionally kept out of the plugin's automatically-loaded surface because a global hook of this kind would affect unrelated, non-Vela projects. See [HOOKS.md](HOOKS.md) for setup.
