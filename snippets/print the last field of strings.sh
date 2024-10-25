#!/usr/bin/sh

# Ordered best to worst experience

echo "string/with/delimiters" | awk -F '/' '{print $NF}'
echo "string/with/delimiters" | sed 's|^.*/||'
echo "string/with/delimiters" | choose -f '/' -1
echo "string/with/delimiters" | grep -o --color='never' '[^/]*$'
echo "string/with/delimiters" | perl -pe 's|(.*)/(.*)$|$2|' -
echo "string/with/delimiters" | tr '/' '\n' | tail -n1
echo "string/with/delimiters" | rev | cut -d '/' -f '1' | rev
