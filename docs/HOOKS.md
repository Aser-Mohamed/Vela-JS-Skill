# Optional safety hooks

Vela-JS-Skill ships three reference hook scripts under `skills/vela-js-skill/reference/hooks/`. They are **disabled by default** and are not registered anywhere automatically — they're project-level Claude Code hooks, and enabling them globally would affect every project you use Claude Code in, not just Vela projects.

Use these if you want extra guardrails around AI-driven code generation on a specific Vela project.

## What each hook does

| Script | Hook event | Behavior |
|---|---|---|
| `guard-dangerous-cmd.sh` | `PreToolUse` | Inspects a proposed shell command before it runs. Blocks destructive recursive deletes (e.g. `rm -rf` against the repo root, home directory, or `node_modules`) and unapproved package-manager mutations (`npm install`/`add`/`remove`, etc.), requiring explicit user confirmation instead. |
| `validate-write.sh` | `PostToolUse` | Checks that a file write landed inside an allow-listed set of directories (`src/`, `pages/`, `.ai-workspace/`, `.claude/`, `.github/`, `common/`) relative to the project root, flagging writes outside that scope. |
| `prompt-vela-workflow.sh` | `UserPromptSubmit` | Scans the incoming prompt for Vela-related trigger phrases and, if matched, reminds the user to provide a requirement document and/or design reference before generation begins. |

Each script follows the standard Claude Code hook exit-code contract: exit `0` to allow, exit `2` to block with a message.

## Enabling a hook for one project

1. Copy the script(s) you want into that project's local hooks directory:

   ```bash
   mkdir -p .claude/hooks
   cp <plugin-install-path>/skills/vela-js-skill/reference/hooks/guard-dangerous-cmd.sh .claude/hooks/
   chmod +x .claude/hooks/guard-dangerous-cmd.sh
   ```

2. Register it in that project's `.claude/settings.json`:

   ```json
   {
     "hooks": {
       "PreToolUse": [
         {
           "matcher": "Bash",
           "hooks": [
             { "type": "command", "command": ".claude/hooks/guard-dangerous-cmd.sh" }
           ]
         }
       ]
     }
   }
   ```

   Adjust the `matcher` and hook event (`PreToolUse`, `PostToolUse`, `UserPromptSubmit`) to match the script you're registering — see the table above.

3. Before relying on `validate-write.sh` in your own project, edit its `PROJECT_ROOT` variable to match your actual project path; it ships with a placeholder path from the original author's environment.

## Notes

- These scripts are provided as a starting point, not a complete security boundary. Review and adapt them to your own project's directory layout and risk tolerance before relying on them.
- Because they're registered per-project rather than through the plugin itself, updating the plugin does not automatically update copies of these scripts you've placed into a project — re-copy them after a plugin update if you want the latest version.
