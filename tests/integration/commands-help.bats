#!/usr/bin/env bats
# Tests that every command exposes a --help flag that prints usage text.
# The --help path in bin/warden sources the command's .help file without
# executing the command body, so no Docker or project .env is needed.

load '../helpers/common'

setup() {
    setup_tmpdir
    export HOME="${TEST_TMPDIR}/home"
    export WARDEN_HOME_DIR="${HOME}/.warden"
    mkdir -p "${WARDEN_HOME_DIR}"
    cd "${TEST_TMPDIR}"
    mock_docker
}

teardown() {
    teardown_tmpdir
}

# Helper: assert a command's --help output is non-empty and exits non-zero.
assert_help() {
    local cmd="$1"
    run "${WARDEN_BIN}" "${cmd}" --help
    [ "${status}" -ne 0 ]
    [ -n "${output}" ]
}

# ---------------------------------------------------------------------------
# Commands that have dedicated .help files (no docker/project needed)
# ---------------------------------------------------------------------------

@test "db --help: exits non-zero and shows usage" {
    assert_help db
    [[ "${output}" == *"db"* ]]
}

@test "debug --help: exits non-zero and shows usage" {
    assert_help debug
    [[ "${output}" == *"debug"* ]]
}

@test "doctor --help: exits non-zero and shows usage" {
    assert_help doctor
    [[ "${output}" == *"doctor"* ]]
}

@test "env-init --help: exits non-zero and shows usage" {
    assert_help env-init
    [[ "${output}" == *"env-init"* ]]
}

@test "redis --help: exits non-zero and shows usage" {
    assert_help redis
    [[ "${output}" == *"redis"* ]]
}

@test "shell --help: exits non-zero and shows usage" {
    assert_help shell
    [[ "${output}" == *"shell"* ]]
}

@test "sign-certificate --help: exits non-zero and shows usage" {
    assert_help sign-certificate
    [[ "${output}" == *"sign-certificate"* ]]
}

@test "spx --help: exits non-zero and shows usage" {
    assert_help spx
    [[ "${output}" == *"spx"* ]]
}

@test "status --help: exits non-zero and shows usage" {
    assert_help status
    [[ "${output}" == *"status"* ]] || [ -n "${output}" ]
}

@test "valkey --help: exits non-zero and shows usage" {
    assert_help valkey
    [[ "${output}" == *"valkey"* ]]
}

@test "blackfire --help: exits non-zero and shows usage" {
    assert_help blackfire
    [[ "${output}" == *"blackfire"* ]]
}

@test "sync --help: exits non-zero and shows usage" {
    assert_help sync
    [[ "${output}" == *"sync"* ]]
}

@test "vnc --help: exits non-zero and shows usage" {
    assert_help vnc
    [[ "${output}" == *"vnc"* ]]
}

# ---------------------------------------------------------------------------
# version: no dedicated .help, falls back to global usage
# ---------------------------------------------------------------------------

@test "version --help: exits non-zero and shows warden usage" {
    run "${WARDEN_BIN}" version --help
    [ "${status}" -ne 0 ]
    [[ "${output}" == *"Usage"* ]] || [[ "${output}" == *"warden"* ]]
}
