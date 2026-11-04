#!/usr/bin/env bash

set -u

root_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

for old_output in "$root_dir"/Testcase[0-9]*Diff; do
    [[ -d "$old_output" ]] || continue
    old_name=${old_output##*/}
    if [[ $old_name =~ ^Testcase[0-9]+Diff$ ]]; then
        rm -rf -- "$old_output"
    fi
done

for testcase_dir in "$root_dir"/Testcase[0-9]*; do
    [[ -d "$testcase_dir" ]] || continue
    testcase_name=${testcase_dir##*/}
    [[ $testcase_name =~ ^Testcase([0-9]+)$ ]] || continue
    testcase_number=${BASH_REMATCH[1]}
    stage_dir=$(mktemp -d)
    has_differences=0

    for file1 in "$testcase_dir"/*.1.txt; do
        [[ -f "$file1" ]] || continue
        stem=${file1##*/}
        stem=${stem%.1.txt}
        file2="$testcase_dir/$stem.2.txt"
        [[ -f "$file2" ]] || continue

        output_file="$stage_dir/${stem}Diff.txt"
        input_name=${file1##*/}

        if (cd "$root_dir" && diff -u -- "$testcase_name/$input_name" "$testcase_name/${stem}.2.txt") > "$output_file"; then
            rm -f -- "$output_file"
        else
            diff_status=$?
            if (( diff_status == 1 )); then
                has_differences=1
            else
                rm -rf -- "$stage_dir"
                printf 'diff failed for %s and %s\n' "$file1" "$file2" >&2
                exit "$diff_status"
            fi
        fi
    done

    if (( has_differences )); then
        output_dir="$root_dir/Testcase${testcase_number}Diff"
        mkdir -p -- "$output_dir"
        mv -- "$stage_dir"/* "$output_dir"/
    fi
    rm -rf -- "$stage_dir"
done