#!/bin/sh

#
#  www.pipperr.de
#  see https://www.pipperr.de/dokuwiki/doku.php?id=linux:ansible_tower_cli_awx
#
# List  Tower hosts

#
# set the securtiy tocken
. ~/.sec_token

################################
usage() { echo "Usage: `basename $0` options -i <inventory nr> / use -h for help"; exit 1; }

###############################
typeset COMMAND_PARAM=":i:h"
 
# falls nicht übergeben wurden mit exit beenden
if ( ! getopts "${COMMAND_PARAM}" opt); then
   usage
fi
 
# Parameter auswerten
 
while getopts "${COMMAND_PARAM}"  opt; do
  case $opt in
    i)
      echo "-i was triggered, Parameter: $OPTARG " >&2
      inventory=${OPTARG}
      ;;
    h)
      echo "-h was triggered, call help" >&2
      usage
      exit 1
      ;;  
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

########################

echo --------------------------------
echo List all hosts from Inventory $inventory
echo --------------------------------

awx hosts list   -f human  --filter name,id,inventory,enabled --inventory $inventory  --all --conf.insecure
#awx hosts list   --inventory $inventory  --all --conf.insecure
