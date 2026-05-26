#!/bin/bash
set -euo pipefail

rm -f mainsummary.log
touch mainsummary.log
rm -f opensummary.log
touch opensummary.log
base="Tests/environment.dme"
testsfailed=0
byondcrashes=0
testspassed=0

filter=""

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --filter) filter="$2"; shift ;;
  esac
  shift
done

run_single_test() {
	file=$1
	logfile=$2
	first_line=$(head -n 1 "$file" || echo "")
	second_line=$((head -n 2 "$file" | tail -n 1) || echo "")
	relative=$(realpath --relative-to="$(dirname "$base")" "$file")
	if [[ $first_line == "// NOBYOND"* || $second_line == "// NOBYOND"* ]]; then
		#skip this one, it won't work in byond
		echo "Skipping $relative due to NOBYOND mark"
		return
	fi
	if [[ $first_line == "// IGNORE"* ]]; then
		#skip this one, it won't work in byond
		echo "Skipping $relative due to IGNORE mark"
		return
	fi
	

	echo "Compiling $relative"
	if ! tools/ci/dm.sh -I\"$relative\" -I\"crashwrapper.dm\" $base; then
		if [[ $first_line == "// COMPILE ERROR"* || $first_line == "//COMPILE ERROR"* ]] then	#expected compile error, should fail to compile
			echo "Expected compile failure, test passed"
			testspassed=$((testspassed + 1))
			return
		else
			echo "TEST FAILED:$relative:Compile failure"
			echo "Failed: $relative" >> $logfile
			testsfailed=$((testsfailed + 1))
			return		
		fi
	else
		if [[ $first_line == "// COMPILE ERROR"* || $first_line == "//COMPILE ERROR"* ]] then	#expected compile error, should fail to compile
			echo "TEST FAILED:$relative:Expected compile failure"
			echo "Failed: $relative" >> $logfile
			testsfailed=$((testsfailed + 1))
			return
		fi
	fi

	echo "Running $relative"
	touch Tests/errors.log
	if ! DreamDaemon Tests/environment.dmb -once -close -trusted -verbose -invisible; then
		echo "TEST FAILED:$relative:BYOND crashed"
		echo "Failed (CRASH): $relative" >> $logfile
		byondcrashes=$((byondcrashes+1))
		sed -i '/^[[:space:]]*$/d' Tests/errors.log
		cat Tests/errors.log
		rm Tests/errors.log
		testsfailed=$((testsfailed + 1))
		return
	fi
	if [ -s "Tests/errors.log" ]; then
		if [[ $first_line == "// RUNTIME ERROR"* || $first_line == "//RUNTIME ERROR"* ]]	then #expected runtime error, should compile but then fail to run
			echo "Expected runtime error, test passed"
			rm Tests/errors.log
			testspassed=$((testspassed + 1))
			return
		else
			echo "Errors detected!"
			sed -i '/^[[:space:]]*$/d' Tests/errors.log
			cat Tests/errors.log
			echo "TEST FAILED:$relative:Expected runtime error"
			rm Tests/errors.log
			echo "Failed test: $relative" >> $logfile
			testsfailed=$((testsfailed + 1))
			return
		fi
	else
		echo "Test passed: $relative"
		testspassed=$((testspassed + 1))
	fi
}

while read -r file; do
	run_single_test $file mainsummary.log
done < <(find Tests/Tests -type f -name "*$filter*.dm")


echo "--------------------------------------------------------------------------------"
echo "Test Summary"
echo "--------------------------------------------------------------------------------"
echo "passed: $testspassed, failed: $testsfailed, BYOND crashes: $byondcrashes"
echo "--------------------------------------------------------------------------------"
echo "failed tests:"
cat mainsummary.log

echo "passed=$testspassed" >> "$GITHUB_OUTPUT"
echo "failed=$testsfailed" >> "$GITHUB_OUTPUT"
echo "crashes=$byondcrashes" >> "$GITHUB_OUTPUT"

summarytestsfailed=$testsfailed
testsfailed=0
byondcrashes=0
testspassed=0

while read -r file; do
	run_single_test $file opensummary.log
done < <(find Tests/OpenIssues -type f -name "*$filter*.dm")


echo "--------------------------------------------------------------------------------"
echo "Open Issues"
echo "--------------------------------------------------------------------------------"
echo "passed: $testspassed, failed: $testsfailed, BYOND crashes: $byondcrashes"
echo "--------------------------------------------------------------------------------"
echo "failed tests:"
cat opensummary.log

echo "openpassed=$testspassed" >> "$GITHUB_OUTPUT"
echo "openfailed=$testsfailed" >> "$GITHUB_OUTPUT"
echo "opencrashes=$byondcrashes" >> "$GITHUB_OUTPUT"

exit $summarytestsfailed

