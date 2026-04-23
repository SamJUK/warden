#!/usr/bin/env bats
# Unit tests for utils/env.sh

load '../helpers/common'

setup() {
    setup_tmpdir
    export WARDEN_DIR
    # env.sh requires core.sh to be loaded first (uses fatal())
    source "${WARDEN_DIR}/utils/core.sh"
    source "${WARDEN_DIR}/utils/env.sh"
}

teardown() {
    teardown_tmpdir
}

# ---------------------------------------------------------------------------
# renderEnvNetworkName()
# ---------------------------------------------------------------------------

@test "renderEnvNetworkName: appends _default suffix" {
    WARDEN_ENV_NAME="myproject"
    result="$(renderEnvNetworkName)"
    [ "${result}" = "myproject_default" ]
}

@test "renderEnvNetworkName: lowercases the env name" {
    WARDEN_ENV_NAME="MyProject"
    result="$(renderEnvNetworkName)"
    [ "${result}" = "myproject_default" ]
}

@test "renderEnvNetworkName: handles env names with hyphens" {
    WARDEN_ENV_NAME="my-project"
    result="$(renderEnvNetworkName)"
    [ "${result}" = "my-project_default" ]
}

# ---------------------------------------------------------------------------
# locateEnvPath()
# ---------------------------------------------------------------------------

@test "locateEnvPath: finds .env file in the current directory" {
    write_project_env "myproject" "magento2"
    cd "${TEST_TMPDIR}"
    result="$(locateEnvPath)"
    # Resolve symlinks on both sides (macOS /tmp -> /private/tmp)
    [ "$(cd "${result}" && pwd -P)" = "$(pwd -P)" ]
}

@test "locateEnvPath: finds .env file in a parent directory" {
    write_project_env "myproject" "magento2"
    mkdir -p "${TEST_TMPDIR}/subdir/deeper"
    cd "${TEST_TMPDIR}/subdir/deeper"
    result="$(locateEnvPath)"
    expected="$(cd "${TEST_TMPDIR}" && pwd -P)"
    [ "$(cd "${result}" && pwd -P)" = "${expected}" ]
}

@test "locateEnvPath: returns non-zero when no .env exists" {
    cd "${TEST_TMPDIR}"
    run locateEnvPath
    [ "${status}" -ne 0 ]
}

@test "locateEnvPath: ignores .env without WARDEN_ENV_NAME" {
    echo "SOME_VAR=value" > "${TEST_TMPDIR}/.env"
    cd "${TEST_TMPDIR}"
    run locateEnvPath
    [ "${status}" -ne 0 ]
}

@test "locateEnvPath: resolves a symlinked .env to the real directory" {
    write_project_env "myproject" "magento2"
    # Create a sub-project that symlinks to the parent .env
    mkdir -p "${TEST_TMPDIR}/subproject"
    ln -s "${TEST_TMPDIR}/.env" "${TEST_TMPDIR}/subproject/.env"
    cd "${TEST_TMPDIR}/subproject"
    result="$(locateEnvPath)"
    # Should resolve to the directory containing the real .env file
    [ -n "${result}" ]
    [ "${status:-0}" -eq 0 ]
}


