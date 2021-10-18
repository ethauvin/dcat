#!/bin/bash

TMPCAT=/tmp/tmp-cat
TMPDCAT=/tmp/tmp-dcat
RED='\033[0;31m'
GREEN='\033[0;32m'

for o in -A -b -e -E -n -s -t -T -v
do
    cat $o test/* > $TMPCAT
    bin/dcat $o test/* > $TMPDCAT
    if  ! $(diff -q $TMPCAT $TMPDCAT);
    then
        echo -e "${RED}Test failed: $o" >&2
        exit
    fi
done

rm -rf $TMPCAT $TMPDCAT

echo -e "${GREEN}All tests passed."
