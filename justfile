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

# Run the application inside the running dev container
run: (exec "iex -S mix phx.server")

# Run an arbitrary command inside the running dev container, e.g. `just exec mix test`
exec +args:
    #!/usr/bin/env bash
    set -euo pipefail
    cid=$({{ just_executable() }} cid)
    # Only ask for a TTY when we actually have one, so piped/CI invocations work.
    tty=()
    [ -t 0 ] && [ -t 1 ] && tty=(-it)
    exec docker exec "${tty[@]}" -u vscode -w {{ workdir }} "$cid" {{ args }}

# Stop and remove the dev container and its database
down:
    #!/usr/bin/env bash
    set -euo pipefail
    # Named volumes (deps, _build, and the Claude config) are preserved, so the
    # next start stays fast and the container's Claude login survives.
    # Compose can operate on a project by name alone, discovering resources by
    # label. That matters here: editors generate override files in temp dirs,
    # so the original compose file list isn't reliably reconstructable.
    project=$(docker inspect "$({{ just_executable() }} cid)" \
        --format '{{{{index .Config.Labels "com.docker.compose.project"}}')
    docker compose --project-name "$project" down

# Print the id of the running dev container, or explain that there isn't one.
[private]
cid:
    #!/usr/bin/env bash
    set -euo pipefail
    cid=$(docker ps -q --filter "label=devcontainer.config_file={{ config }}")
    if [ -z "$cid" ]; then
        echo "No running dev container for {{ justfile_directory() }}." >&2
        echo "Start it in your editor, or run: devcontainer up --workspace-folder ." >&2
        exit 1
    fi
    echo "$cid"
