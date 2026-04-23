#!/usr/bin/env bats
# Unit tests for utils/core.sh

load '../helpers/common'

# Source core.sh under test; set WARDEN_DIR so the guard check passes.
setup() {
    export WARDEN_DIR
    source "${WARDEN_DIR}/utils/core.sh"
}

# ---------------------------------------------------------------------------
# version()
# ---------------------------------------------------------------------------

@test "version: single digit returns padded number" {
    result="$(version 1)"
    [ "${result}" = "1000000000" ]
}

@test "version: two-part version string" {
    result="$(version 2.2)"
    [ "${result}" = "2002000000" ]
}

@test "version: three-part version string" {
    result="$(version 2.2.3)"
    [ "${result}" = "2002003000" ]
}

@test "version: four-part version string" {
    result="$(version 1.2.3.4)"
    [ "${result}" = "1002003004" ]
}

@test "version: newer version compares greater than older" {
    newer="$(version 2.3.0)"
    older="$(version 2.2.3)"
    [ "${newer}" -gt "${older}" ]
}

@test "version: equal versions compare equal" {
    a="$(version 2.2.3)"
    b="$(version 2.2.3)"
    [ "${a}" -eq "${b}" ]
}

# ---------------------------------------------------------------------------
# containsElement()
# ---------------------------------------------------------------------------

@test "containsElement: finds element in single-item array" {
    arr=("alpha")
    containsElement "alpha" "${arr[@]}"
}

@test "containsElement: finds element in multi-item array" {
    arr=("alpha" "beta" "gamma")
    containsElement "beta" "${arr[@]}"
}

@test "containsElement: returns 1 when element is absent" {
    arr=("alpha" "beta")
    ! containsElement "delta" "${arr[@]}"
}

@test "containsElement: empty array returns 1" {
    arr=()
    ! containsElement "anything" "${arr[@]}"
}

@test "containsElement: exact match only (no substring match)" {
    arr=("foobar")
    ! containsElement "foo" "${arr[@]}"
}

@test "containsElement: element with spaces is found" {
    arr=("hello world" "foo")
    containsElement "hello world" "${arr[@]}"
}

# ---------------------------------------------------------------------------
# getPeeredServices()
# ---------------------------------------------------------------------------

@test "getPeeredServices: includes traefik by default" {
    result="$(getPeeredServices)"
    [[ "${result}" == *"traefik"* ]]
}

@test "getPeeredServices: includes tunnel by default" {
    result="$(getPeeredServices)"
    [[ "${result}" == *"tunnel"* ]]
}

@test "getPeeredServices: includes phpmyadmin when WARDEN_PHPMYADMIN_ENABLE=1" {
    WARDEN_PHPMYADMIN_ENABLE=1
    result="$(getPeeredServices)"
    [[ "${result}" == *"phpmyadmin"* ]]
}

@test "getPeeredServices: excludes phpmyadmin when WARDEN_PHPMYADMIN_ENABLE is unset" {
    unset WARDEN_PHPMYADMIN_ENABLE
    result="$(getPeeredServices)"
    [[ "${result}" != *"phpmyadmin"* ]]
}

# ---------------------------------------------------------------------------
# warning / error output (messaging functions)
# ---------------------------------------------------------------------------

@test "warning: outputs to stderr with WARNING label" {
    result="$(warning "test warning" 2>&1)"
    [[ "${result}" == *"WARNING"* ]]
    [[ "${result}" == *"test warning"* ]]
}

@test "error: outputs to stderr with ERROR label" {
    result="$(error "test error" 2>&1)"
    [[ "${result}" == *"ERROR"* ]]
    [[ "${result}" == *"test error"* ]]
}
