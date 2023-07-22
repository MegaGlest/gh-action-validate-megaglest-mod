#!/usr/bin/env -S bash --posix
set -ev

#if [ -z "$INPUT_DIRECTORY" ]; then
    #echo "directory is required"
    #exit 1
#fi

test -f "$INPUT_DIRECTORY/$INPUT_NAME.xml"
WORK_DIR="$GITHUB_WORKSPACE/../$INPUT_NAME"
MOD_TMP_DIR="$WORK_DIR/$INPUT_NAME"
mkdir -p "$MOD_TMP_DIR"

if [ -n "$INPUT_DEPENDENCIES" ]; then
  for dep in ${INPUT_DEPENDENCIES}; do
    mv "$dep" "$WORK_DIR"
  done
fi
mv "$INPUT_DIRECTORY"/* "$MOD_TMP_DIR"

# show some variables
export -p

type=(tech scenario tileset)
subdir=(${type[0]}s ${type[1]}s ${type[2]}s)
validate_type=(techtrees ${type[1]} ${type[2]})

FAKE_HOME="./fake_home"

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

echo $mg_sub
mkdir -p "$mg_sub"
mv "$MOD_TMP_DIR" "$mg_sub"

if [ -n "$INPUT_DEPENDENCIES" ]; then
  for dep in ${INPUT_DEPENDENCIES}; do
    mv "$WORK_DIR/$dep" "$FAKE_HOME/.megaglest/techs"
  done
fi

HOME="$FAKE_HOME" xvfb-run /usr/games/megaglest --validate-"$validate_substr"="$INPUT_NAME" | sed -e/======\ Started\ Validation\ ======/\{ -e:1 -en\;b1 -e\} -ed > results.txt

cat results.txt
grep -i 'NO ERRORS' results.txt || exit 1

# The commas used for expansion indicate to change all characters to lowercase
if [ "${INPUT_FAIL_ON_WARNING,,}" = "yes" ]; then
  grep -i warning results.txt && exit 1
fi

OUTPUT_DIR="$GITHUB_WORKSPACE/output"
# so changes can be made in the workflow outside the action
mkdir -m 1777 -p "$OUTPUT_DIR"

# move the mod folder to the output dir, which can then be processed
# by a user in their workflow as desired
mv "$mg_sub/$INPUT_NAME" "$OUTPUT_DIR"

if [ -n "$INPUT_RELEASE_NAME" ]; then
  cd "$OUTPUT_DIR/$INPUT_NAME"
  mv "$INPUT_NAME.xml" "$INPUT_RELEASE_NAME.xml"
  cd ..
  mv "$INPUT_NAME" "$INPUT_RELEASE_NAME"
fi
