# x10

Multi-repo workspace manager for GitHub projects using git worktrees and VS Code / Cursor multi-root workspaces.

Each **project** groups one or more repos checked out at specific branches or PRs. A single declarative manifest (`x10.json`) is the source of truth — x10 handles cloning, worktree creation, workspace files, and per-project tooling.

## Why x10?

Working across multiple related repos is painful: switching branches, keeping things in sync, and having your editor understand the whole context at once. x10 solves this by:

- **Isolating work per project** — each project gets its own worktrees on the right branches, so you can have the same repo checked out at three different PRs simultaneously.
- **One-command setup** — `x10 add my-project my-repo --pr 42` clones, creates the worktree, and regenerates the workspace file.
- **Editor integration** — generates `.code-workspace` files so Cursor/VS Code open all repos for a project as a single multi-root workspace.
- **Day-to-day CLI** — `x10 status`, `x10 sync`, `x10 prs`, `x10 cd` work across all repos in a project at once.

## Prerequisites

```bash
brew install git jq gh
# Recommended:
brew install fzf direnv just
```

- `git`, `jq` — required
- `gh` — required for PR resolution (`--pr`), `x10 prs`, `x10 gc`
- `fzf` — interactive project picker (falls back to numbered menu)
- `direnv` — auto-loads `.envrc` per project
- `just` — per-project task runner (generated `justfile` is optional)

## Installation

```bash
# Clone into your preferred location
git clone https://github.com/yourusername/x10 ~/.x10

# Add the bin directory to PATH (or symlink x10 and x10-gen into /usr/local/bin)
echo 'export PATH="$HOME/.x10/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Initialize a workspace
x10 init ~/dev --org my-github-org

# Install shell integration (x10 cd + tab-completion)
x10 setup
source ~/.zshrc

# Verify
x10 doctor
```

> **Tip:** Set `X10_ROOT` to point at your workspace if it is not `~/x10`:
> ```bash
> export X10_ROOT="$HOME/dev"   # add to ~/.zshrc before the x10 setup block
> ```

## Quick start

```bash
# Add repos to a project (creates the project if it does not exist)
x10 add my-project my-repo                          # auto-detects default branch
x10 add my-project my-repo --pr 42                  # track a specific PR
x10 add my-project my-repo --branch feature/x       # explicit branch
x10 add my-project my-repo --branch main --mode link # shared read-only ref on main
x10 add my-project other-org/their-repo --branch main # repo from another GitHub org

# Open the project in your editor
x10 open my-project

# Day-to-day
x10 status              # git status across all repos in all projects
x10 sync                # fetch + fast-forward all repos
x10 prs                 # PR state for every repo
x10 cd my-project       # cd into the project dir
x10 cd my-project repo  # cd into a specific repo in the project

# Housekeeping
x10 gc                  # remove worktrees for merged/closed PRs (interactive)
x10 gc -y               # same, non-interactive
x10 prune               # report orphaned worktrees not in the manifest
x10 prune --remove      # remove them
```

## Commands

| Command | Description |
|---------|-------------|
| `x10 init [dir] [--org ORG]` | Initialize a new workspace |
| `x10 ls` | List projects |
| `x10 open [project]` | Open in preferred editor (auto-detects from CWD) |
| `x10 cursor [project]` | Open in Cursor |
| `x10 code [project]` | Open in VS Code |
| `x10 status [project]` | Git status across repos (all projects if omitted) |
| `x10 sync [project]` | Fetch + fast-forward each repo |
| `x10 prs [project]` | PR state per repo branch |
| `x10 cd <project> [repo]` | Change directory to project or specific repo |
| `x10 add <project> <repo> [opts]` | Add a repo to a project |
| `x10 rm <project> <repo>` | Remove a repo from a project |
| `x10 gc [-y]` | Remove worktrees for merged/closed PRs |
| `x10 gen [project...]` | Regenerate workspace files from manifest |
| `x10 gen --switch [project...]` | Regenerate and re-point worktrees to manifest branches |
| `x10 prune [--remove] [-y]` | Report/remove orphaned worktrees |
| `x10 config [key [value]]` | View or set user configuration |
| `x10 doctor` | Check dependencies and configuration |
| `x10 setup` | Install shell integration into `~/.zshrc` |
| `x10 --version` | Print version |

### `x10 add` options

| Option | Description |
|--------|-------------|
| `--pr N` | Track PR number N (branch resolved via `gh`) |
| `--branch B` | Use explicit branch B |
| `--mode link` | Link to canonical clone (no worktree; use for shared `main`) |
| `--mode worktree` | Default: create an isolated worktree |

## Concepts

### Worktree vs link mode

- **worktree** (default) — creates a git worktree at `worktrees/<project>/<repo>`. Each project gets its own checkout; changes in one project don't affect another.
- **link** — references the canonical clone at `repos/<repo>` directly (no worktree). Use for shared repos you only read on `main`/`master`. Commits there are visible across all projects that link the repo.

### Org-qualified repos

The manifest has a default `org`. Unqualified repo names use it; qualified names (`other-org/their-lib`) use the given org. The local folder is always just the repo name:

```
"my-api"                  ->  github.com/your-org/my-api   ->  repos/my-api
"other-org/their-lib"     ->  github.com/other-org/their-lib ->  repos/their-lib
```

### Generated files

x10 generates three files per project under `projects/<project>/`:

| File | Purpose |
|------|---------|
| `<project>.code-workspace` | VS Code / Cursor multi-root workspace |
| `.envrc` | direnv env vars (`<REPO>_PATH`, `X10_REPO_PATHS`) |
| `justfile` | Optional per-project recipes (`status`, `sync`, `prs`, `fetch`, `cursor`, `code`) |

**Do not hand-edit generated files** — they are overwritten on every `x10 gen` run.

## Configuration

User config lives at `~/.config/x10/config.json`:

```bash
x10 config                        # show all config
x10 config editor cursor          # set preferred editor (cursor, code, zed, ...)
x10 config default_org my-org    # fallback org for new workspaces
x10 config root ~/dev             # workspace root (if not using X10_ROOT)
```

Editor resolution order: `$X10_EDITOR` env var → config `editor` key → auto-detect (`cursor`, then `code`).

## Directory layout

```
<workspace>/
  x10.json                         # manifest — source of truth (edit this or use x10 add/rm)
  repos/<repo>/                    # canonical git clones (one per repo)
  worktrees/<project>/<repo>/      # per-project branch checkouts
  projects/<project>/              # generated project files (do not edit)
    <project>.code-workspace       #   multi-root workspace
    .envrc                         #   direnv env vars
    justfile                       #   task recipes (needs just)
```

## Manifest format

```jsonc
{
  "org": "my-github-org",        // default org for unqualified repo names
  "projects": {
    "my-project": {
      "repos": [
        { "repo": "my-api",         "pr": 42 },
        { "repo": "my-frontend",    "branch": "feature/new-ui" },
        { "repo": "shared-lib",     "branch": "main", "mode": "link" },
        { "repo": "other-org/tool", "branch": "main" }
      ]
    }
  }
}
```

Repo entry fields:

| Field | Required | Description |
|-------|----------|-------------|
| `repo` | yes | Repo name, optionally org-qualified. Unqualified uses manifest `org`. |
| `pr` | no | PR number; branch resolved via `gh pr view`. Mutually exclusive with `branch`. |
| `branch` | no | Explicit branch name. Mutually exclusive with `pr`. |
| `mode` | no | `worktree` (default) or `link`. |

## License

MIT — see [LICENSE](LICENSE).
