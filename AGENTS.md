# x10 workspace — agent guide

This document describes the x10 workspace layout and CLI contract for AI agents and automated tooling. It is designed to be placed at the workspace root so agents find it automatically.

## What is x10?

x10 manages multi-repo development projects using git worktrees. Each **project** groups one or more **repos** checked out at specific branches or PRs. A single declarative manifest (`x10.json`) is the source of truth. To change anything, use `x10 add`/`x10 rm`, or edit the manifest and re-run `x10 gen`. Do not hand-edit generated files.

## Layout

```
<workspace>/
  x10.json                        # SOURCE OF TRUTH — edit this (or use x10 add/rm)
  repos/<repo>/                   # canonical git clones (one per repo, stay on main/master)
  worktrees/<project>/<repo>/     # per-project checkouts on the project's branch
  projects/<project>/             # generated project definition (do not edit)
    <project>.code-workspace      #   multi-root Cursor/VS Code workspace
    .envrc                        #   direnv: exports <REPO>_PATH + X10_REPO_PATHS
    justfile                      #   optional recipes (needs just): status, branches, fetch, sync, prs
```

Shell integration lives in `bin/shell-init.zsh`, installed via `x10 setup`. It defines the `x10` shell function (so `x10 cd` works) and provides zsh tab-completion.

## The manifest: `x10.json`

```jsonc
{
  "org": "my-github-org",        // default GitHub org for unqualified repo names
  "projects": {
    "<project>": {
      "repos": [
        { "repo": "<name>",              "pr": 123 },
        { "repo": "<name>",              "branch": "feature/foo" },
        { "repo": "<name>",              "branch": "main", "mode": "link" },
        { "repo": "other-org/repo-name", "branch": "main" }
      ]
    }
  }
}
```

Repo entry fields:

- `repo` (required): repo name, optionally org-qualified. Unqualified names use the manifest `org`; qualified names (e.g. `other-org/lib`) use the given org. The local clone always lives at `repos/<repo-name>`.
- `pr` (optional): PR number. The generator resolves the head branch via `gh`. Mutually exclusive with `branch`.
- `branch` (optional): explicit branch name. Mutually exclusive with `pr`.
- `mode` (optional, default `worktree`):
  - `worktree` — creates/uses `worktrees/<project>/<repo>` on the resolved branch.
  - `link` — references `repos/<repo>` directly (no worktree). Use for shared repos on `main`/`master`.

## Commands

```bash
x10 init [dir] [--org ORG]   # initialize a new workspace
x10 ls                       # list projects
x10 open   [project]         # open in preferred editor
x10 cursor [project]         # open in Cursor
x10 code   [project]         # open in VS Code
x10 status [project]         # git status (all projects if omitted)
x10 sync   [project]         # fetch + fast-forward each repo
x10 prs    [project]         # PR state per repo
x10 cd <project> [repo]      # cd to a project or repo

x10 add <proj> <repo> [--pr N | --branch B] [--mode link|worktree]
x10 rm  <proj> <repo>

x10 gc [-y]                  # remove worktrees for merged/closed PRs
x10 gen   [project...]       # regenerate workspace files
x10 gen   --switch [proj...] # regenerate + re-point clean worktrees to manifest branch
x10 prune [--remove] [-y]    # report/remove orphaned worktrees

x10 config [key [value]]     # view or set user config (editor, default_org, root)
x10 doctor                   # check dependencies and config
x10 setup                    # install shell integration
x10 --version
```

## Common edits (for an agent)

- **Add a repo to a project**: `x10 add <project> <repo> --pr N` or `x10 add <project> <repo> --branch B [--mode link]`.
- **Remove a repo from a project**: `x10 rm <project> <repo>`, then `x10 prune --remove` to clean up the worktree.
- **Change a repo's branch**: edit the manifest entry, then `x10 gen --switch <project>`.
- **Add a new project**: `x10 add <new-project> <repo>` — auto-creates it.
- **A shared repo on main**: use `--mode link`.
- **A repo from another org**: use `other-org/repo-name` as the repo argument.

## Environment variables (from `.envrc`)

After `direnv allow`, every project directory exports:

| Variable | Value |
|----------|-------|
| `X10_ROOT` | Workspace root directory |
| `X10_PROJECT` | Current project name |
| `X10_PROJECT_DIR` | `$X10_ROOT/projects/<project>` |
| `<REPO>_PATH` | Absolute path to each repo (e.g. `MY_API_PATH`) |
| `X10_REPO_PATHS` | Newline-separated list of all repo paths |

Variable name convention: repo name uppercased with hyphens replaced by underscores (`data-fever-mcp` -> `DATA_FEVER_MCP_PATH`).

## Good to know

- **Worktrees share the object store.** Disk cost is just the working tree, not full git history.
- **Linked (`mode: link`) repos are writable.** A commit there affects every project that links them. Treat as read-only reference unless you explicitly want that.
- **Don't hand-edit generated files** (`*.code-workspace`, `.envrc`, `justfile`); they are overwritten on every `x10 gen` run.
- **`x10 open` uses the configured editor** — set via `x10 config editor <name>` or `$X10_EDITOR`.
- **`just` is optional.** The CLI provides `status`/`sync`/`prs` directly. The generated justfile is a convenience for users who have `just` installed.
- **`x10 gc` only removes worktrees** — it does not update `x10.json`. After running it, remove the entry from the manifest manually or with `x10 rm`.
