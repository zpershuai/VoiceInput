<!-- opencode:openspec-agent-optimized:start -->
## Agent Execution Plan

### Phase Summary
1. Recon
2. Implementation
3. Review
4. Verification

### Routing Notes
- Use `@explorer` when existing implementation paths are unclear.
- Use `@librarian` when external APIs or platform behavior need confirmation.
- Use `@designer` for UI-heavy changes.
- Use `@oracle` for permission, security, architecture, or migration review.

### Acceptance Signals
- Repository documentation SHALL provide layered navigation
- Documentation SHALL describe the end-to-end runtime workflow
- Documentation SHALL explain module boundaries and data flow
- Documentation SHALL provide actionable troubleshooting paths
- Documentation SHALL define maintenance expectations
- Settings window uses compact top spacing
- Bottom action buttons remain fully visible
- Settings sections keep a clean vertical rhythm
- Settings menu item matches peer item style
<!-- opencode:openspec-agent-optimized:end -->

## 1. Documentation Architecture

- [x] [route: @explorer -> @designer -> @fixer] 1.1 Audit the current `README.md` and `docs/*.md` content, identify overlap and missing coverage, and define the target responsibility of each document layer
- [x] [route: @explorer -> @designer -> @fixer] 1.2 Design the upgraded documentation information architecture for repository entry, deep technical guides, troubleshooting, and reference material
- [x] [route: @fixer] 1.3 Decide which existing documents will be rewritten versus split or newly added so the structure matches the documented architecture

## 2. Workflow And Architecture Content

- [x] [route: @explorer -> @fixer] 2.1 Reconstruct the end-to-end runtime workflow from the current source code, covering launch, permission handling, shortcut monitoring, recording, recognition, optional LLM refinement, and text injection
- [x] [route: @explorer -> @fixer] 2.2 Document the core module boundaries, callback relationships, and key state transitions across `AppDelegate`, `GlobalEventMonitor`, `SpeechRecognizer`, `FloatingWindow`, `LLMRefiner`, `TextInjector`, `SettingsWindow`, `LanguageManager`, and `Logger`
- [x] [route: @explorer -> @fixer] 2.3 Document the key runtime data flows for audio, transcription text, refined text, settings, permissions, and logs in a form maintainers can trace during feature work

## 3. Troubleshooting And Maintenance Guides

- [x] [route: @fixer] 3.1 Rewrite troubleshooting guidance so common symptoms map to likely modules, required permissions, external dependencies, and relevant log modules
- [x] [route: @fixer] 3.2 Add documentation maintenance rules that state which documentation layers must be updated when user-visible behavior, workflow, logging, or architecture changes

## 4. Entry Documents And Consistency Validation

- [x] [route: @fixer] 4.1 Rewrite `README.md` as the top-level entry document with concise workflow summary and navigation into deep docs
- [x] [route: @fixer] 4.2 Rewrite `docs/README.md` as the deep documentation index organized by maintainer goals
- [x] [route: @fixer] 4.3 Verify the upgraded document set is internally consistent with current source behavior and that navigation from `README.md` into `docs/` is complete
