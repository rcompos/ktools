#!/usr/bin/env bash
# Decode kubernetes secrets yaml

DBUG=${DBUG:-""}

if [[ $# -gt 1 ]]; then
  echo "Decode kubernetes secrets yaml from file or stdin"
  echo "Usage:  $0 [secrets_file]"
  echo "  Supply optional file name for Kubernetes secrets"
  echo "  yaml as command-line argument" 
  echo 
  echo "Example:  kubectl get secret dummy-secret -o yaml | $0"
  echo "Example:  cat dummy-secret.yaml | $0"
  echo "Example:  $0 < \`echo dummy-secret.yaml\`"
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
    echo "stringData:"
    continue
  fi
  if [ "$data" != "" ]; then # in data section
    data_line=`echo "$line" | perl -ne 'print if /^\s+\S/'`
    if [ "$data_line" != "" ]; then
      # still in data section
      key=`echo "$line" | cut -d: -f 1`
      value=`echo "$line" | cut -d: -f 2`
      plaintext=`echo "$value" | perl -pe 's/^\s+//' | base64 -d`
      echo  "$key: \"$plaintext\""
    else # out of data section
      data=""
      echo "$line"
    fi
  else 
    echo "$line"
  fi
done < <(cat -- "$SECRETS_FILE")

