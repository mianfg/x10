# x10 — Backlog

Improvement ideas, roughly grouped by area. Not ordered by priority.

---

## Shell & Installation

- **bash and fish support** — `shell-init.zsh` is zsh-only. Add `shell-init.bash` and `shell-init.fish` with equivalent wrapper function and completions. The `x10 setup` command should detect the active shell and install the right file.
- **Homebrew tap** — `brew install yourusername/tap/x10` so users do not need to clone manually.
- **`curl | bash` installer** — a one-liner that clones, sets `PATH`, and runs `x10 setup`.
- **Symlink install** — `x10 install` (or `install.sh`) to symlink `bin/x10` and `bin/x10-gen` into `/usr/local/bin` or `~/.local/bin`.

---

## Manifest & Projects

- **`x10 rename <project> <new-name>`** — rename a project in the manifest and move its `projects/` and `worktrees/` directories.
- **`x10 mv <proj> <repo> <new-proj>`** — move a repo entry from one project to another.
- **`x10 gc` should update the manifest** — after removing a worktree for a merged/closed PR, prompt to also remove the entry from `x10.json`. Currently users must do this manually.
- **`x10 gc` for link-mode repos** — currently only checks worktrees; linked repos whose PR is closed are silently skipped.
- **Manifest validation** — `x10 doctor` or a new `x10 validate` should check for: duplicate repo entries within a project, invalid `mode` values, `pr` + `branch` conflicts, entries with neither field, and repos that no longer exist on GitHub.
- **Multiple workspaces** — support for more than one `x10.json` / workspace root, switchable via `x10 workspace <name>` or `X10_ROOT`.
- **`x10 init --from <url-or-file>`** — bootstrap a workspace from a remote or local manifest template.

---

## CLI & UX

- **`x10 info <project>`** — show project details: repos, branches, PR states, last sync time.
- **`x10 status --short` / `--porcelain`** — one line per repo for scripting and CI.
- **`x10 ls --json`** — machine-readable output for all commands that produce lists.
- **`x10 worktrees`** — list all active worktrees with project, repo, branch, and dirty state.
- **`x10 new-pr <project> <repo>`** — push the current branch of a worktree and open a draft PR via `gh pr create`.
- **`x10 clone <repo>`** — clone a repo into `repos/` without adding it to any project.
- **`x10 open` from inside any repo** — currently works from `projects/` and `worktrees/`; extend `project_from_cwd` to also detect when CWD is inside `repos/<repo>`.
- **`x10 gen --switch` for dirty worktrees** — currently warns and skips; could offer to stash, switch, and pop.
- **Interactive `x10 add`** — when called without arguments, walk the user through project and repo selection interactively.
- **`x10 cd` with no args** — when inside a worktree, `x10 cd` with no project should cd to the project root (i.e., `projects/<current-project>`).

---

## Editors & Workspace Files

- **Zed workspace format** — Zed uses a different workspace file format (`.zed/`). Generate Zed workspace files alongside `.code-workspace` for users who prefer Zed.
- **Custom workspace settings** — allow a `settings` key in the manifest project entry to merge additional VS Code/Cursor settings into the generated `.code-workspace`.
- **Per-project CLAUDE.md / AGENTS.md generation** — optionally generate a `CLAUDE.md` or `AGENTS.md` in each project directory describing the repos and their roles.
- **Neovim / session support** — generate a Session.vim or a `nvim-session` compatible file for projects.

---

## Git & GitHub

- **Non-GitHub remotes** — currently assumes `git@github.com`. Support GitLab, Gitea, Bitbucket, and self-hosted instances via a `remote` field in the manifest or a per-org config.
- **SSH config host alias support** — resolve GitHub hostnames through `~/.ssh/config` `Host` aliases so users with custom SSH setups (e.g., `Host github-work`) do not need to modify the CLI.
- **Shallow clone option** — `x10 add --depth N` or a global config key to clone with `--depth` for repos with large history.
- **`x10 sync` conflict reporting** — when ff-only fails, show which commits are diverging, not just "diverged — skipped".
- **`x10 prs` with PR URL** — include the PR URL in the output so it is clickable in terminals that support hyperlinks.
- **Stale branch detection** — `x10 status` or a new `x10 stale` command to flag repos that have not been fetched recently.

---

## direnv & Environment

- **Language toolchain auto-setup** — detect `package.json`, `pyproject.toml`, `go.mod`, etc. in each repo and emit the corresponding `layout node`, `layout python`, etc. in the generated `.envrc`.
- **Shared `.envrc` snippets** — allow a `envrc` key in the manifest project entry to inject custom lines into the generated `.envrc`.
- **`direnv allow` on gen** — currently only runs if `direnv` is installed; should also warn when `.envrc` was updated but `direnv` is not installed.

---

## Portability & Compatibility

- **Windows / WSL2 support** — git worktree paths, symlinks, and `gh` auth behave differently on Windows. Document limitations and add workarounds.
- **`x10 export`** — dump the current workspace state (including resolved branches for `pr` entries) as a portable manifest snapshot.
- **`x10 import`** — apply a manifest snapshot, cloning and checking out everything from scratch.
- **Offline mode** — when `gh` or network is unavailable, `x10 gen` should fall back to cached branch resolutions for `pr` entries rather than failing hard.

---

## Hooks & Extensibility

- **Hook system** — `pre-gen` and `post-gen` hooks in the manifest or `~/.config/x10/hooks/` for custom scripts that run before/after workspace generation.
- **Plugin discovery** — look for `x10-<command>` executables on `$PATH`, enabling third-party sub-commands.
- **Custom `justfile` template** — allow a `justfile.template` in the workspace root or manifest entry to override the generated justfile content per project.

---

## Observability & CI

- **`x10 status --ci`** — exit with a non-zero code if any repo has uncommitted changes; useful in CI.
- **`x10 doctor --json`** — machine-readable health check output.
- **GitHub Actions integration** — a reusable workflow or action that sets up an x10 workspace in CI (clone repos, configure, export paths as outputs).

---

## Misc

- **`x10 --version` with update check** — optionally check for a newer release on GitHub and notify the user.
- **Man page** — generate a `x10.1` man page from the usage text.
- **Shell prompt integration** — a `x10_prompt_info` helper for zsh/bash prompts to show the current project name when inside a workspace.
