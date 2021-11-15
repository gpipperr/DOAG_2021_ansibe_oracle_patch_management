#!/bin/sh
#
#  www.pipperr.de
#
#  Library for the REST API to control Tower
#
#
#
#################  GET Defaults ###################################

################### Prepare Environment ############################

# Home of the scripts
SCRIPTPATH=$(cd ${0%/*} && echo $PWD/${0##*/})
SCRIPTS=`dirname "$SCRIPTPATH{}"`
export SCRIPTS


# get SYSTEMIDENTIFIER 
SYSTEMIDENTIFIER=`ls -l /dev/disk/by-uuid/ | awk '{ print $9 }'  | tail -1`
export SYSTEMIDENTIFIER

############  Helper functions #################################

###############################################################################
# User defaultpassword alternativPasswort
askYesNo() {
  USER_QUESTION=$1
	QUESTION_DEFAULT=$2	
	if [ ! -n "${QUESTION_DEFAULT}" ]; then
	 QUESTION_DEFAULT="NO"
	fi
	LIMIT=10             
	ANSWER_COUNTER=1
	while [ "$ANSWER_COUNTER" -le $LIMIT ]
	do
		printf "   ${USER_QUESTION}   [%s]:" "${QUESTION_DEFAULT}" 
		read YES_NO_ANSWER
		if [ ! -n "${YES_NO_ANSWER}" ]; then
			YES_NO_ANSWER=${QUESTION_DEFAULT}
		fi
		if [ ! -n "${YES_NO_ANSWER}" ]; then
			printError "Please enter a answer for the question :  ${USER_QUESTION}"
		else
		   if [ "${YES_NO_ANSWER}" == 'NO' ]; then
			  break      
			 else
			  if [ "${YES_NO_ANSWER}" == 'YES' ]; then
				 break
				else
				 printError "Please enter as answer YES or NO !"
			  fi	
      fi				
		fi	
		echo -n "$ANSWER_COUNTER "
		let "ANSWER_COUNTER+=1"
	done  
	if [ ! -n "${YES_NO_ANSWER}" ]; then
		printError "Without a answer  for this question ${USER_QUESTION} for you can not install the schema!"
		exit 1
	fi	
}

##########################################################################
# Password file handling
encryptPWDFile () {

PWDFILE=$1

 if [ -f "/usr/bin/openssl" ]; then
		openssl des3 -salt -in  ${PWDFILE} -out ${PWDFILE}.des3 -pass pass:"${SYSTEMIDENTIFIER}" > /dev/null
		#debug printf "%s encrypt file :: \n%s to \n%s.des3 \n" "--" "${PWDFILE}" "${PWDFILE}" 
		#rm ${PWDFILE} 
  else
		printError "Openssl not exits - password file will be not encrypted"
 fi
}
	
dencryptPWDFile() {

PWDFILE=$1

 if [ -f "/usr/bin/openssl" ]; then
	openssl des3 -d -salt -in ${PWDFILE}.des3 -out ${PWDFILE} -pass pass:"${SYSTEMIDENTIFIER}" > /dev/null
  #debug printf "%s decrypt file :: \n%s.des3 to \n%s \n" "--" "${PWDFILE}" "${PWDFILE}" 
 else
  printError "Openssl not exits - password file will be not dencrypted"
 fi  
}

#normal
printLine() {
	if [ ! -n "$1" ]; then
		printf "\033[35m%s\033[0m\n" "----------------------------------------------------------------------------"
	else
		printf "%s" "-- "		
		while [ "$1" != "" ]; do
			printf "%s " $1 
			shift
		done		
		printf  "%s\n" ""
	fi	
}
# 1 Prompt
# 2 list lenght
# 3 seperator
# 4 text

