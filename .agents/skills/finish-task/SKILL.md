---
name: finish-task
description: Validate, inspect, and commit a completed focused CoreCritters task when the user requests closure.
---

1. Run `./tools/check.sh`. If it fails, identify the relevant error, fix failures caused by this task, and rerun it. Never commit while validation fails.
2. Run `git status --short`, `git diff --stat`, and `git diff`. Inspect enough of the diff to understand the task. Check for generated Godot caches, temporary or debug files, credentials, unrelated user changes, and unexpected large or binary files. Never revert unrelated user changes.
3. Stage explicit paths relevant to the task. Use `git add -A` only when all current changes clearly belong to it. Leave unrelated changes uncommitted.
4. Create one focused Conventional Commit with a concise subject based on the actual diff. Common prefixes: `feat:`, `fix:`, `refactor:`, `chore:`, `test:`, `docs:`. Split only for a clear technical reason. Never amend or rewrite history, force push, or push unless explicitly requested.
5. Run `git status --short` after committing. Report only validation PASS/FAIL, the short commit hash and subject, and any files intentionally left uncommitted.
