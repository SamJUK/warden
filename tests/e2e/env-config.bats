#!/usr/bin/env bats
# E2E tests using "warden env config" (docker compose config) to validate the
# merged compose manifest for each project type without starting containers.
# Requires a running Docker daemon.

load '../helpers/common'

setup() {
    needs_docker
    setup_tmpdir
    # Isolate warden home config without overriding HOME, so Docker's
    # ~/.docker/cli-plugins are still accessible for compose.
    export WARDEN_HOME_DIR="${TEST_TMPDIR}/warden-home"
    mkdir -p "${WARDEN_HOME_DIR}"
    cd "${TEST_TMPDIR}"
}

teardown() {
    teardown_tmpdir
}

# ---------------------------------------------------------------------------
# magento2 — default services
# ---------------------------------------------------------------------------

@test "env-config magento2: php-fpm service is present" {
    write_project_env "e2etest" "magento2"
    run "${WARDEN_BIN}" env config
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"php-fpm:"* ]]
}

@test "env-config magento2: db service is present when WARDEN_DB=1" {
    write_project_env "e2etest" "magento2" "WARDEN_DB=1"
    run "${WARDEN_BIN}" env config
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"  db:"* ]]
    [[ "${output}" == *"mariadb"* ]] || [[ "${output}" == *"mysql"* ]] || [[ "${output}" == *"percona"* ]]
}

@test "env-config magento2: db service is absent when WARDEN_DB=0" {
    write_project_env "e2etest" "magento2" "WARDEN_DB=0"
    run "${WARDEN_BIN}" env config
    [ "${status}" -eq 0 ]
    # No db service block in the services section
    [[ "${output}" != *"  db:"* ]]
}

@test "env-config magento2: network name is derived from env name" {
    write_project_env "myproject" "magento2"
    run "${WARDEN_BIN}" env config
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"myproject_default"* ]]
}

@test "env-config magento2: redis service present when WARDEN_REDIS=1" {
    write_project_env "e2etest" "magento2" "WARDEN_REDIS=1"
    run "${WARDEN_BIN}" env config
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"  redis:"* ]]
}

@test "env-config magento2: redis service absent when WARDEN_REDIS=0" {
    write_project_env "e2etest" "magento2" "WARDEN_REDIS=0"
    run "${WARDEN_BIN}" env config
    [ "${status}" -eq 0 ]
    [[ "${output}" != *"  redis:"* ]]
}

@test "env-config magento2: php-fpm image contains magento2 variant" {
    write_project_env "e2etest" "magento2"
    run "${WARDEN_BIN}" env config
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"php-fpm"*"magento2"* ]] || [[ "${output}" == *"magento2"*"php-fpm"* ]]
}

# ---------------------------------------------------------------------------
# laravel — different service set from magento2
# ---------------------------------------------------------------------------

@test "env-config laravel: php-fpm service is present" {
    write_project_env "laraveltest" "laravel"
    run "${WARDEN_BIN}" env config
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"php-fpm:"* ]]
}

@test "env-config laravel: php-fpm image does not use magento2 variant" {
    write_project_env "laraveltest" "laravel"
    run "${WARDEN_BIN}" env config
    [ "${status}" -eq 0 ]
    # Image name should not contain magento2
    [[ "${output}" != *"php-fpm:*-magento2"* ]]
}

# ---------------------------------------------------------------------------
# local — minimal environment (no standard services by default)
# ---------------------------------------------------------------------------

@test "env-config local: php-fpm service is absent by default" {
    write_project_env "localtest" "local"
    run "${WARDEN_BIN}" env config
    [ "${status}" -eq 0 ]
    [[ "${output}" != *"php-fpm:"* ]]
}

@test "env-config local: db service is absent by default" {
    write_project_env "localtest" "local"
    run "${WARDEN_BIN}" env config
    [ "${status}" -eq 0 ]
    [[ "${output}" != *"  db:"* ]]
}

@test "env-config local: nginx service is absent by default" {
    write_project_env "localtest" "local"
    run "${WARDEN_BIN}" env config
    [ "${status}" -eq 0 ]
    [[ "${output}" != *"  nginx:"* ]]
}

# ---------------------------------------------------------------------------
# warden-env.yml project override
# ---------------------------------------------------------------------------

@test "env-config override: custom env var from warden-env.yml appears in config" {
    write_project_env "overridetest" "laravel"
    mkdir -p "${TEST_TMPDIR}/.warden"
    cat > "${TEST_TMPDIR}/.warden/warden-env.yml" <<'EOF'
services:
  php-fpm:
    environment:
      - E2E_BATS_CUSTOM=bats-override-value
EOF
    run "${WARDEN_BIN}" env config
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"E2E_BATS_CUSTOM"* ]]
    [[ "${output}" == *"bats-override-value"* ]]
}
