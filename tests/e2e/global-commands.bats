#!/usr/bin/env bats
# E2E tests for global warden commands that interact directly with Docker.
# Requires a running Docker daemon.

load '../helpers/common'

setup() {
    needs_docker
    setup_tmpdir
    export WARDEN_HOME_DIR="${TEST_TMPDIR}/warden-home"
    mkdir -p "${WARDEN_HOME_DIR}"
    cd "${TEST_TMPDIR}"
}

teardown() {
    teardown_tmpdir
}

# ---------------------------------------------------------------------------
# warden status
# ---------------------------------------------------------------------------

@test "status: exits with code 0 and produces output" {
    run "${WARDEN_BIN}" status
    [ "${status}" -eq 0 ]
    [ -n "${output}" ]
}

@test "status: output mentions running environments or reports none found" {
    run "${WARDEN_BIN}" status
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"running"* ]] \
        || [[ "${output}" == *"No running"* ]] \
        || [[ "${output}" == *"not currently"* ]]
}

# ---------------------------------------------------------------------------
# warden doctor
# ---------------------------------------------------------------------------

@test "doctor: exits with code 0" {
    run "${WARDEN_BIN}" doctor
    [ "${status}" -eq 0 ]
}

@test "doctor: output contains OS/architecture info" {
    run "${WARDEN_BIN}" doctor
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"OS"* ]] || [[ "${output}" == *"uname"* ]] || [[ "${output}" == *"Darwin"* ]] || [[ "${output}" == *"Linux"* ]]
}

@test "doctor: output contains docker version info" {
    run "${WARDEN_BIN}" doctor
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Docker"* ]]
}

@test "doctor: output contains warden version info" {
    expected_version="$(cat "${WARDEN_DIR}/version")"
    run "${WARDEN_BIN}" doctor
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"${expected_version}"* ]]
}
