#! /bin/sh

#
#  www.pipperr.de
#  see https://www.pipperr.de/dokuwiki/doku.php?id=linux:ansible_tower_cli_awx
#

# Remove a list of servers from tower
#
#

############### source the helper functions ######################
. tower_lib.sh


# set the securtiy tocken
. ~/.sec_token



################################
usage() { echo "Usage: `basename $0` options -s <hostname list with  , as seperator like a,b,c> / use -h for help"; exit 1; }

###############################
typeset COMMAND_PARAM=":s:h"

# falls nicht übergeben wurden mit exit beenden
if ( ! getopts "${COMMAND_PARAM}" opt); then
   usage
fi

# Parameter auswerten

while getopts "${COMMAND_PARAM}"  opt; do
  case $opt in
    s)
      echo "-s was triggered, Parameter: $OPTARG " >&2
      SERVER_INPUT=${OPTARG}
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
# create server list
delimiter=,
s=$SERVER_INPUT$delimiter

SERVER_LIST=();

while [[ $s ]]; do
    SERVER_LIST+=( "${s%%"$delimiter"*}" );
    s=${s#*"$delimiter"};
done;


#################### 

printLine

askYesNo "Remove this list of Host ${SERVER_INPUT} from Tower?(Please typ YES if you like to delete!)" "NO"

if [ ! -n "${YES_NO_ANSWER}" ]; then
            YES_NO_ANSWER=NO
fi

if [ "${YES_NO_ANSWER}" == 'YES' ]; then


 for i in ${SERVER_LIST[*]}; do   
        printLine "Get ID for Server $i"
        TOWER_SRV_LST=`awx hosts list -f human --name $i --filter id --all --conf.insecure | grep -E '[[:digit:]]+' `
	
       if [ ! -n "${TOWER_SRV_LST}" ]; then
         printError "ID for Server $i not found, not exits in Tower?"  
       else  
         for s in ${TOWER_SRV_LST} ; do
             printLine "ID for Server $i is $s"
	     printLine "Remove  $i from all inventories"
	     awx hosts delete $s --conf.insecure
             printLine	     
         done
      fi    	
 done

else
 printLine "No Hosts to delete" 
fi

printLine

