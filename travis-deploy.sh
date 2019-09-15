#!/bin/bash

set -xeuo pipefail

# https://github.com/travis-ci/travis-build/blob/4f580b238530108cdd08719c326cd571d4e7b99f/lib/travis/build/bash/travis_retry.bash
travis_retry() {
  local result=0
  local count=1
  while [[ "${count}" -le 3 ]]; do
    [[ "${result}" -ne 0 ]] && {
      echo -e "\\n${ANSI_RED}The command \"${*}\" failed. Retrying, ${count} of 3.${ANSI_RESET}\\n" >&2
    }
    "${@}" && { result=0 && break; } || result="${?}"
    count="$((count + 1))"
    sleep 1
  done

  [[ "${count}" -gt 3 ]] && {
    echo -e "\\n${ANSI_RED}The command \"${*}\" failed 3 times.${ANSI_RESET}\\n" >&2
  }

  return "${result}"
}


echo "push to ${DOCKER_IMAGE}:${TAG}"
travis_retry docker push "${DOCKER_IMAGE}:${TAG}"

if [ -n "${ALIASES+x}" ]; then
  for ALIAS in ${ALIASES}; do
    echo "Pushing tag aliases ${ALIAS}"
    docker tag "${DOCKER_IMAGE}:${TAG}" "${DOCKER_IMAGE}:${ALIAS}"
    travis_retry docker push "${DOCKER_IMAGE}:${ALIAS}"
  done
fi

if [ -n "${SNAPSHOT+x}" ] && [ "$(date +%d)" -eq "1" ]; then
  echo "Pushing snapshot tag $(date +%Y%m)"
  docker tag "${DOCKER_IMAGE}:${TAG}" "${DOCKER_IMAGE}:$(date +%Y%m)"
  travis_retry docker push "${DOCKER_IMAGE}:$(date +%Y%m)"
fi
