# Phase Workflows

Each phase has two files:

- `Agents.md`: who does what and what must be handed off.
- `Skill.md`: repeatable execution instructions for that phase.

## Common Workflow

- Use Japanese for project documents and GitHub Issues by default.
- Treat the parent phase Issue as the milestone boundary.
- Create detailed sub-issues when starting a phase, not all at repository bootstrap time.
- Work one issue at a time on a dedicated branch.
- Update relevant docs in the same issue as implementation or decision work.
- Validate before closing an issue.

## Phases

1. [Requirements](01-requirements/Agents.md)
2. [Architecture](02-architecture/Agents.md)
3. [Repository and Environment](03-repository-environment/Agents.md)
4. [PC Bridge](04-pc-bridge/Agents.md)
5. [Android App](05-android-app/Agents.md)
6. [Push Notifications](06-push-notifications/Agents.md)
7. [QA](07-qa/Agents.md)
8. [Release](08-release/Agents.md)
