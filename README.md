[![Test Action](https://github.com/MegaGlest/gh-action-validate-megaglest-mod/actions/workflows/test.yml/badge.svg)](https://github.com/MegaGlest/gh-action-validate-megaglest-mod/actions/workflows/test.yml)

# gh-action-validate-megaglest-mod

GitHub Action to validate and build a [MegaGlest](https://megaglest.org/) mod

## Usage

If your mod is not in the root directory of your repository, you can add the
'directory' argument (see examples and options below).

The example shown below has two separate functions:

1. When there is a push to the default branch, or when a pull request is
opened or updated, the mod is validated by running `megaglest
--validate-<mod-type>=<yourmod>` in a [docker
container](https://docs.docker.com/get-started/what-is-a-container/).

2. When creating a release from GitHub and a new tag is created (if the tag
starts with a 'v'), the built mod will get uploaded to the release page, along
with a corresponding sha256sum.

This file needs to be placed in

    <your_repo_root>/.github/workflows/<filename>.yml

(where `<filename>` can be anything you like)

The [release action](https://github.com/ncipollo/release-action) used
in the example below is a separate action (not maintained by this
project) and can be replaced by a different release action if you
like.

```yaml
name: Validate MegaGlest mod

on:
  push:
    branches:
      - main
    tags:
      - v**
  pull_request:
    branches:
      - main

jobs:
  validate-mod:
    runs-on: ubuntu-latest
    env:
      MOD_NAME: <your-mod-name>
      RELEASE_NAME: <your-mod-release-name>
    steps:
    - uses: actions/checkout@v3

    - if: ${{ github.ref_type == 'tag' }}
      run: |
        MOD_VERSION=${{ github.ref_name }}
        echo "MOD_VERSION=${MOD_VERSION:1}" >> $GITHUB_ENV
    - uses:  megaglest/gh-action-validate-megaglest-mod@v1
      with:
        name: ${{ env.MOD_NAME }}
        release_name: ${{ env.RELEASE_NAME }}
        type: tech

    - if: ${{ github.ref_type == 'tag' }}
      name: Make 7z and sha256sum
      run: |
        OUT_FILE="$RELEASE_NAME-$MOD_VERSION"
        cd output/$RELEASE_NAME
        sudo mv $RELEASE_NAME.xml "$OUT_FILE".xml
        cd ..
        sudo mv "$RELEASE_NAME" "$OUT_FILE"
        7z a "$OUT_FILE.7z" "$OUT_FILE"
        sudo rm -rf "$OUT_FILE"
        sha256sum "$OUT_FILE.7z" > "$OUT_FILE.7z.sha256sum"

    - if: ${{ github.ref_type == 'tag' }}
      name: Release Mod
      uses: ncipollo/release-action@v1
      with:
        allowUpdates: True
        prerelease: False
        artifacts: "output/${{ env.RELEASE_NAME }}*.*"
        token: ${{ secrets.GITHUB_TOKEN }}
        omitNameDuringUpdate: True
        omitBodyDuringUpdate: True
```

## Options

```yaml
inputs:
  name:
    description: "name of the mod"
    required: true
    default: ''
  release_name:
    description: "Specify if the name of your mod is different for releases"
    required: false
    default: ''
  directory:
    description: "relative path to the directory containing the top-level mod xml file"
    required: false
    default: '.'
  dependencies:
    description: "additional dependencies for your mod (i.e. other techtrees)"
    required: false
    default: ''
  type:
    description: "tech, scenario, or tileset"
    required: true
    default: tech
  fail_on_warning:
    description: "Fail if no errors present, but warnings are indicated"
    required: false
    default: 'no'
```

The example below demonstrates how to code your yaml if your mod requires a
techtree as a dependency:

```yaml
...
    steps:
    - uses: actions/checkout@v3 # clones your mod repo
    - uses: actions/checkout@v3 # clones dependency
      with:
        clean: 'false'
        repository: 'megaglest/megaglest-data'
        path: 'megaglest-data'
        sparse-checkout: 'techs/megapack'
    - name: Get megapack
      run: |
        mv megaglest-data/techs/megapack $GITHUB_WORKSPACE
        rm -rf $GITHUB_WORKSPACE/megaglest-data
        cd $GITHUB_WORKSPACE
...
    - uses: megaglest/gh-action-validate-megaglest-mod@v1
      with:
        name: ${{ env.MOD_NAME }}
        type: scenario
        dependencies: 'megapack'
...
```

## Additional Notes

If you have more than one dependency, separate them with a newline:

```yaml
  dependencies: |
    megapack
    techtree2
    techtree3
```

If your mod resides in a repository and the main xml has something like 'dev'
or 'testing' in the filename, you can use `release_name` to strip that away.

The docker image used by this action is pulled from
[jammyjamjamman/megaglest-no-data](https://hub.docker.com/repository/docker/jammyjamjamman/megaglest-no-data).