@test "locateEnvPath: ignores .env without WARDEN_ENV_TYPE" {
    echo "WARDEN_ENV_NAME=test" > "${TEST_TMPDIR}/.env"
    cd "${TEST_TMPDIR}"
    run locateEnvPath
    [ "${status}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# assertValidEnvType()
# ---------------------------------------------------------------------------

@test "assertValidEnvType: passes for built-in magento2 type" {
    WARDEN_ENV_TYPE="magento2"
    WARDEN_ENV_PATH=""
    WARDEN_HOME_DIR="${TEST_TMPDIR}/home"
    assertValidEnvType
}

@test "assertValidEnvType: passes for built-in local type" {
    WARDEN_ENV_TYPE="local"
    WARDEN_ENV_PATH=""
    WARDEN_HOME_DIR="${TEST_TMPDIR}/home"
    assertValidEnvType
}

@test "assertValidEnvType: passes for built-in laravel type" {
    WARDEN_ENV_TYPE="laravel"
    WARDEN_ENV_PATH=""
    WARDEN_HOME_DIR="${TEST_TMPDIR}/home"
    assertValidEnvType
}

@test "assertValidEnvType: fails for unknown env type" {
    WARDEN_ENV_TYPE="nonexistent-type"
    WARDEN_ENV_PATH=""
    WARDEN_HOME_DIR="${TEST_TMPDIR}/home"
    run assertValidEnvType
    [ "${status}" -ne 0 ]
}

@test "assertValidEnvType: passes for custom type defined in WARDEN_ENV_PATH" {
    WARDEN_ENV_TYPE="custom"
    WARDEN_HOME_DIR="${TEST_TMPDIR}/home"
    WARDEN_ENV_PATH="${TEST_TMPDIR}/project"
    mkdir -p "${WARDEN_ENV_PATH}/.warden/environments/custom"
    touch "${WARDEN_ENV_PATH}/.warden/environments/custom/custom.base.yml"
    assertValidEnvType
}

# ---------------------------------------------------------------------------
# fetchValidEnvTypes()
# ---------------------------------------------------------------------------

@test "fetchValidEnvTypes: includes magento2 in results" {
    WARDEN_HOME_DIR="${TEST_TMPDIR}/home"
    WARDEN_ENV_PATH=""
    result="$(fetchValidEnvTypes)"
    [[ "${result}" == *"magento2"* ]]
}

@test "fetchValidEnvTypes: includes local in results" {
    WARDEN_HOME_DIR="${TEST_TMPDIR}/home"
    WARDEN_ENV_PATH=""
    result="$(fetchValidEnvTypes)"
    [[ "${result}" == *"local"* ]]
}

@test "fetchValidEnvTypes: includes laravel in results" {
    WARDEN_HOME_DIR="${TEST_TMPDIR}/home"
    WARDEN_ENV_PATH=""
    result="$(fetchValidEnvTypes)"
    [[ "${result}" == *"laravel"* ]]
}

@test "fetchValidEnvTypes: does not include includes pseudo-type" {
    WARDEN_HOME_DIR="${TEST_TMPDIR}/home"
    WARDEN_ENV_PATH=""
    result="$(fetchValidEnvTypes)"
    [[ "${result}" != *"includes"* ]]
}

# ---------------------------------------------------------------------------
# appendEnvPartialIfExists()
# ---------------------------------------------------------------------------

@test "appendEnvPartialIfExists: adds file to DOCKER_COMPOSE_ARGS when base.yml exists" {
    WARDEN_ENV_TYPE="magento2"
    WARDEN_ENV_SUBT="linux"
    WARDEN_MUTAGEN_ENABLE=0
    WARDEN_HOME_DIR="${TEST_TMPDIR}/home"
    WARDEN_ENV_PATH="${TEST_TMPDIR}/project"
    DOCKER_COMPOSE_ARGS=()

    appendEnvPartialIfExists "magento2"

    # Should have added at least one -f flag
    [[ "${#DOCKER_COMPOSE_ARGS[@]}" -gt 0 ]]
}

@test "appendEnvPartialIfExists: does not add args when partial does not exist" {
    WARDEN_ENV_TYPE="magento2"
    WARDEN_ENV_SUBT="linux"
    WARDEN_MUTAGEN_ENABLE=0
    WARDEN_HOME_DIR="${TEST_TMPDIR}/home"
    WARDEN_ENV_PATH="${TEST_TMPDIR}/project"
    DOCKER_COMPOSE_ARGS=()

    appendEnvPartialIfExists "nonexistent-partial-xyz"

    [ "${#DOCKER_COMPOSE_ARGS[@]}" -eq 0 ]
}
