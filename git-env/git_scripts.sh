#!/bin/bash

echr() { echo -e '\033[1;31m'"$@"'\033[0m'; }
echb() { echo -e '\033[1;34m'"$@"'\033[0m'; }
echy() { echo -e '\033[1;33m'"$@"'\033[0m'; }

__ugwgit_run_cmd()
{
	local repo_name=$1;
	local repo_path=$2;
	local repo_rev=$3;
	local repo_branch=$4;
	local orig_url=$5;
	local cmd=$6;

	echb "$repo_name (path=${env_root}/ugw/$repo_path/$repo_name)"
	cd "${env_root}/ugw/$repo_path/$repo_name" ; git $cmd ; cd -
}

ugwgit()
{
	#. ${env_root}/build_support/scripts/create_build_workspace.plugin
	local manifest_file="${env_root}/.ugw_ref_states_git"
	echo "manifest file=$manifest_file"
	usage() { echo "Usage: ugwgit <command>"; }
	err() { echo -e '\033[1;31m'"$@"'\033[0m'; usage; }

	local cmd="$@"

	[[ ! -e $manifest_file ]] && err "no subrepos (.ugw_ref_states_git not found), are you in the root folder?" && return
	[[ -z "$cmd" ]] && err "command is empty!!" && return

	echy "Running git $cmd on all repos (manifest file=$manifest_file)"
	while read line; do
		__ugwgit_run_cmd $line $cmd
	done < $manifest_file
}
