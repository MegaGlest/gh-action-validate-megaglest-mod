# GitHub Action to validate and build a [MegaGlest](https://megaglest.org/) mod

## Usage

If your mod is not in the root directory of your repository, you can
add the 'directory' argument (see option table below) after 'with:' to
specify the relative path.

The example shown below has two separate jobs:

1. When there is a push to the default branch, or when a pull request
is opened or updated, the pyromod is built and is uploaded to the
workflow output page.

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
  MOD_NAME: <your-mod>

jobs:
  build-pyromod:
    if: ${{ github.ref_type != 'tag' }}
    runs-on: ubuntu-latest
    env:
      MOD_VERSION: ${{ github.sha }}
    steps:
    - uses: actions/checkout@v3
    - uses: megaglest/gh-action-validate-megaglest-mod@v1
      with:
        name: ${{ env.MOD_NAME }}
        version: ${{ env.MOD_VERSION }}
      id: build-mod
    - name: Upload Artifacts
      # Uploads artifacts (combined into a zip file) to the workflow output page
      uses: actions/upload-artifact@v3
      with:
        name: ${{ env.MOD_NAME }}-${{ env.MOD_VERSION }}
        path: "output/${{ env.MOD_NAME }}*.*"

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
    - uses:  megaglest/gh-action-validate-megaglest-mod@v1
      with:
        name: ${{ env.MOD_NAME }}
        version: ${{ env.MOD_VERSION }}
      id: build-mod
    - name: Create sha256sum
      run:  |
        OUTPUT_FILE="$MOD_NAME-$MOD_VERSION.7z"
        cd output
        sha256sum $OUTPUT_FILE > $OUTPUT_FILE.sha256sum
    - name: Release Mod
      uses: ncipollo/release-action@v1
      with:
        allowUpdates: True
        prerelease: False
        artifacts: "output/${{ env.MOD_NAME }}*.*"
        token: ${{ secrets.GITHUB_TOKEN }}
        omitNameDuringUpdate: True
        omitBodyDuringUpdate: True
```

## Option table

| name | required | description | default |
|----------|--------|-------------|--------|
| name | true | | |
| version | true | | |
| directory | false | relative path to your mod.json file | '.' |
| remove_from_pyromod | false | list of files or directories to remove, each separated by a space (wildcards ok) | |

Note that this action will remove '.git*' from the pyromod by default
and doesn't need to be added to the 'remove_from_pyromod' string.

remove_from_pyromod example:

    remove_from_pyromod: 'foo bar /package.json /.*'

## Additional Notes

Option table

The docker image used by this action is published from
[0ad-matters/0ad-bin-nodata](https://github.com/0ad-matters/0ad-bin-nodata)
and pulled from
[andy5995/0ad-bin-nodata](https://hub.docker.com/repository/docker/andy5995/0ad-bin-nodata).
