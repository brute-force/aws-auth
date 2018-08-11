#!/bin/bash

function usage () {
   cat <<EOF

Usage: $0 options

options:
   -m   arn of your virtual mfa device
EOF
   exit
}

while getopts "m:" OPTION
do
  case $OPTION in
    m)
      mfa_serial_number=$OPTARG
      ;;
    *)
      usage;
      exit 1
      ;;
  esac
done

if [ ! "$mfa_serial_number" ]
then
  usage
  exit 1
else
  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
  unset AWS_SESSION_TOKEN

  token_code=$(ykman oath code | perl -pe "s/.* +(\d+)$/\1/g;")
  echo "token code: $token_code"

  output=$(aws sts get-session-token --serial-number $mfa_serial_number --token-code $token_code)
  echo "output: $output"

  aws_access_key_id=$(echo $output | perl -pe "s/.*AccessKeyId\": \"([^\"]+)\".*/\1/g;")
  aws_secret_access_key=$(echo $output | perl -pe "s/.*SecretAccessKey\": \"([^\"]+)\".*/\1/g;")
  aws_session_token=$(echo $output | perl -pe "s/.*SessionToken\": \"([^\"]+)\".*/\1/g;")

  export AWS_ACCESS_KEY_ID=$aws_access_key_id
  export AWS_SECRET_ACCESS_KEY=$aws_secret_access_key
  export AWS_SESSION_TOKEN=$aws_session_token

  echo "AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID"
  echo "AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY"
  echo "AWS_SESSION_TOKEN: $AWS_SESSION_TOKEN"
fi

