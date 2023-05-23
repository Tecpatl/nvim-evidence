script_dir=$(
	cd $(dirname $0)
	pwd
)

input_file="${script_dir}/deck.json"
#output_file="./out.csv"
output_file="${script_dir}/anki.lua"

now_timestamp=$(date +%s)

echo "{" >$output_file

id=0

sed -i "/sound.*mp3/d" ${input_file}
#jq -r '[.notes[] | "* "+.fields[0] + "\n\n** answer\n\n" + [.fields | join("\n")][0] ]' $input_file |
jq -r '[.notes[] | "# "+.fields[0] + "\n\n## answer\n\n" + [.fields | join("\n")][0] ]' $input_file |
	while read -r first; do
		if [[ $first != "[" && $first != "]" ]]; then
			#id=$(($id + 1))
			#x="$(echo $first | sed 's/,$//g;s/"/""/g;s/[^\t]*/"&"/g')"
			#x="$(echo $first | sed 's/,$//g;s/\\"/""/g;')"
			x="$(echo $first)"
			echo "$x" >>$output_file
		fi
	done

echo "}" >>$output_file
# import
# sqlite3 -header -csv ./sql/v1 ".import /home/oyjy/workspace/project/anki/out.csv toefl"

# export
# sqlite3 -header -csv ./sql/v1 "select * from entries;" > ./test.csv
