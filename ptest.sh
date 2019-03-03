#!/bin/bash
red="\033[0;91m"
nocolor="\033[0m"
green="\033[0;92m"
yellow="\033[0;33m"
blue="\033[38;5;111m"

wrong="${red}\u2717${nocolor}"
fat_wrong="\u2718"
right="${green}\u2713${nocolor}"
fat_right="u2714"

function what_was_passed_to_this_script() {
  passed=$1
  if [[ -d $passed ]]; then
    run_all_java_programs $passed
    return 0
  elif [[ -f $passed ]]; then
    run_java_program $passed
    return 0
  else
    return 1
  fi
}

function run_all_java_programs() {
  for java_source_code in *.java; do
    local file=$java_source_code
    run_java_program $file
  done
}

function run_java_program() {
  java_file=$1
  printf "${blue}\e[1mRunning ${java_file}...${nocolor}"

  javac $java_file 2> /dev/null
  compile_val=$?
  if [[ $compile_val != 0 ]]; then
    echo -e "** fail ** (failed to compile) ${wrong}"
    return 1
  fi

  subdircount="$(find . -maxdepth 1 -type d | wc -l)"
  if [[ $subdircount -lt 1 ]]; then
    echo -e "no input data ${fat_wrong}\n"
    exit 1
  fi
  echo""

  local file=${java_file%.*}
  for program in data/$file; do
    for case in $program/*/; do
      run_on_input_files ${file} ${case}
    done
  done
  return 0
}

function run_on_input_files() {
  local file=$1
  local dir=$2

  local result=${file}Output.txt
  touch $result
  echo -n "$(java $file)" > $result 2> /dev/null
  execution_val=$?
  if [[ $execution_val != 0 ]]; then
    print_right_aligned ${dir} "** fail ** (program crashed)" ${wrong}
    return 1 
  fi

  diff $result $dir/$file.out> /dev/null
  diff_val=$?
  
  if  [[ $diff_val != 0 ]]; then
    print_right_aligned ${dir} "** fail ** (output does not match)" ${wrong}
    return 1
  else
    print_right_aligned ${dir} "PASS!" ${right}
    PASS_CNT=`expr $PASS_CNT + 1`
  fi
  return 0
}

function clean_up() {
  rm -f *.class
  rm -f *.txt
}

function print_right_aligned() {
  local file=$1
  file=${file#*/}
  file=${file#*/}
  local result=$2
  local output=$3
  printf "%25s %35s" "${file}..." "${result}"
  if [[ $result = "PASS!" ]]; then
    printf " ${right}\n"
  else
    printf " ${wrong}\n"
  fi
  # printf "                                                              \u2718\n" 
}

function print_header() {
  echo ""
  echo "================================================================"
  echo "                        Running pTest"
  echo "================================================================"
  echo ""
}

print_header
what_was_passed_to_this_script $1
clean_up