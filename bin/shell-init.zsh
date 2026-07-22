# x10 workspace — shell integration
# Sourced from ~/.zshrc via `x10 setup`.

# direnv hook (if installed)
if command -v direnv &>/dev/null; then
  eval "$(direnv hook zsh)"
fi

# Wrapper function so `x10 cd` can change the shell's working directory.
x10() {
  if [[ "${1:-}" == "cd" ]]; then
    shift
    local target
    target="$(command x10 _path "$@")" || return 1
    builtin cd "$target"
  else
    command x10 "$@"
  fi
}

# Zsh tab-completion
_x10_completions() {
  local -a commands=(
    'init:initialize a new workspace'
    'ls:list projects'
    'cursor:open in Cursor'
    'code:open in VS Code'
    'open:open in preferred editor'
    'status:git status across repos'
    'sync:fetch + fast-forward repos'
    'prs:PR state per repo'
    'add:add a repo to a project'
    'rm:remove a repo from a project'
    'cd:change directory to project/repo'
    'gc:remove merged/closed PR worktrees'
    'gen:regenerate workspace files'
    'prune:report/remove orphaned worktrees'
    'config:view or set user configuration'
    'doctor:check dependencies and config'
    'setup:install shell integration'
    'help:show usage'
  )

  if (( CURRENT == 2 )); then
    _describe 'command' commands
    return
  fi

  case "${words[2]}" in
    cursor|code|open|status|sync|prs|cd|rm)
      if (( CURRENT == 3 )); then
        local -a projects
        projects=($(command x10 ls 2>/dev/null))
        (( ${#projects[@]} )) && _describe 'project' projects
      fi
      if (( CURRENT == 4 )) && [[ "${words[2]}" =~ ^(cd|rm)$ ]]; then
        local proj="${words[3]}"
        local root="${X10_ROOT:-$HOME/x10}"
        local manifest="$root/x10.json"
        local -a repos
        repos=($(jq -r --arg p "$proj" \
          '.projects[$p].repos[]?.repo // empty' "$manifest" 2>/dev/null \
          | sed 's|.*/||'))
        (( ${#repos[@]} )) && _describe 'repo' repos
      fi
      ;;
    add)
      if (( CURRENT == 3 )); then
        local -a projects
        projects=($(command x10 ls 2>/dev/null))
        (( ${#projects[@]} )) && _describe 'project' projects
      fi
      ;;
    config)
      if (( CURRENT == 3 )); then
        local -a keys=('editor' 'default_org' 'root')
        _describe 'config key' keys
      fi
      ;;
  esac
}
compdef _x10_completions x10
