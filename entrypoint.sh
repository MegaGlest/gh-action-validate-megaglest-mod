#!/bin/bash
set -ev

exit 0
# xvfb-run ./usr/games/megaglest --validate-techtrees=insects-mod/git_repos/Insects-World-Mod/insects_world_dev/ | sed -e/======\ Started\ Validation\ ======/\{ -e:1 -en\;b1 -e\} -ed
if [ -z "$INPUT_DIRECTORY" ]; then
    INPUT_DIRECTORY="."
fi

OUTPUT_DIR=/github/workspace/output
mkdir -m 777 -p $OUTPUT_DIR
OUTPUT_FILE="$OUTPUT_DIR/$INPUT_NAME-$INPUT_VERSION.7z"

# validate
# build 7z

zip -d "$OUTPUT_FILE" ".git*"

for item in $INPUT_REMOVE_FROM_MOD; do
  if [ -z "${item##*.git*}" ]; then
    continue
  fi
  zip -d "$OUTPUT_FILE" "$item"
done
