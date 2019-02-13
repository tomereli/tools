#!/bin/bash

me=`basename $0`

function good_message_example()
{
cat << EOF
Git message format - pay attention that line should be shorter than 72 chars:
------------------------------------------------------------
head line

body line 1
body line 2
body line 3
...

Change-Id: <hash>
Signed-off-by: <full user name> <userlogin@intel.com>
------------------------------------------------------------
EOF
}

function rule_violation(){
hash=${1:-'HEAD'}
cat_file=$(git cat-file -p $hash)
if [ $? -ne 0 ];then
	echo "$me failed on \"git cat-file -p $hash\""
	exit 1
fi
echo "$cat_file" | awk '
	BEGIN{ len = 0; change_id = 0; signed = 0 };
	NR < 6 { next };
	# keep line length, number of words and full string
	{len = length($0); num_words[NR] = NF; line[NR] = $0}
	{if (len > 72 && $0 !~ /Signed-off-by:/) {print "line length "len" > 72 :" "\""$0"\""};}
	NR == 6 && /^[[:blank:]]/ {print "No spaces allowed in the start of HEADLINE : " "\""$0"\""}
	# NR 7 is a line after headline
	NR == 7 {
		if (NF != 0){print "Expected blank line after HEADLINE instead of: " "\""$0"\""}
	}

	$1 ~ /^Change-Id:/ {change_id = NR;
		if (signed){print "Signed-off-by: should appear after Change-Id: : " "\""$0"\""}
		# Message Body should be followed by blank line
		if (num_words[NR-1]){
			print "Expected blank line before Change-Id: instead of: " "\""line[NR-1]"\"" }
		}
	$1 ~ /^Signed-off-by:/{signed = NR}
	END {
		if (!signed){print "Missing Signed-off-by:"}
		if (!change_id){print "Missing Change-Id:"}
	}
'
}

eval $1 $2


