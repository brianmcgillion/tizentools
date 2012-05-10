#!/bin/bash

ROOT=`pwd`
MANIFEST="$ROOT/manifest.manifest"
SUCCESS="$ROOT/success.txt"
FAILED_NO_SPEC="$ROOT/failed_no_spec"
EMPTY_SPEC="$ROOT/empty_spec"

function relativepath(){
    python -c "import os.path; print os.path.relpath('$PWD', '$ROOT')";
}

# use the .git directory as a marker to find the relevant projects
# in the directory hierarchy
for dir in $(find $ROOT -name "\.git")
do
    # the parent of the git directory is the base of the project
    cd $dir/..
    count=0
    projectpath=$(relativepath)
    # only if there is a spec file for the project will we continue
    path_names=$(find packaging -name '*.spec' 2> /dev/null)
    for pathname in $path_names
    do
	name=$(basename $pathname ".spec")
	if [ -s $pathname ] ; then
	    sed -i "s/^%files.*$/&\n\%manifest $name\.manifest/" $pathname
	    cp $MANIFEST ./"$name.manifest"
	    # TODO ADD GIT COMMANDS
	    echo $projectpath >> $SUCCESS
	else
	    echo $projectpath >> $EMPTY_SPEC
	fi
	count=$(( count+1 ))
    done
    [ $count -eq 0 ] && echo $projectpath >> $FAILED_NO_SPEC 
done
