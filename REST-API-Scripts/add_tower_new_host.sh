#!/bin/sh
#
#
#  www.pipperr.de
#  see https://www.pipperr.de/dokuwiki/doku.php?id=linux:ansible_tower_cli_awx
#
################# add new Host to tower ##########################
#
#  Add new Host to the Tower enviroment
#
##################################################################


############### source the helper functions ######################
. tower_lib.sh


#################################################################
# set the securtiy tocken
. ~/.sec_token


#################################################################

# read the tower setup
TOWERCONFFILE=${SCRIPTS}/tower.conf
. ${TOWERCONFFILE}

# read the last config
CONFFILE=${SCRIPTS}/add_host.conf

if [ -f "${CONFFILE}.des3" ]; then
    dencryptPWDFile ${CONFFILE}
	. ${CONFFILE}
	rm ${CONFILE}
else
   if [ -f "${CONFFILE}" ]; then
        . ${CONFFILE}
	   rm ${CONFFILE}
     else
	   printLine "no preconfiguration add_host.conf found"
   fi
fi


#################################################################
printLine  "-------------------------------------------------"
printLine  "Welcome to add new host to tower"
printLine  "-------------------------------------------------"

################################################################
# Enter the Hostname

printf "Please enter the Name of the Host  you like to add [%s]:" "${S_HOST_NAME}"
read HOST_NAME
if [ ! -n "${HOST_NAME}" ]; then
	HOST_NAME=${S_HOST_NAME}
fi


printf "Please enter the Description of the Host ${HOST_NAME}  [%s]:" "${S_HOST_DESCRIPTION}"
read HOST_DESCRIPTION
if [ ! -n "${HOST_DESCRIPTION}" ]; then
        HOST_DESCRIPTION=${S_HOST_DESCRIPTION}
fi



printf "Please enter the Root password of the host you like to add [%s]:" "${S_ROOT_PWD}"
read ROOT_PWD
if [ ! -n "${ROOT_PWD}" ]; then
        ROOT_PWD=${S_ROOT_PWD}
fi

###########################################################
#
# check the inputs
#
printLine
printLine "Start to check the Hostname and the root Password ......"
sshpass -p ${ROOT_PWD} ssh -o StrictHostKeyChecking=no root@${HOST_NAME} hostname

if [ $? -eq 0 ]
then
 printLineSuccess
 printLine "Host exits and Root Password is valid"
 printLineSuccess
else
 printError
 printError "Host ${HOST_NAME} not reachable with ssh or wrong password"
 printError
 exit 1 
fi

# Check if the host still exits in Tower
printLine
printLine "Check if the host is configured in Tower "

awx hosts list  --conf.insecure -f human --filter id,name,inventory --name ${HOST_NAME}

awx hosts list  --conf.insecure -f human --filter id,name,inventory --name ${HOST_NAME} | grep ${HOST_NAME} > /dev/null

if [ $? -eq 1 ]
then
 printLineSuccess
 printLine "Host not exits and can be added"
 printLineSuccess
else
 printError
 printError "Host ${HOST_NAME} still exists, please remove the host"
 deleteHost ${HOST_NAME}
 printError
fi


####
# add the host to the install inventory
# Remember last values
echo "#actual Host config"> ${CONFFILE}

echo export S_HOST_NAME=${HOST_NAME}                >> ${CONFFILE}
echo export S_HOST_DESCRIPTION=${HOST_DESCRIPTION}  >> ${CONFFILE}
echo export S_ROOT_PWD=${ROOT_PWD}                  >> ${CONFFILE}


# encrypt the password in the files
encryptPWDFile ${CONFFILE}

#
# Create the hostvar file
echo --- > host_vars_toset.yml
echo ansible_connection: ssh  >> host_vars_toset.yml
echo ansible_ssh_user: root   >> host_vars_toset.yml
echo ansible_ssh_pass: ${ROOT_PWD} >> host_vars_toset.yml

printLine  "-------------------------------------------------"
printLine  "Start to add new host to tower"
printLine  "Hostname    : ${HOST_NAME}"
printLine  "Description : ${HOST_DESCRIPTION}"
printLine  "-------------------------------------------------"

askYesNo "Add this Host to Tower?" "YES"

if [ "${YES_NO_ANSWER}" = 'YES' ]; then
 printLine  ""
else
 printError
 printError "Host not added"
 printError
 exit 1
fi


awx host create --conf.insecure --name ${HOST_NAME} -f human  --inventory ${INSTALL_INVENTROY} --description ${HOST_DESCRIPTION} --variables @./host_vars_toset.yml

#rm -f ./host_vars_toset.yml

#
# Call Playbooks to add this host
#

awx job_templates launch --monitor --conf.insecure --wait  --inventory ${INSTALL_INVENTROY} ${CREATE_ANSIBLE_PLAYBOOK}


awx job_templates launch --monitor --conf.insecure --wait   --inventory ${INSTALL_INVENTROY} ${ENABLE_SSH_ACCESS}


printLine "-------------------------------------------"
printLine "Check output"
printLine "-------------------------------------------"


askYesNo "Remove the Host from install inventory and add to production" "YES"

if [ "${YES_NO_ANSWER}" = 'YES' ]; then
  printLine  ""
else
  printError
  printError "Host must be added manually"
  printError
  exit 1
fi


# Remove host from install inventory

awx host delete --conf.insecure --name ${HOST_NAME} -f human

printLine "-------------------------------------------"
printLine "Add to produktion inventory"
printLine "-------------------------------------------"


# Add Host to Prod inventory

awx host create --conf.insecure --name ${HOST_NAME}  -f human --inventory ${PROD_INVENTORY} --description ${HOST_DESCRIPTION} 



#######################################################
# Add Host to Group

addHostToGroup $HOST_NAME $PROD_INVENTORY

########################################################

printLineSuccess "-------------------------------------------"
printLineSuccess "Finsh to add host ${HOST_NAME}"
printLineSuccess "-------------------------------------------"

############### Finish Script ##########################




