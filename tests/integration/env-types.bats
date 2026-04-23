#!/usr/bin/env bats
# Tests for environment type handling:
# - loadEnvConfig correctly reads .env vars
# - appendEnvPartialIfExists selects the right compose files per env type
# - Feature-flag env vars suppress/enable specific service partials

load '../helpers/common'

setup() {
    setup_tmpdir
    export WARDEN_HOME_DIR="${TEST_TMPDIR}/home/.warden"
    mkdir -p "${WARDEN_HOME_DIR}"
    export WARDEN_DIR
    source "${WARDEN_DIR}/utils/core.sh"
    source "${WARDEN_DIR}/utils/env.sh"
}

teardown() {
    teardown_tmpdir
}

# ---------------------------------------------------------------------------
# loadEnvConfig: reads values from .env
# ---------------------------------------------------------------------------

@test "loadEnvConfig: sets WARDEN_ENV_NAME from .env" {
    write_project_env "myproject" "magento2"
    loadEnvConfig "${TEST_TMPDIR}"
    [ "${WARDEN_ENV_NAME}" = "myproject" ]
}

@test "loadEnvConfig: sets WARDEN_ENV_TYPE from .env" {
    write_project_env "myproject" "magento2"
    loadEnvConfig "${TEST_TMPDIR}"
    [ "${WARDEN_ENV_TYPE}" = "magento2" ]
}

@test "loadEnvConfig: sets WARDEN_ENV_NAME for laravel fixture" {
    write_project_env "laravelapp" "laravel"
    loadEnvConfig "${TEST_TMPDIR}"
    [ "${WARDEN_ENV_NAME}" = "laravelapp" ]
    [ "${WARDEN_ENV_TYPE}" = "laravel" ]
}

@test "loadEnvConfig: sets WARDEN_ENV_NAME for magento1 fixture" {
    write_project_env "m1store" "magento1"
    loadEnvConfig "${TEST_TMPDIR}"
    [ "${WARDEN_ENV_NAME}" = "m1store" ]
    [ "${WARDEN_ENV_TYPE}" = "magento1" ]
}

@test "loadEnvConfig: sets WARDEN_ENV_NAME for wordpress fixture" {
    write_project_env "wpsite" "wordpress"
    loadEnvConfig "${TEST_TMPDIR}"
    [ "${WARDEN_ENV_NAME}" = "wpsite" ]
    [ "${WARDEN_ENV_TYPE}" = "wordpress" ]
}

@test "loadEnvConfig: sets WARDEN_ENV_SUBT based on host OS" {
    write_project_env "localproject" "local"
    loadEnvConfig "${TEST_TMPDIR}"
    [[ "${WARDEN_ENV_SUBT}" == "darwin" || "${WARDEN_ENV_SUBT}" == "linux" ]]
}

