# Agent Guidelines for Pin Repository

These instructions apply to all AI coding agents working on this project.

## Mandatory Git Commits for Impactful Changes

You MUST create a Git commit for every impactful change made to this repository.

### When to Commit
- New feature implementation or enhancement (UI widgets, pages, state management).
- Bug fixes and layout adjustments.
- Window management, GTK runner, or platform channel modifications.
- Configuration or build script changes (`build_release.sh`, `launch_pin.sh`, `pubspec.yaml`, `pin.desktop`).
- Documentation updates (`README.md`, guides, architecture references).
- Test additions or updates.

### Commit Requirements
1. **Verification First**: Validate changes before committing (e.g., run `flutter test` or `dart analyze`).
2. **Conventional Commits Format**:
   - `feat(...)`: new features or capabilities
   - `fix(...)`: bug and layout fixes
   - `docs(...)`: documentation updates
   - `style(...)`: styling, theme, and UI adjustments
   - `refactor(...)`: structural code improvements
   - `test(...)`: test additions and updates
   - `chore(...)`: build scripts, configs, launcher shortcuts, dependencies
3. **Clean Staging**: Stage only the files associated with the change. Never commit temporary files, logs, or build artifacts.
