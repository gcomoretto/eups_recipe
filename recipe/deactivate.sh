# unsetup any products to keep env clean
# topological sort makes it faster since unsetup works on deps too
pkgs=`eups list -s --topological -D 2>/dev/null | sed 's/|//g' | awk '{ print $1 }'`
while [[ $pkgs ]]; do
    for pkg in ${pkgs}; do
        if [[ ${pkg} == "eups" ]]; then
           continue
        fi
        unsetup $pkg >/dev/null 2>&1
        break
    done
    pkgs=`eups list -s --topological -D 2>/dev/null | sed 's/|//g' | awk '{ print $1 }'`
    if [[ ${pkgs} == "eups" ]]; then
        break
    fi
done

# it stops at eups so we get the rest in a list
pkgs=`eups list -s 2>/dev/null | sed 's/|//g' | awk '{ print $1 }'`
for pkg in ${pkgs}; do
    if [[ ${pkg} == "eups" ]]; then
       continue
    fi
    unsetup $pkg >/dev/null 2>&1
done

# clean out the path, removing EUPS_DIR/bin
# https://stackoverflow.com/questions/370047/what-is-the-most-elegant-way-to-remove-a-path-from-the-path-variable-in-bash
# we are not using the function below because this seems to mess with conda's
# own path manipulations
WORK=:$PATH:
REMOVE=":${EUPS_DIR}/bin:"
WORK=${WORK//$REMOVE/:}
WORK=${WORK%:}
WORK=${WORK#:}
export PATH=$WORK

# remove EUPS vars
for var in EUPS_PATH EUPS_SHELL SETUP_EUPS EUPS_DIR; do
    unset $var
done
