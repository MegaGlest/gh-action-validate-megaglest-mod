[![Test Action](https://github.com/MegaGlest/gh-action-validate-megaglest-mod/actions/workflows/test.yml/badge.svg)](https://github.com/MegaGlest/gh-action-validate-megaglest-mod/actions/workflows/test.yml)

# gh-action-validate-megaglest-mod

GitHub Action to validate and build a [MegaGlest](https://megaglest.org/) mod

## Usage

If your mod is not in the root directory of your repository, you can
add the 'directory' argument (see options below).

The example shown below has two separate jobs:

1. When there is a push to the default branch, or when a pull request is
opened or updated, the mod is built and is uploaded to the workflow output
page.

2. When a new a new tag is created (if the tag starts with a 'v'), the
built mod will get uploaded to the release page, along with a
corresponding sha256sum.

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

env:
  MOD_NAME: <mod-name>
  RELEASE_NAME: <release-name>

jobs:
  validate-and-build-mod:
    if: ${{ github.ref_type != 'tag' }}
    runs-on: ubuntu-latest
    env:
      MOD_VERSION: ${{ github.sha }}
    steps:
    - uses: actions/checkout@v3
    - uses: megaglest/gh-action-validate-megaglest-mod@v1
      with:
        name: ${{ env.MOD_NAME }}
        type: tech
    - name: Make 7z
      run: |
        cd output
        7z a $MOD_NAME.7z $MOD_NAME

    - name: Upload Artifacts
      # Uploads artifacts (combined into a zip file) to the workflow output page
      uses: actions/upload-artifact@v3
      with:
        name: ${{ env.MOD_NAME }}-${{ env.MOD_VERSION }}
        path: "output/${{ env.MOD_NAME }}*.7z"

  release-mod:
    if: ${{ github.ref_type == 'tag' }}
    runs-on: ubuntu-latest
    env:
      MOD_VERSION: ${{ github.ref_name }}
    steps:
    - uses: actions/checkout@v3
    - name: Massage Variables
      run: |
        echo "MOD_VERSION=${MOD_VERSION:1}" >> $GITHUB_ENV
    - uses: megaglest/gh-action-validate-megaglest-mod@v1
      with:
        name: ${{ env.MOD_NAME }}
        release_name: ${{ env.RELEASE_NAME }}
        type: tech
    - name: Make 7z
      run: |
        cd output/$RELEASE_NAME
        sudo mv $RELEASE_NAME.xml $RELEASE_NAME-$MOD_VERSION.xml
        cd ..
        sudo mv $RELEASE_NAME $RELEASE_NAME-$MOD_VERSION
        7z a $RELEASE_NAME-$MOD_VERSION.7z $RELEASE_NAME-$MOD_VERSION
        sudo rm -rf $RELEASE_NAME-$MOD_VERSION
    - name: Create sha256sum
      run:  |
        OUTPUT_FILE="$RELEASE_NAME-$MOD_VERSION.7z"
        cd output
        sha256sum $OUTPUT_FILE > $OUTPUT_FILE.sha256sum
    - name: Release Mod
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

The example below demonstrates how to code your yaml if your mod requires one
or more techtrees as dependencies:

```yaml
  test-megaglest-scenario:
    runs-on: ubuntu-latest
    env:
      TEST_MOD_NAME: 'egypt_has_fallen'
    steps:
    - uses: actions/checkout@v3
    - name: clone scenario
      run: |
        git clone --depth 1 https://github.com/zetaglest/${{ env.TEST_MOD_NAME }} test
        # get only the megapack techtree
        git clone -n --depth=1 --filter=tree:0 https://github.com/megaglest/megaglest-data
        cd megaglest-data
        git sparse-checkout set --no-cone techs/megapack
        git checkout
        mv techs/megapack $GITHUB_WORKSPACE
        rm -rf $GITHUB_WORKSPACE/megaglest-data
        cd $GITHUB_WORKSPACE
    - name: Run Validate Action
      uses: megaglest/gh-action-validate-megaglest-mod@v1
      with:
        name: ${{ env.TEST_MOD_NAME }}
        directory: test
        type: scenario
        fail_on_warning: no
        dependencies: 'megapack'
```

## Additional Notes

If you have more than one dependency, separate them with a space:

     dependencies: 'megapack techtree2 techtree3'

If your mod resides in a repository and the main xml has something like 'dev'
or 'testing' in the filename, you can use `release_name` to strip that away.

The docker image used by this action is pulled from
[jammyjamjamman/megaglest-no-data](https://hub.docker.com/repository/docker/jammyjamjamman/megaglest-no-data).
