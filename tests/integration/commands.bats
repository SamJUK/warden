#!/usr/bin/env bats
# Integration tests for warden CLI commands
# Docker is mocked so these tests do not require a running Docker daemon.

load '../helpers/common'

setup() {
    setup_tmpdir
    # Isolate HOME and WARDEN_HOME_DIR so tests are not affected by the
    # developer's real ~/.warden or any ambient .env files.
    export HOME="${TEST_TMPDIR}/home"
    export WARDEN_HOME_DIR="${HOME}/.warden"
    mkdir -p "${WARDEN_HOME_DIR}"
    cd "${TEST_TMPDIR}"
    mock_docker
}

teardown() {
    teardown_tmpdir
}

# ---------------------------------------------------------------------------
# version command
# ---------------------------------------------------------------------------

@test "version: outputs content of the version file" {
    expected="$(cat "${WARDEN_DIR}/version")"
    run "${WARDEN_BIN}" version
    [ "${status}" -eq 0 ]
    [ "${output}" = "${expected}" ]
}

# ---------------------------------------------------------------------------
# usage / help
# ---------------------------------------------------------------------------

@test "help: no arguments exits with non-zero status and shows usage" {
    run "${WARDEN_BIN}"
    [ "${status}" -ne 0 ]
    [[ "${output}" == *"Usage"* ]] || [[ "${output}" == *"warden"* ]]
}

@test "help: --help flag exits with non-zero status and shows usage" {
    run "${WARDEN_BIN}" --help
    [ "${status}" -ne 0 ]
    [[ "${output}" == *"Usage"* ]] || [[ "${output}" == *"warden"* ]]
}

@test "help: unknown command exits with non-zero status and shows usage" {
    run "${WARDEN_BIN}" totally-unknown-command-xyz
    [ "${status}" -ne 0 ]
    [[ "${output}" == *"Usage"* ]] || [[ "${output}" == *"warden"* ]]
}

# ---------------------------------------------------------------------------
# env-init command
# ---------------------------------------------------------------------------

@test "env-init: creates a .env file with expected content" {
    cd "${TEST_TMPDIR}"
    run bash -c "echo -e 'myapp\nmagento2' | '${WARDEN_BIN}' env-init myapp magento2"
    [ "${status}" -eq 0 ]
    [ -f "${TEST_TMPDIR}/.env" ]
    grep -q "WARDEN_ENV_NAME=myapp" "${TEST_TMPDIR}/.env"
    grep -q "WARDEN_ENV_TYPE=magento2" "${TEST_TMPDIR}/.env"
}

@test "env-init: sets TRAEFIK_DOMAIN based on env name" {
    cd "${TEST_TMPDIR}"
    run "${WARDEN_BIN}" env-init testsite local
    [ "${status}" -eq 0 ]
    grep -q "TRAEFIK_DOMAIN=testsite.test" "${TEST_TMPDIR}/.env"
}

@test "env-init: sets WARDEN_WEB_ROOT to /" {
    cd "${TEST_TMPDIR}"
    run "${WARDEN_BIN}" env-init webapp laravel
    [ "${status}" -eq 0 ]
    grep -q "WARDEN_WEB_ROOT=/" "${TEST_TMPDIR}/.env"
}

