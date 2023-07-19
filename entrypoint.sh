#!/bin/bash
set -ev

if [ -z "$INPUT_DIRECTORY" ]; then
    INPUT_DIRECTORY="."
fi

xvfb-run /usr/games/megaglest --validate-techtrees=$INPUT_DIRECTORY | sed -e/======\ Started\ Validation\ ======/\{ -e:1 -en\;b1 -e\} -ed > results.txt

ret=0
cat results.txt
grep -i error results.txt || exit 0
# if [ INPUT_FAIL_ON_WARNING = true ] then
exit 1
# fi
if [ $ret eq 1]; then
  #if fail_on_warning = true
  # grep check for warning
  # if warning found, exit 1 else exit 0
fi
exit 0

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
