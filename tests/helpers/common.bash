#!/usr/bin/env bash
# Shared helpers for warden BATS test suite

# Root of the warden project
export WARDEN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Path to the warden binary
export WARDEN_BIN="${WARDEN_DIR}/bin/warden"

# Creates a temporary directory for the duration of a test and sets TEST_TMPDIR.
# Call from BATS setup() functions.
setup_tmpdir() {
    TEST_TMPDIR="$(mktemp -d)"
    export TEST_TMPDIR
    export ORIGINAL_PATH="${PATH}"
}

# Skips the test if Docker is not available or the daemon is not running.
# Call at the start of setup() in E2E test files.
needs_docker() {
    if ! docker info &>/dev/null 2>&1; then
        skip "Docker daemon is not available"
    fi
}

# Removes the temporary directory created by setup_tmpdir.
# Call from BATS teardown() functions.
teardown_tmpdir() {
    [[ -n "${TEST_TMPDIR}" && -d "${TEST_TMPDIR}" ]] && rm -rf "${TEST_TMPDIR}"
    # Restore PATH to avoid shim bleed between tests
    [[ -n "${ORIGINAL_PATH}" ]] && export PATH="${ORIGINAL_PATH}"
}

# Write a minimal project .env into TEST_TMPDIR.
# Usage: write_project_env <name> <type> [KEY=value ...]
# Extra KEY=value pairs (simple scalar values only) are appended one per line.
# NOTE: Warden's loadEnvConfig evals the .env file, which means values written
# here take precedence over any runtime env var overrides. Always set service
# flags (WARDEN_DB, WARDEN_REDIS, etc.) here rather than as env var overrides.
write_project_env() {
    local name="$1" type="$2"
    shift 2
    {
        printf 'WARDEN_ENV_NAME=%s\n' "${name}"
        printf 'WARDEN_ENV_TYPE=%s\n' "${type}"
        printf 'WARDEN_WEB_ROOT=/\n'
        printf 'TRAEFIK_DOMAIN=%s.test\n' "${name}"
        printf 'TRAEFIK_SUBDOMAIN=app\n'
        printf '%s\n' "$@"
    } > "${TEST_TMPDIR}/.env"
}

# Modify or append a KEY=VALUE entry in a .env file.
# Usage: set_env_value <key> <value> [file]
# Intended for simple scalar values (0/1, names, versions).
# For safety, values containing shell metacharacters are not supported.
set_env_value() {
    local key="$1" val="$2" file="${3:-${TEST_TMPDIR}/.env}"
    if grep -q "^${key}=" "${file}"; then
        sed -i.bak "s|^${key}=.*|${key}=${val}|" "${file}" && rm -f "${file}.bak"
    else
        printf '%s=%s\n' "${key}" "${val}" >> "${file}"
    fi
}

# Prepends a fake "docker" shim to PATH so commands that call docker don't
# require a real Docker daemon.  The shim silently succeeds by default.
mock_docker() {
    local shim_dir="${TEST_TMPDIR}/mock_bin"
    mkdir -p "${shim_dir}"
    cat > "${shim_dir}/docker" <<'EOF'
#!/usr/bin/env bash
# Minimal docker shim for BATS tests.
case "$1" in
    system)   exit 0 ;;       # docker system info
    network)  echo "" ;;      # docker network ls
    compose)
        # docker compose version
        if [[ "$2" == "version" ]]; then
            echo "Docker Compose version v2.5.0"
        fi
        exit 0
        ;;
    *)
        echo "docker mock: unexpected call: $*" >&2
        exit 1
        ;;
esac
EOF
    chmod +x "${shim_dir}/docker"
    export PATH="${shim_dir}:${PATH}"
}
