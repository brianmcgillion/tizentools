#!/bin/bash

ROOT=`pwd`
MANIFEST="$ROOT/manifest.manifest"
SUCCESS="$ROOT/success.txt"
FAILED_MULTIPLE_PACKAGES="$ROOT/failed_multiple_packages"
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
    projectpath=$(relativepath)
    # only if there is a spec file for the project will we continue
    if [ -e packaging/*.spec ] ; then
	pathname=$(find packaging -name '*.spec')
	name=$(basename $pathname ".spec")
	if [ -s $pathname ] ; then
	    if [ `grep -c "^%files\s*\(-f.*\)*$" $pathname` -eq 1 ] ; then
		sed -i "s/^%files\s*\(-f.*\)*$/&\n\%manifest $name\.manifest/" $pathname
		cp $MANIFEST ./"$name.manifest"
	    # TODO ADD GIT COMMANDS
		echo $projectpath >> $SUCCESS
	    else
		echo $projectpath >> $FAILED_MULTIPLE_PACKAGES
	    fi
	else
	    echo $projectpath >> $EMPTY_SPEC
	fi
    else
	echo $projectpath >> $FAILED_NO_SPEC 
    fi
done
