#!/usr/bin/env -S bash --posix
set -ev

#if [ -z "$INPUT_DIRECTORY" ]; then
    #echo "directory is required"
    #exit 1
#fi

test -f "$INPUT_DIRECTORY/$INPUT_NAME.xml"

# show some variables
export -p

type=(tech scenario tileset)
subdir=(${type[0]}s ${type[1]}s ${type[2]}s)
validate_type=(techtrees ${type[1]} ${type[2]})

FAKE_HOME="/fake_home"

mg_sub=""
validate_substr=""
i=0
for t in ${type[@]}; do
  if [ "$t" = "$INPUT_TYPE" ]; then
    mg_sub="$FAKE_HOME/.megaglest/${subdir[i]}"
    validate_substr="${validate_type[i]}"
    break
  fi
  ((i=i+1))
done

if [ -z "$mg_sub" ]; then
  echo "'type' must be one of the following:"
  echo
  printf '%s\n' "${type[@]}"
  exit 1
fi

mg_sub="$mg_sub/$INPUT_NAME"
echo $mg_sub
mkdir -p "$mg_sub"
mv "$INPUT_DIRECTORY/"* "$mg_sub"

HOME="$FAKE_HOME" xvfb-run /usr/games/megaglest --validate-"$validate_substr"="$INPUT_NAME" | sed -e/======\ Started\ Validation\ ======/\{ -e:1 -en\;b1 -e\} -ed > results.txt

cat results.txt
grep -i 'NO ERRORS' results.txt || exit 1

# The commas used for expansion indicate to change all characters to lowercase
if [ "${INPUT_FAIL_ON_WARNING,,}" = "yes" ]; then
  grep -i warning results.txt && exit 1
fi

rm results.txt

OUTPUT_DIR="$GITHUB_WORKSPACE/output"
mkdir -m 777 -p "$OUTPUT_DIR"
OUTPUT_FILE="$OUTPUT_DIR/$INPUT_NAME-$INPUT_VERSION.7z"
7z a "$OUTPUT_FILE" "$mg_sub"
7z d "$OUTPUT_FILE" "$INPUT_NAME/.git"*

for item in $INPUT_REMOVE_FROM_MOD; do
  if [ -z "${item##*.git*}" ]; then
    continue
  fi
  7z d "$OUTPUT_FILE" "$item"
done
