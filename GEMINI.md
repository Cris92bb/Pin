# Agent Instructions: Git Commits on Impactful Changes

For all coding tasks in this repository, the agent must adhere to:

## Code Quality, Design Tokens & FSD Compliance
- **File Size Limit (<= 300 LOC)**: Strive to keep all Dart source files under 300 lines of code. Split large classes and monolithic views into modular components in dedicated `components/` subdirectories.
- **Componentization & Doctype Comments**: Build cohesive, reusable widgets with complete Dart doc comments (`///`) providing role descriptions, architectural context, and parameter specifications.
- **Design Token Consistency**: Never hardcode colors (`Color(0x...)`). Always use `PinTokens` or `Theme.of(context)` for colors, radii, shadows, borders, and spacing.
- **Strict FSD Compliance**: Preserve unidirectional imports (`app` -> `pages` -> `widgets` -> `features` -> `entities` -> `shared`) and zero cross-slice imports. Validate with `tool/verify_fsd.dart --strict`.

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
