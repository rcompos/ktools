#!/usr/bin/env bash
# Decode kubernetes secrets yaml

SECRETS_FILE=${SECRETS_FILE}
DBUG=${DBUG:-""}

if [[ $# -gt 1 ]]; then
  echo "Decode kubernetes secrets yaml from file or stdin"
  echo "Usage:  $0 [secrets_file]"
  echo "  Supply optional file name for Kubernetes secrets yaml as" 
  echo "  command-line argument or as environmental variable SECRETS_FILE"
  echo 
  echo "Example:  kubectl get secret mysecret -o yaml | $0"
  echo "Example:  cat secrets_file | $0"
  echo "Example:  $0 < \`echo secrets_file\`"
  exit 1
fi

SECRETS_FILE=${1--}

data=""
i=0
while IFS= read -r line; do
  if [ "$DBUG" != "" ]; then
    echo "${i}> $line"
  fi
  i=$(( $i + 1 ))
  data_match=`echo $line | perl -ne 'print if /^data:/'`
  if [ "$data_match" != "" ]; then
    data="true"
    echo "$line"
    continue
  fi
  if [ "$data" != "" ]; then 
    # in data section
    #echo "b> "
    data_line=`echo "$line" | perl -ne 'print if /^\s+\S/'`
    if [ "$data_line" != "" ]; then
      # still in data section
      key=`echo "$line" | cut -d: -f 1`
      value=`echo "$line" | cut -d: -f 2`
      echo -n "$key: "; echo "$value" | perl -pe 's/^\s+//' | base64 -d; echo
    else
      #echo "c> "
      # out of data section
      data=""
      echo "$line"
    fi
  else 
    echo "$line"
  fi
done < <(cat -- "$SECRETS_FILE")
