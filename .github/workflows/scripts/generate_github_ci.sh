#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

CI_WORKFLOW_FILE=.github/workflows/ci.yml

generate_job () {
    NAME=$1
    GRADLE_ARGS=$2

    cat <<END >> $CI_WORKFLOW_FILE
    ${NAME}:
        runs-on: ubuntu-18.04
        steps:
          - uses: actions/checkout@v2
          - uses: actions/setup-java@v1
            with:
              java-version: '1.8'
          - name: Cache Gradle Home files
            uses: actions/cache@v1
            with:
              path: ~/.gradle/caches
              key: \${{ runner.os }}-gradle-home-$NAME-\${{ hashFiles('**/*.gradle') }}
              restore-keys: |
                            \${{ runner.os }}-gradle-home-$NAME-
                            \${{ runner.os }}-gradle-home-core_check-
                            \${{ runner.os }}-gradle-home-
          - name: Build with Gradle
            run: |
                ./gradlew --no-daemon --continue --scan --info ${GRADLE_ARGS}
END
}

generate_preface () {
    cat <<END > $CI_WORKFLOW_FILE

# This file is generated by .github/workflows/scripts/generate_github_ci.sh
# DO NOT HAND EDIT
name: CI

on:
  pull_request: {}
  push: { branches: [ master ] }

jobs:
END
}

generate_preface
generate_job core_check "testcontainers:check"

find modules -type d -mindepth 1 -maxdepth 1 | while read -r MODULE_DIRECTORY; do
    MODULE=$(basename "$MODULE_DIRECTORY")
    generate_job module_${MODULE}_check ${MODULE}:check
done
