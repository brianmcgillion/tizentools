#!/bin/bash

ROOT=`pwd`
MANIFEST="$ROOT/manifest.manifest"
SUCCESS="$ROOT/success.txt"
FAILED_MULTIPLE_PACKAGES="$ROOT/failed_multiple_packages"
FAILED_NO_SPEC="$ROOT/failed_no_spec"

# use the .git directory as a marker to find the relevant projects
# in the directory hierarchy
for dir in $(find $ROOT -name "\.git")
do
    pushd $ROOT
    # the parent of the git directory is the base of the project
    cd $dir/..
    # only if there is a spec file for the project will we continue
    if [ -e packaging/*.spec ] ; then
	pathname=$(find packaging -name '*.spec')
	name=$(basename $pathname)
	name=${name%.*}
	if [ `grep -c "^\%files\s*$" $pathname` -eq 1 ] ; then
	    sed -i "s/^\%files\s*$/%files\n\%manifest $name\.manifest/" $pathname
	    cp $MANIFEST ./"$name.manifest"
	    # TODO ADD GIT COMMANDS
	    echo "$name" >> $SUCCESS
	else
	    echo "$name" >> $FAILED_MULTIPLE_PACKAGES
	fi
    else
	echo `pwd` >> $FAILED_NO_SPEC 
    fi
    # go back to the base directory
    popd
done

