# Git Commit Automation Guidelines for AI Agents

Whenever working on this codebase, the agent must adhere to the following rules regarding Git version control:

## 1. Commit on Every Impactful Change
- For every impactful change made to the codebase, you MUST create a Git commit.
- Impactful changes include:
  - Adding or modifying features, UI components, or domain logic.
  - Fixing bugs, layout issues, or regressions.
  - Adding or modifying build scripts, desktop launchers, or configuration files.
  - Updating documentation (e.g., `README.md`, guides, or architecture notes).
  - Adding or updating tests.
  - Refactoring or significant dependency adjustments.

## 2. Timing and Quality Verification
- Create commits when a coherent unit of work is completed and verified.
- Run tests (`flutter test`) or static checks (`dart analyze`) when modifying Dart/Flutter code before committing to ensure the build remains clean.
- **Code & Documentation Consistency Check**: Before creating any commit that introduces, removes, or alters functionality, architecture, endpoints, models, tokens, shortcuts, or form factors, scan and check related markdown documentation (`README.md`, `docs/`, `.agents/rules/`) and update them to prevent drift.
- Never commit broken code, syntax errors, or unverified changes unless explicitly instructed.

## 3. Scope & Staging
- Do NOT use blind `git add .` if there are untracked build caches or temporary files.
- Stage specific files or directories related to the change (e.g., `git add lib/ widgets/ README.md`).
- Respect `.gitignore` and ensure transient artifacts (build outputs, `.dart_tool`, temporary caches) are never committed.

## 4. Conventional Commit Messages
- Use clear, professional [Conventional Commits](https://www.conventionalcommits.org/) format:
  - `feat(<scope>): <short description>` — new user-facing or technical features
  - `fix(<scope>): <short description>` — bug or layout fixes
  - `docs(<scope>): <short description>` — documentation changes
  - `refactor(<scope>): <short description>` — code changes that neither fix a bug nor add a feature
  - `style(<scope>): <short description>` — UI polish, formatting, styling tweaks
  - `perf(<scope>): <short description>` — performance optimizations
  - `test(<scope>): <short description>` — adding or correcting tests
  - `chore(<scope>): <short description>` — build configuration, scripts, packaging, desktop files
- The commit title should be imperative and concise (under 72 characters).
- Include bullet points or body explanation when the change requires additional context.

## 5. Branching & Pull Request Workflow
- **Never push directly to `develop` or `main`**: All direct pushes are blocked by the `.githooks/pre-push` hook.
- Merging into `develop` is permitted **ONLY** via a GitHub Pull Request from a feature branch (`feat/...`, `fix/...`, `chore/...`).
- Ensure all CI workflow checks (`.github/workflows/ci.yml`), FSD boundary verification, and test suites are green before merging the PR.
