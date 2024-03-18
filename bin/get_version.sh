#!/usr/bin/env bash

# Get the date, first 4 chars of branch name and short commit hash
date=$(date -u +"%Y%m%d")
branch=${1:-$(git rev-parse --abbrev-ref HEAD)}
commit=${2:-$(git rev-parse --short HEAD)}
dirty=$(git diff-index --quiet HEAD && echo "" || echo "dirty")

# Function to transform characters to ZMK key behaviours
transform_char() {
    local char=$1
    case $char in
        [A-Za-z]) echo "<&kp ${char^^}>" ;;
        [0-9]) echo "<&kp N${char}>" ;;
        ".") echo "<&kp DOT>" ;;
        "-") echo "<&kp MINUS>" ;;
        *) echo "Unknown character '"$char"'" > /dev/stderr; exit 1 ;;
    esac
}

# Function to transform a string into ZMK key behaviours
transform_string() {
    local str=$1
    local -a transformed
    for ((i = 0; i < ${#str}; i++)); do
        transformed+=("$(transform_char "${str:$i:1}")") || exit 1
    done
    join_by ", " "${transformed[@]}"
}

# Output a string with arguments joined by a separator (first argument)
join_by() {
    local sep=$1
    shift
    local first=$1
    shift
    printf "%s" "$first" "${@/#/$sep}"
}

# Combine the string parts, add trailing carriage return
result=$(join_by "-" $date $branch $commit $dirty)

# Transform the combined string
formatted_result=$(transform_string "$result")", <&kp RET>" || exit 1

echo $result
echo $formatted_result

# Create new macro to define version, overwrite previous one
echo '#define VERSION_MACRO' > "config/version.dtsi"
echo 'macro_ver: macro_ver {' >> "config/version.dtsi"
echo 'compatible = "zmk,behavior-macro";' >> "config/version.dtsi"
echo 'label = "macro_ver";' >> "config/version.dtsi"
echo '#binding-cells = <0>;' >> "config/version.dtsi"
echo "bindings = $formatted_result;" >> "config/version.dtsi"
echo '};' >> "config/version.dtsi"
