#!/bin/bash
#
#  This is a file to run BMXNET Broker as a Linux service
#
export HOME=/home/foia
export REMOTE_HOST=`echo $REMOTE_HOST | sed 's/::ffff://'`
source $HOME/etc/env

LOG=$HOME/log/bmxnet.log

echo "$$ Job begin `date`"                                      >>  ${LOG}
echo "$$  ${gtm_dist}/mumps -run XINETD^BMXMON"                 >>  ${LOG}

${gtm_dist}/mumps -run XINETD^BMXMON                           2>>  ${LOG}
echo "$$  BMXNET Broker stopped with exit code $?"              >>  ${LOG}
echo "$$ Job ended `date`"
