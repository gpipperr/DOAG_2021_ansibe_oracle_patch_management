#!/bin/sh
#
#  www.pipperr.de
#  see https://www.pipperr.de/dokuwiki/doku.php?id=linux:ansible_tower_cli_awx
#
# List  Tower Inventory


#
# set the securtiy tocken
. ~/.sec_token


#
awx  inventory  list -f human --conf.insecure

