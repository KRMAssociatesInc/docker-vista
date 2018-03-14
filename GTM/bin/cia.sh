#!/bin/bash
#
#  This is a file to run CIA Broker as a Linux service
#
export HOME=/home/foia
export REMOTE_HOST=`echo $REMOTE_HOST | sed 's/::ffff://'`
source $HOME/etc/env

LOG=$HOME/log/cia.log

echo "$$ Job begin `date`"                                      >>  ${LOG}
echo "$$  ${gtm_dist}/mumps -run %XCMD 'D EN^CIANBLIS(9100,\$ztrnlnm(\"REMOTE_HOST\"),2)'"                >>  ${LOG}
${gtm_dist}/mumps -run %XCMD 'D EN^CIANBLIS(9100,$ztrnlnm("REMOTE_HOST"),2)'         2>>  ${LOG}
echo "$$  CIA Broker stopped with exit code $?"                  >>  ${LOG}
echo "$$ Job ended `date`"
