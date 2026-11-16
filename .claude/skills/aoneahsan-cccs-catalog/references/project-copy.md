# Codex project copies of owner-created skills

**Last updated:** 2026-11-11

The owner's 2026-11-11 choice is to copy every related `aoneahsan-cccs-*` skill into each project. This is a Codex rule. The notebook's `custom-skills/` remains the source; a project copy is a pinned fork for that project. A global link alone no longer satisfies the Codex project-copy gate.

## Select at each phase

Read the project's `AGENTS.md`, its stack and the current task. Match **every** current-phase trigger against `rules/skill-bindings.md` and source skill descriptions. Include the whole matching design set for a click dummy or new UI; include the story skills when writing reader-facing content; include palette, typography, accessibility, platform, data and verification skills when their concerns are active. Recheck before the first edit of every later phase. A skill unrelated to the project or phase is not copied just to increase the count.

Use the exact `aoneahsan-cccs-*` folder name. Resolve its source through `~/.agents/skills/` or the notebook's `custom-skills/`; never guess a machine-specific notebook path. Copy **the entire source folder** into `<repo>/.claude/skills/<name>/`, including `SKILL.md`, `OVERVIEW.md`, `FLOW.mmd`, required `references/` and `assets/`. Copy files, not a symlink to the global folder. Do not create a second copy when the same skill is already present.

Before replacing an existing project copy, compare it with the current source and preserve documented project-specific fixes. Reconcile source updates deliberately; do not overwrite a locally modified skill silently. Record the source notebook commit and copy date in the task's commit or the project's existing skill inventory. The project-local file does not become the fleet source of truth.

## Verify before work begins

1. Confirm the copied `SKILL.md` frontmatter `name:` equals the folder name, and `OVERVIEW.md` and `FLOW.mmd` exist.
2. Check every referenced relative path resolves inside the copy; inspect any retained executable or command before running it. Run a representative command when the skill depends on one.
3. Scan the copied folder for secrets and private planning text, especially before committing a public repository. A public copy must contain only publishable guidance. If the source carries private material, make a safe project-local copy that preserves the applicable rules and verify it before staging.
4. Check the project's `.agents/skills/<name>` link points to its local `.claude/skills/<name>` copy after project sync. If the link is absent, run the established sync from that project and verify it; until then, load the local `SKILL.md` directly.
5. Review `git diff` and stage only skill files you own. Follow the project's commit and push authorization. Recheck source revisions on the next matching phase so a pinned copy does not silently drift.

Vetted external skills follow `aoneahsan-cccs-cloned-skills-library/references/copy-procedure.md` and keep their `ext-*` names. Codex copies all related vetted external matches without another approval. Quarantined, paid or unsafe sources remain blocked by their existing gates.
