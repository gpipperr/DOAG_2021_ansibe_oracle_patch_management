#!/bin/sh
#
#  www.pipperr.de
#  see https://www.pipperr.de/dokuwiki/doku.php?id=linux:ansible_tower_cli_awx
#

# Login to Tower
#
# ==============================

############### source the helper functions ######################
. tower_lib.sh


# read the password file
CONFFILE=${SCRIPTS}/tower_login.conf


if [ -f "${CONFFILE}.des3" ]; then
        dencryptPWDFile ${CONFFILE}
        . ${CONFFILE}
        rm ${CONFFILE}
else
  if [ -f "${CONFFILE}" ]; then
        . ${CONFFILE}
        encryptPWDFile ${CONFFILE}
   else
        printError
        printError "No preconfiguration ${CONFFILE} found!"
        echo export TOWER_USERNAME=admin > ${CONFFILE}
        echo export TOWER_PASSWORD=xxxxx >> ${CONFFILE}
        printError "Add username and password file to ${CONFFILE}"
        printError
   exit 1
   fi
fi


#################################################################
printLine  "-------------------------------------------------"
printLine  " Try to Login to tower with the login data from ${CONFFILE}"

################################################################


# Login
$(TOWER_USERNAME=$TOWER_USERNAME TOWER_PASSWORD=$TOWER_PASSWORD awx login -f human --conf.insecure )


if [ $? -eq 0 ]
then

 # Store the Secure Tocken to login to tower
 echo export TOWER_OAUTH_TOKEN=$TOWER_OAUTH_TOKEN > ~/.sec_token
 
 # Test Connection
 #awx config --conf.insecure > /dev/null

 printLineSuccess
 printLine "Success full login to tower"
 printLineSuccess
else
 printError
 printError "Error to login to tower, check username and password, if wrong recreate the file ./${CONFFILE}"
 printError TOWER_USERNAME=$TOWER_USERNAME
 printError TOWER_PASSWORD=$TOWER_PASSWORD
 printError
fi


