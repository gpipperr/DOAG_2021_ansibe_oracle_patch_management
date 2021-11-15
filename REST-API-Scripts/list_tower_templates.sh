#!/bin/sh
#
#  www.pipperr.de
#  see https://www.pipperr.de/dokuwiki/doku.php?id=linux:ansible_tower_cli_awx
#
#  display all tower templates

#  set the securtiy tocken
#
. ~/.sec_token


## 
awx job_templates list  --conf.insecure -all -f human

