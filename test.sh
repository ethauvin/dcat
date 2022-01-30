#!/bin/bash

TMPCAT=/tmp/tmp-cat
TMPDCAT=/tmp/tmp-dcat
RED='\033[0;31m'
GREEN='\033[0;32m'

checkDiff () {
    if  ! $(cmp -s $TMPCAT $TMPDCAT);
    then
        echo -e "${RED}Test failed: $1" >&2
        exit
    fi  
}

for o in '' -A -b -e -E -n -s -t -T -v '-Abs'
do
    echo -e "Testing: cat $o"
    cat $o test/* > $TMPCAT
    bin/dcat $o test/* > $TMPDCAT
    checkDiff "cat $o"
done

echo -e "Testing: cat -"
echo "This is a test" | cat - test/* > $TMPCAT
echo "This is a test" | bin/dcat - test/* > $TMPDCAT
checkDiff "cat -"

rm -rf $TMPCAT $TMPDCAT

echo -e "${GREEN}All tests passed."