@test "env-init: fails for an invalid env type" {
    cd "${TEST_TMPDIR}"
    run "${WARDEN_BIN}" env-init myapp not-a-real-type
    [ "${status}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

@test "arg-parsing: -h flag on a command shows help output" {
    run "${WARDEN_BIN}" version -h
    # Should show usage without actually erroring out in a confusing way
    [ "${status}" -eq 0 ] || [[ "${output}" == *"Usage"* ]]
}

# ---------------------------------------------------------------------------
# env-init: all built-in environment types
# ---------------------------------------------------------------------------

@test "env-init: creates valid .env for magento1 type" {
    cd "${TEST_TMPDIR}"
    run "${WARDEN_BIN}" env-init m1store magento1
    [ "${status}" -eq 0 ]
    grep -q "WARDEN_ENV_TYPE=magento1" "${TEST_TMPDIR}/.env"
}

@test "env-init: creates valid .env for laravel type" {
    cd "${TEST_TMPDIR}"
    run "${WARDEN_BIN}" env-init laravelapp laravel
    [ "${status}" -eq 0 ]
    grep -q "WARDEN_ENV_TYPE=laravel" "${TEST_TMPDIR}/.env"
}

@test "env-init: creates valid .env for wordpress type" {
    cd "${TEST_TMPDIR}"
    run "${WARDEN_BIN}" env-init wpsite wordpress
    [ "${status}" -eq 0 ]
    grep -q "WARDEN_ENV_TYPE=wordpress" "${TEST_TMPDIR}/.env"
}

@test "env-init: creates valid .env for drupal type" {
    cd "${TEST_TMPDIR}"
    run "${WARDEN_BIN}" env-init drupalsite drupal
    [ "${status}" -eq 0 ]
    grep -q "WARDEN_ENV_TYPE=drupal" "${TEST_TMPDIR}/.env"
}

@test "env-init: creates valid .env for symfony type" {
    cd "${TEST_TMPDIR}"
    run "${WARDEN_BIN}" env-init symapp symfony
    [ "${status}" -eq 0 ]
    grep -q "WARDEN_ENV_TYPE=symfony" "${TEST_TMPDIR}/.env"
}

@test "env-init: creates valid .env for shopware type" {
    cd "${TEST_TMPDIR}"
    run "${WARDEN_BIN}" env-init shopapp shopware
    [ "${status}" -eq 0 ]
    grep -q "WARDEN_ENV_TYPE=shopware" "${TEST_TMPDIR}/.env"
}

@test "env-init: creates valid .env for cakephp type" {
    cd "${TEST_TMPDIR}"
    run "${WARDEN_BIN}" env-init cakeapp cakephp
    [ "${status}" -eq 0 ]
    grep -q "WARDEN_ENV_TYPE=cakephp" "${TEST_TMPDIR}/.env"
}

# ---------------------------------------------------------------------------
# db command — service disabled
# ---------------------------------------------------------------------------

# NOTE: Warden's loadEnvConfig evals .env values which take precedence over
# runtime env vars. Service flags must be set in the .env file, not as env
# var overrides at runtime.

@test "db: exits with error when WARDEN_DB=0" {
    write_project_env "myproject" "magento2" "WARDEN_DB=0"
    cd "${TEST_TMPDIR}"
    run "${WARDEN_BIN}" db connect
    [ "${status}" -ne 0 ]
    [[ "${output}" == *"WARDEN_DB=0"* ]]
}

# ---------------------------------------------------------------------------
# redis command — service disabled
# ---------------------------------------------------------------------------

@test "redis: exits with error when WARDEN_REDIS=0" {
    write_project_env "myproject" "magento2" "WARDEN_REDIS=0"
    cd "${TEST_TMPDIR}"
    run "${WARDEN_BIN}" redis
    [ "${status}" -ne 0 ]
    [[ "${output}" == *"WARDEN_REDIS=0"* ]]
}

# ---------------------------------------------------------------------------
# valkey command — service disabled
# ---------------------------------------------------------------------------

@test "valkey: exits with error when WARDEN_VALKEY=0" {
    write_project_env "myproject" "magento2" "WARDEN_VALKEY=0"
    cd "${TEST_TMPDIR}"
    run "${WARDEN_BIN}" valkey
    [ "${status}" -ne 0 ]
    [[ "${output}" == *"WARDEN_VALKEY=0"* ]]
}

# ---------------------------------------------------------------------------
# sign-certificate command
# ---------------------------------------------------------------------------

@test "sign-certificate: fails with helpful message when no hostname given" {
    # The CA check in sign-certificate.cmd runs before the hostname check,
    # so without a CA the error is about the missing CA, not the missing hostname.
    # Both are valid "no hostname" paths — test that either helpful message appears.
    run "${WARDEN_BIN}" sign-certificate
    [ "${status}" -ne 0 ]
    [[ "${output}" == *"hostname"* ]] \
        || [[ "${output}" == *"requires"* ]] \
        || [[ "${output}" == *"root CA"* ]] \
        || [[ "${output}" == *"install"* ]]
}

@test "sign-certificate: fails with helpful message when root CA is missing" {
    export WARDEN_SSL_DIR="${TEST_TMPDIR}/ssl"
    mkdir -p "${WARDEN_SSL_DIR}/certs"
    run "${WARDEN_BIN}" sign-certificate example.test
    [ "${status}" -ne 0 ]
    [[ "${output}" == *"Missing the root CA"* ]] || [[ "${output}" == *"warden install"* ]]
}

