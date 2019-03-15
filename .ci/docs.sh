#!/usr/bin/env bash
if [[ ! -e .ci/common.sh || ! -e pytest_plt ]]; then
    echo "Run this script from the root directory of this repository"
    exit 1
fi
source .ci/common.sh

# This script builds the documentation and uploads it to GitHub pages

NAME=$0
COMMAND=$1

if [[ "$COMMAND" == "install" ]]; then
    exe conda install --quiet numpy
    exe pip install -e .[docs]
elif [[ "$COMMAND" == "script" ]]; then
    exe sphinx-build -b linkcheck -vW docs docs/_build

    git clone -b gh-pages-release https://github.com/nengo/pytest-plt.git ../pytest-plt-docs
    RELEASES=$(find ../pytest-plt-docs -maxdepth 1 -type d -name "v[0-9].*" -printf "%f,")

    if [[ "$TRAVIS_BRANCH" == "$TRAVIS_TAG" ]]; then
        RELEASES="$RELEASES$TRAVIS_TAG"
        exe sphinx-build -b html docs ../pytest-plt-docs/"$TRAVIS_TAG" -vW -A building_version="$TRAVIS_TAG" -A releases="$RELEASES"
    else
        exe sphinx-build -b html docs ../pytest-plt-docs -vW -A building_version=latest -A releases="$RELEASES"
    fi
elif [[ "$COMMAND" == "after_success" ]]; then
    cd ../pytest-plt-docs || exit
    git config --global user.email "travis@travis-ci.org"
    git config --global user.name "TravisCI"
    git add --all
    if [[ "$TRAVIS_BRANCH" == "$TRAVIS_TAG" ]]; then
        exe git commit -m "Documentation for release $TRAVIS_TAG"
        exe git push -q "https://$GH_TOKEN@github.com/nengo/pytest-plt.git" gh-pages-release
    elif [[ "${TRAVIS_PULL_REQUEST_BRANCH:-$TRAVIS_BRANCH}" == "master" ]]; then
        exe git commit -m "Last update at $(date '+%Y-%m-%d %T')"
        exe git push -fq "https://$GH_TOKEN@github.com/nengo/pytest-plt.git" gh-pages-release:gh-pages
    elif [[ "$TRAVIS_PULL_REQUEST" == "false" ]]; then
        exe git commit -m "Documentation for branch $TRAVIS_BRANCH"
        exe git push -fq "https://$GH_TOKEN@github.com/nengo/pytest-plt.git" gh-pages-release:gh-pages-test
    fi
elif [[ -z "$COMMAND" ]]; then
    echo "$NAME requires a command like 'install' or 'script'"
else
    echo "$NAME does not define $COMMAND"
fi

exit "$STATUS"
