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

output_step_summary() {
	file=$1
	reason=$2
	logfile=$3
	echo "❌ TEST FAILED: [$file](https://github.com/spacestation13/dm-test-suite/tree/master/$file)" >> $GITHUB_STEP_SUMMARY
	echo "" >> $GITHUB_STEP_SUMMARY # Critical empty line
    
    echo "<details>" >> $GITHUB_STEP_SUMMARY
    echo "<summary>$reason</summary>" >> $GITHUB_STEP_SUMMARY
    echo "" >> $GITHUB_STEP_SUMMARY # Critical empty line
    
    echo "\`\`\`text" >> $GITHUB_STEP_SUMMARY
    cat $logfile >> $GITHUB_STEP_SUMMARY
    echo "\`\`\`" >> $GITHUB_STEP_SUMMARY
    
    echo "" >> $GITHUB_STEP_SUMMARY # Critical empty line
    echo "</details>" >> $GITHUB_STEP_SUMMARY
	echo "" >> $GITHUB_STEP_SUMMARY # Critical empty line
}

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
			output_step_summary $file "Compile failure!" result.log
			echo "Failed: $relative" >> $logfile
			testsfailed=$((testsfailed + 1))
			return
		fi
	else
		if [[ $first_line == "// COMPILE ERROR"* || $first_line == "//COMPILE ERROR"* ]] then	#expected compile error, should fail to compile
			output_step_summary $file "Expected a compile failure!" result.log
			echo "Failed: $relative" >> $logfile
			testsfailed=$((testsfailed + 1))
			return
		fi
	fi

	echo "Running $relative"
	touch Tests/errors.log
	if ! DreamDaemon Tests/environment.dmb -once -close -trusted -verbose -invisible -log errors.log ; then
		output_step_summary $file "BYOND crashed!" Tests/errors.log
		echo "CRASHED: $relative" >> $logfile
		byondcrashes=$((byondcrashes+1))
		sed -i '/^[[:space:]]*$/d' Tests/errors.log
		cat Tests/errors.log
		rm Tests/errors.log
		testsfailed=$((testsfailed + 1))
		return
	fi
	sed -i '1,3d; /^[[:space:]]*$/d' Tests/errors.log
	if [ -s Tests/errors.log ]
	then
		if [[ $first_line == "// RUNTIME ERROR"* || $first_line == "//RUNTIME ERROR"* ]]
		then #expected runtime error, should compile but then fail to run
			echo "Expected runtime error, test passed"
			rm Tests/errors.log
			testspassed=$((testspassed + 1))
			return
		else
			echo "Errors detected!"
			sed -i '/^[[:space:]]*$/d' Tests/errors.log
			output_step_summary $file "Runtime error" Tests/errors.log
			echo "TEST FAILED:$file:Unexpected runtime error"
			rm Tests/errors.log
			echo "Failed: $relative" >> $logfile
			testsfailed=$((testsfailed + 1))
			return
		fi
	else
		if [[ $first_line == "// RUNTIME ERROR"* || $first_line == "//RUNTIME ERROR"* ]]
		then #expected runtime error, should compile but then fail to run
			echo "TEST FAILED:$file:Expected runtime error, but none found!"
			output_step_summary $file "Expected runtime error" Tests/errors.log
			rm Tests/errors.log
			echo "Failed: $relative" >> $logfile
			testsfailed=$((testsfailed + 1))
			return
		else	
			echo "Test passed: $relative"
			testspassed=$((testspassed + 1))
			rm Tests/errors.log
		fi
	fi
}

echo "# Test Summary" >> $GITHUB_STEP_SUMMARY

while read -r file; do
	run_single_test $file mainsummary.log
done < <(find Tests/Tests -type f -name "*$filter*.dm")

if [[ "$testsfailed" -eq 0 ]]
then
	echo "### ✅ All tests passed" >> $GITHUB_STEP_SUMMARY
fi

echo "--------------------------------------------------------------------------------"
echo "Test Summary"
echo "--------------------------------------------------------------------------------"
echo "passed: $testspassed, failed: $testsfailed, BYOND crashes: $byondcrashes"
echo "--------------------------------------------------------------------------------"
echo "Failed tests:"
cat mainsummary.log

echo "passed=$testspassed" >> "$GITHUB_OUTPUT"
echo "failed=$testsfailed" >> "$GITHUB_OUTPUT"
echo "crashes=$byondcrashes" >> "$GITHUB_OUTPUT"

summarytestsfailed=$testsfailed
testsfailed=0
byondcrashes=0
testspassed=0

echo "" >> $GITHUB_STEP_SUMMARY
echo "## Open Issues" >> $GITHUB_STEP_SUMMARY

while read -r file; do
	run_single_test $file opensummary.log
done < <(find Tests/OpenIssues -type f -name "*$filter*.dm")

if [[ "$testsfailed" -eq 0 ]]
then
	echo "### ✅ All tests passed" >> $GITHUB_STEP_SUMMARY
fi


echo "--------------------------------------------------------------------------------"
echo "Open Issues"
echo "--------------------------------------------------------------------------------"
echo "passed: $testspassed, failed: $testsfailed, BYOND crashes: $byondcrashes"
echo "--------------------------------------------------------------------------------"
echo "Failed tests:"
cat opensummary.log

echo "openpassed=$testspassed" >> "$GITHUB_OUTPUT"
echo "openfailed=$testsfailed" >> "$GITHUB_OUTPUT"
echo "opencrashes=$byondcrashes" >> "$GITHUB_OUTPUT"

exit $summarytestsfailed

