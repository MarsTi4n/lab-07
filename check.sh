#!/usr/bin/env bash

root_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
all_passed=1
shopt -s nullglob dotglob

for testcase_number in {1..4}; do
	testcase_name="Testcase${testcase_number}"
	testcase_dir="$root_dir/$testcase_name"
	output_dir="$root_dir/Testcase${testcase_number}Diff"
	testcase_passed=1
	has_differences=0
	declare -A expected_outputs=()

	if [[ ! -d "$testcase_dir" ]]; then
		testcase_passed=0
	else
		for file1 in "$testcase_dir"/*.1.txt; do
			[[ -f "$file1" ]] || continue
			stem=${file1##*/}
			stem=${stem%.1.txt}
			file2="$testcase_dir/$stem.2.txt"
			[[ -f "$file2" ]] || continue

			output_name="${stem}Diff.txt"
			output_file="$output_dir/$output_name"
			relative_file1="$testcase_name/${file1##*/}"
			relative_file2="$testcase_name/${stem}.2.txt"

			if (cd "$root_dir" && diff -u -- "$relative_file1" "$relative_file2") > /dev/null; then
				if [[ -e "$output_file" ]]; then
					testcase_passed=0
				fi
			else
				diff_status=$?
				if (( diff_status == 1 )); then
					has_differences=1
					expected_outputs["$output_name"]=1
					if [[ ! -f "$output_file" ]] || ! cmp -s -- "$output_file" <(cd "$root_dir" && diff -u -- "$relative_file1" "$relative_file2"); then
						testcase_passed=0
					fi
				else
					testcase_passed=0
				fi
			fi
		done
	fi

	if (( has_differences )); then
		[[ -d "$output_dir" ]] || testcase_passed=0
	elif [[ -e "$output_dir" ]]; then
		testcase_passed=0
	fi

	if [[ -d "$output_dir" ]]; then
		for output_file in "$output_dir"/*; do
			[[ -e "$output_file" ]] || continue
			output_name=${output_file##*/}
			if [[ ! -f "$output_file" || -z ${expected_outputs[$output_name]+present} ]]; then
				testcase_passed=0
			fi
		done
	fi

	if (( testcase_passed )); then
		printf 'Testcase%s: PASS\n' "$testcase_number"
	else
		printf 'Testcase%s: FAIL\n' "$testcase_number"
		all_passed=0
	fi
done

(( all_passed ))
