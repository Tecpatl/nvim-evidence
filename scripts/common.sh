#!/bin/bash

show_msg() {
	echo -e "\033[1;36m$1\033[0m"
}

show_info() {
	echo -e "\033[1;32m$1\033[0m"
}

show_warning() {
	echo -e "\033[1;33m$1\033[0m"
}

show_error() {
	echo -e "\033[1;31m$1\033[0m"
}

show_danger() {
	echo -e "\033[1;31m$1\033[0m"
}

exec_and_check() {
	show_msg "${1}"

	eval ${1}

	if [[ $? -ne 0 ]]; then
		show_error "'${1}' failed"
		exit 1
	fi
}

exec_and_check_no_exit() {
	show_msg "${1}"

	eval ${1}

	if [[ $? -ne 0 ]]; then
		show_error "'${1}' failed"
	fi
}

exec_and_check_with_time() {
	show_info "TASK_START: ${1}"

	local exec_start_time=$(date +%s)
	eval ${1}
	local exec_end_time=$(date +%s)

	local exec_cost_time=$(($exec_end_time - $exec_start_time))
	show_info "TASK_TIME_COST $(($exec_cost_time / 60))min $(($exec_cost_time % 60))s: ${1}"

	if [[ $? -ne 0 ]]; then
		show_error "'${1}' failed"
		exit 1
	fi
}

