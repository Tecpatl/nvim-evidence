script_dir=$(
	cd $(dirname $0)
	pwd
)

root_dir=$(git rev-parse --show-toplevel)
cd ${root_dir}

common_file="${script_dir}/common.sh"
source $common_file

echo_help() {
	show_danger "Usage: $0 [-a all] [-f path]"
	exit 1
}

default_path=${root_dir}/lua/evidence/tests/

min_vim="${root_dir}/scripts/minimal_init.vim"

while getopts 'af:' OPT; do
	case $OPT in
	a)
    exec_and_check "nvim --headless --noplugin -u ${min_vim} -c \"PlenaryBustedDirectory ${default_path} { minimal_init = '${min_vim}' }\" "
    exit 0
    ;;
	f) 
    file_name="$OPTARG" 
    exec_and_check "nvim --headless --noplugin -u ${min_vim} -c \"PlenaryBustedFile ${default_path}${file_name}\" "
		;;
	?) echo_help ;;
	esac
done