printList() {
	  printf "%s" "    "		
		
		PRINT_TEXT=${1}	
		
		printf "%s" "${PRINT_TEXT}"
		
		STRG_COUNT=${#PRINT_TEXT}	
		
		while [[  ${STRG_COUNT} -lt $2  ]]; do
		 printf "%s" " "
		 let "STRG_COUNT+=1"
	  done
		
		printf "\033[31m%s \033[0m"   "$3"
		printf "\033[32m%s \033[0m\n" "$4"	

}

#red
printError() {
	if [ ! -n "$1" ]; then
		printf "\033[31m%s\033[0m\n" "----------------------------------------------------------------------------"
	else
		printf "\033[31m%s\033[0m" "!! "		
		while [ "$1" != "" ]; do
			printf "\033[31m%s \033[0m" $1 
			shift
		done
		printf  "%s\n" ""
	fi	
}
#green
printLineSuccess() {
	if [ ! -n "$1" ]; then
		printf "\033[32m%s\033[0m\n" "----------------------------------------------------------------------------"
	else
		printf "\033[32m%s\033[0m" "!! "		
		while [ "$1" != "" ]; do
			printf "\033[32m%s \033[0m" $1 
			shift
		done
		printf  "%s\n" ""
	fi	
}

# Trim a string
trimString() {
	TRIMSTRING=${1}
	TRIMSTRING="${TRIMSTRING#"${TRIMSTRING%%[![:space:]]*}"}"   
	TRIMSTRING="${TRIMSTRING%"${TRIMSTRING##*[![:space:]]}"}"   
	echo ${TRIMSTRING}
}

######################## Tower Script parts ###################

deleteHost() {
  
  HOST_NAME=$1
  
  awx hosts list  --conf.insecure -f human --filter id,name,inventory --name ${HOST_NAME}
 
  askYesNo "Delete  this Host from  Tower?" "YES"

  if [ "${YES_NO_ANSWER}" = 'YES' ]; then
    for s in `awx hosts list -f human --name ${HOST_NAME} --filter id --all --conf.insecure | grep -E '[[:digit:]]+' ` ; do
           printLine "ID for Server ${HOSTNAME} is $s"
           printLine "Remove from all inventories"
           awx hosts delete $s --conf.insecure
           printLine "---------------------------"
    done
  else
    printError
    printError "Host ${HOSTNAME} not deleted"
    printError
    exit 1
  fi

}


# Add Host to Group

addHostToGroup() {

HOST_NAME=$1
PROD_INVENTORY=$2



printLine "-------------------------------------------"
printLine "Add host to groups in inventory ${PROD_INVENTORY}"
printLine "-------------------------------------------"


SAVEIFS=$IFS   # Save current IFS
IFS='
'
# Change IFS to new line

ALL_GROUPS=`awx groups list -f human --conf.insecure --filter id,name --inventory ${PROD_INVENTORY}`

for GROUP_INFO in $ALL_GROUPS
do

if [[ "${GROUP_INFO}" =~ ^==.* ]] || [[ "${GROUP_INFO}" =~ ^id.* ]]; then
   echo " "
else

 askYesNo "Add Host ${HOST_NAME} to this group ${GROUP_INFO}" "NO"

 if [ "${YES_NO_ANSWER}" = 'YES' ]; then

   GROUP_ID=`echo ${GROUP_INFO} | cut -d " " -f 1`

   printLine "Add Host ${HOST_NAME} to Group ID ${GROUP_ID}"

   printLine "  Use this url with this payload "
   printLine "  https://localhost/api/v2/groups/${GROUP_ID}/hosts/"
   printLine "  { \"name\" : \"${HOST_NAME}\" , \"inventory\" : \"${PROD_INVENTORY}\" }"

   echo { \"name\" : \"${HOST_NAME}\" , \"inventory\" : \"${PROD_INVENTORY}\" } > grpData.json
    #--trace-ascii /dev/stdout
   curl -k -s -H "Authorization: Bearer $TOWER_OAUTH_TOKEN" -H "Connection: close"  -X POST -H "Content-Type: application/json"   "https://localhost/api/v2/groups/${GROUP_ID}/hosts/"  --data  @grpData.json

  printLine

 fi
fi

done

IFS=$SAVEIFS   # Restore IFS


}
