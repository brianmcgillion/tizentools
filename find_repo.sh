#!/bin/bash

ROOT=`pwd`
MANIFEST="$ROOT/manifest.manifest"
SUCCESS="$ROOT/success.result"
FAILED_NO_SPEC="$ROOT/failed_no_spec.result"
EMPTY_SPEC="$ROOT/empty_spec.result"
ALREADY_DONE="$ROOT/already_done.result"

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
	manifest_dst="packaging/$name.manifest"
	# if a manifest exists assume we have already done the work on this package.
	if [ -e $manifest_dst ] ; then
	    echo $projectpath >> $ALREADY_DONE
	    continue
	fi
	# make sure the spec file is not empty
	if [ -s $pathname ] ; then
	    # The dirtiest hack that I could come up with without writing real code :)
	    tac $pathname | sed "0,/^Source/ { /^Source/i \
Source1001: $manifest_dst 
}" | tac > tmp.spec ; mv tmp.spec $pathname
	    
	    sed -i '/^%build/ a \
cp %{SOURCE1001} .' $pathname
	    sed -i "/^%files/ a \
%manifest $name\.manifest" $pathname
	    cp $MANIFEST ./"$manifest_dst"
	    git add "$manifest_dst" "$pathname"
	    git commit -s -m "Add default Smack manifest for $name.spec"
	    echo $projectpath >> $SUCCESS
	else
	    echo $projectpath >> $EMPTY_SPEC
	fi
	count=$(( count+1 ))
    done
    [ $count -eq 0 ] && echo $projectpath >> $FAILED_NO_SPEC 
done
