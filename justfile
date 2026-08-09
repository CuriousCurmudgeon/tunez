# Dev container recipes. The container itself is started by your editor (Zed's
# dev container support, VS Code, or `devcontainer up`); these recipes only
# attach to the one that is already running.

# The devcontainer CLI stamps this label onto the container, so we can find it
# without depending on the compose-generated container name.
config := justfile_directory() / ".devcontainer/devcontainer.json"

# Must match "workspaceFolder" in devcontainer.json.
workdir := "/workspaces/tunez"

# List available recipes
default:
    @just --list

# Open Claude Code inside the running dev container
claude: (exec "claude")

# Open a login shell inside the running dev container
shell: (exec "bash" "-l")

# Run an arbitrary command inside the running dev container, e.g. `just exec mix test`
exec +args:
    #!/usr/bin/env bash
    set -euo pipefail
    cid=$(docker ps -q --filter "label=devcontainer.config_file={{ config }}")
    if [ -z "$cid" ]; then
        echo "No running dev container for {{ justfile_directory() }}." >&2
        echo "Start it in your editor, or run: devcontainer up --workspace-folder ." >&2
        exit 1
    fi
    # Only ask for a TTY when we actually have one, so piped/CI invocations work.
    tty=()
    [ -t 0 ] && [ -t 1 ] && tty=(-it)
    exec docker exec "${tty[@]}" -u vscode -w {{ workdir }} "$cid" {{ args }}