@test "loadEnvConfig: fails for unknown env type" {
    cat > "${TEST_TMPDIR}/.env" <<EOF
WARDEN_ENV_NAME=test
WARDEN_ENV_TYPE=not-a-real-type
EOF
    run loadEnvConfig "${TEST_TMPDIR}"
    [ "${status}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# appendEnvPartialIfExists: correct files per env type (linux, no mutagen)
# ---------------------------------------------------------------------------

@test "appendEnvPartialIfExists: magento2 base file is included" {
    WARDEN_ENV_TYPE="magento2"
    WARDEN_ENV_SUBT="linux"
    WARDEN_MUTAGEN_ENABLE=0
    WARDEN_ENV_PATH="${TEST_TMPDIR}/project"
    DOCKER_COMPOSE_ARGS=()
    appendEnvPartialIfExists "magento2"
    # At minimum the base.yml should have been added
    [[ "${DOCKER_COMPOSE_ARGS[*]}" == *"magento2.base.yml"* ]]
}

@test "appendEnvPartialIfExists: local base file is included" {
    WARDEN_ENV_TYPE="local"
    WARDEN_ENV_SUBT="linux"
    WARDEN_MUTAGEN_ENABLE=0
    WARDEN_ENV_PATH="${TEST_TMPDIR}/project"
    DOCKER_COMPOSE_ARGS=()
    appendEnvPartialIfExists "local"
    [[ "${DOCKER_COMPOSE_ARGS[*]}" == *"local.base.yml"* ]]
}

@test "appendEnvPartialIfExists: laravel base file is included" {
    WARDEN_ENV_TYPE="laravel"
    WARDEN_ENV_SUBT="linux"
    WARDEN_MUTAGEN_ENABLE=0
    WARDEN_ENV_PATH="${TEST_TMPDIR}/project"
    DOCKER_COMPOSE_ARGS=()
    appendEnvPartialIfExists "laravel"
    [[ "${DOCKER_COMPOSE_ARGS[*]}" == *"laravel.base.yml"* ]]
}

@test "appendEnvPartialIfExists: magento1 base file is included" {
    WARDEN_ENV_TYPE="magento1"
    WARDEN_ENV_SUBT="linux"
    WARDEN_MUTAGEN_ENABLE=0
    WARDEN_ENV_PATH="${TEST_TMPDIR}/project"
    DOCKER_COMPOSE_ARGS=()
    appendEnvPartialIfExists "magento1"
    [[ "${DOCKER_COMPOSE_ARGS[*]}" == *"magento1.base.yml"* ]]
}

@test "appendEnvPartialIfExists: wordpress base file is included" {
    WARDEN_ENV_TYPE="wordpress"
    WARDEN_ENV_SUBT="linux"
    WARDEN_MUTAGEN_ENABLE=0
    WARDEN_ENV_PATH="${TEST_TMPDIR}/project"
    DOCKER_COMPOSE_ARGS=()
    appendEnvPartialIfExists "wordpress"
    [[ "${DOCKER_COMPOSE_ARGS[*]}" == *"wordpress.base.yml"* ]]
}

@test "appendEnvPartialIfExists: php-fpm base file is included for magento2" {
    WARDEN_ENV_TYPE="magento2"
    WARDEN_ENV_SUBT="linux"
    WARDEN_MUTAGEN_ENABLE=0
    WARDEN_ENV_PATH="${TEST_TMPDIR}/project"
    DOCKER_COMPOSE_ARGS=()
    appendEnvPartialIfExists "php-fpm"
    [[ "${DOCKER_COMPOSE_ARGS[*]}" == *"php-fpm"* ]]
}

@test "appendEnvPartialIfExists: nginx base file is included" {
    WARDEN_ENV_TYPE="magento2"
    WARDEN_ENV_SUBT="linux"
    WARDEN_MUTAGEN_ENABLE=0
    WARDEN_ENV_PATH="${TEST_TMPDIR}/project"
    DOCKER_COMPOSE_ARGS=()
    appendEnvPartialIfExists "nginx"
    [[ "${DOCKER_COMPOSE_ARGS[*]}" == *"nginx"* ]]
}

# ---------------------------------------------------------------------------
# appendEnvPartialIfExists: feature-flag suppression
# ---------------------------------------------------------------------------

@test "feature-flag: WARDEN_DB=0 means db partial is not added" {
    WARDEN_ENV_TYPE="magento2"
    WARDEN_ENV_SUBT="linux"
    WARDEN_MUTAGEN_ENABLE=0
    WARDEN_ENV_PATH="${TEST_TMPDIR}/project"
    DOCKER_COMPOSE_ARGS=()
    # Simulate the env.cmd conditional: only add db if WARDEN_DB=1
    [[ ${WARDEN_DB:-1} -eq 1 ]] && appendEnvPartialIfExists "db"
    # When WARDEN_DB is unset defaults to 1 so db WILL be there; test explicit 0
    DOCKER_COMPOSE_ARGS=()
    WARDEN_DB=0
    [[ ${WARDEN_DB} -eq 1 ]] && appendEnvPartialIfExists "db"
    [[ "${DOCKER_COMPOSE_ARGS[*]}" != *"db.base.yml"* ]]
}

@test "feature-flag: WARDEN_DB=1 means db partial is added" {
    WARDEN_ENV_TYPE="magento2"
    WARDEN_ENV_SUBT="linux"
    WARDEN_MUTAGEN_ENABLE=0
    WARDEN_ENV_PATH="${TEST_TMPDIR}/project"
    WARDEN_DB=1
    DOCKER_COMPOSE_ARGS=()
    [[ ${WARDEN_DB} -eq 1 ]] && appendEnvPartialIfExists "db"
    [[ "${DOCKER_COMPOSE_ARGS[*]}" == *"db.base.yml"* ]]
}

@test "feature-flag: WARDEN_REDIS=0 means redis partial is not added" {
    WARDEN_ENV_TYPE="magento2"
    WARDEN_ENV_SUBT="linux"
    WARDEN_MUTAGEN_ENABLE=0
    WARDEN_ENV_PATH="${TEST_TMPDIR}/project"
    WARDEN_REDIS=0
    DOCKER_COMPOSE_ARGS=()
    [[ ${WARDEN_REDIS} -eq 1 ]] && appendEnvPartialIfExists "redis"
    [[ "${DOCKER_COMPOSE_ARGS[*]}" != *"redis"* ]]
}

@test "feature-flag: WARDEN_ELASTICSEARCH=0 means elasticsearch partial is not added" {
    WARDEN_ENV_TYPE="magento2"
    WARDEN_ENV_SUBT="linux"
    WARDEN_MUTAGEN_ENABLE=0
    WARDEN_ENV_PATH="${TEST_TMPDIR}/project"
    WARDEN_ELASTICSEARCH=0
    DOCKER_COMPOSE_ARGS=()
    [[ ${WARDEN_ELASTICSEARCH} -eq 1 ]] && appendEnvPartialIfExists "elasticsearch"
    [[ "${DOCKER_COMPOSE_ARGS[*]}" != *"elasticsearch"* ]]
}

# ---------------------------------------------------------------------------
# fetchValidEnvTypes: all built-in types are present
# ---------------------------------------------------------------------------

@test "fetchValidEnvTypes: includes all built-in types" {
    WARDEN_ENV_PATH=""
    result="$(fetchValidEnvTypes)"
    for envtype in magento2 magento1 laravel local wordpress drupal symfony shopware cakephp; do
        [[ "${result}" == *"${envtype}"* ]]
    done
}
