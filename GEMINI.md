# Agent Instructions: Git Commits on Impactful Changes

For all coding tasks in this repository, the agent must adhere to:

## Mandatory Commits on Impactful Changes
- **Requirement**: For every impactful change made to the codebase (feature addition, bug/layout fix, script/build update, documentation, or test modification), create a Git commit.
- **Pre-requisite**: Ensure changes are verified (e.g., `flutter test` or `dart analyze` pass).
- **Format**: Follow [Conventional Commits](https://www.conventionalcommits.org/):
  - `feat(...)`: new feature or functionality
  - `fix(...)`: bug or layout fix
  - `docs(...)`: documentation changes
  - `style(...)`: UI polish and styling tweaks
  - `refactor(...)`: non-breaking code restructuring
  - `test(...)`: test additions or adjustments
  - `chore(...)`: build scripts, desktop integration, dependency management
- **Staging**: Stage only the relevant changed files. Keep commits atomic and clean.

## Branching & Pull Request Policy
- **Merge into `develop` Only via PR**: Direct pushes to `develop` or `main` are strictly forbidden. All modifications must be committed to feature/fix branches and merged through a GitHub Pull Request.
- **Verification Before Merge**: Pull Requests must pass the FSD strict boundary audit, static analysis, and the automated test suite.
