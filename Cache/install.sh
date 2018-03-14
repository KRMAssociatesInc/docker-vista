#!/usr/bin/env bash
#---------------------------------------------------------------------------
# Copyright 2011-2012 The Open Source Electronic Health Record Agent
# Copyright 2017 Christopher Edwards
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#---------------------------------------------------------------------------

# Installs Intersystems Caché in an automated way
# This utility requires root privliges

# Make sure we are root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

# Options
# used http://rsalveti.wordpress.com/2007/04/03/bash-parsing-arguments-with-getopts/
# for guidance

usage()
{
    cat << EOF
    usage: $0 options

    This script will install Caché and create a VistA instance

    OPTIONS:
      -h    Show this message
      -f    Skip setting firewall rules
      -i    Instance name
EOF
}

while getopts ":hfi:" option
do
    case $option in
        h)
            usage
            exit 1
            ;;
        f)
            firewall=false
            ;;
        i)
            instance=$(echo $OPTARG |tr '[:upper:]' '[:lower:]')
            ;;
    esac
done

if [[ -z $instance ]]; then
    usage
    exit 1
fi

if [[ -z $firewall ]]; then
    firewall=true
fi

# hack for CentOS
cp /etc/redhat-release /etc/redhat-release.orig
echo "Red Hat Enterprise Linux (Santiago) release 6" > /etc/redhat-release

# Need to know where script was ran from
scriptdir=`dirname $0`

# BaseDir
basedir=/opt/cachesys/$instance

# Create Daemon User accounts
./createDaemonAccount.sh -i $instance

usermod root -G cachegrp$instance

# unzip the cachekit in a temp directory
cachekit=$(ls -1 /opt/vista/cache-*.tar.gz)
echo "Using cache installer: $cachekit"
tempdir=/tmp/cachekit
mkdir $tempdir
chmod og+rx $tempdir
pushd $tempdir
tar xzf $cachekit

# Create environment variables for install
export ISC_PACKAGE_INITIAL_SECURITY="minimal"
export ISC_PACKAGE_MGRUSER=cacheusr$instance
export ISC_PACKAGE_MGRGROUP=cachegrp$instance
export ISC_PACKAGE_INSTANCENAME=CACHE
export ISC_PACKAGE_INSTALLDIR=$basedir
export ISC_PACKAGE_CACHEUSER=cacheusr$instance
export ISC_PACKAGE_CACHEGROUP=cachegrp$instance
export ISC_PACKAGE_STARTCACHE="N"

# Install Caché
if [ -e cinstall_silent ]; then
    ./cinstall_silent
else
    # the cachekit has a subdirectory before we can find cinstall_silent
    cd $(ls -1)
    ./cinstall_silent
fi

popd
if [ -e /opt/vista/cache.key ]; then
    cp /opt/vista/cache.key $basedir/mgr
fi

# Perform subsitutions in cpf file and copy to destination
cp $scriptdir/cache.cpf $basedir/cache.cpf-new
perl -pi -e 's/foia/'$instance'/g' $basedir/cache.cpf-new
perl -pi -e 's/FOIA/'${instance^^}'/g' $basedir/cache.cpf-new

# Move CACHE.dat
mkdir -p $basedir/vista
if [ -e /opt/vista/CACHE.DAT ]; then
    mv /opt/vista/CACHE.DAT $basedir/vista/CACHE.DAT
    chown root:cachegrp$instance $basedir/vista/CACHE.DAT
    chmod ug+rw $basedir/vista/CACHE.DAT
    chmod ug+rw $basedir/vista
fi

# Clean up from install
cd $scriptdir
rm -rf $tempdir
mv /etc/redhat-release.orig /etc/redhat-release

# create startup script used by docker
echo "#!/bin/bash"                                      > $basedir/bin/start.sh
echo 'trap "ccontrol stop CACHE quietly" SIGTERM'       >> $basedir/bin/start.sh
echo 'echo "Starting sshd"'                             >> $basedir/bin/start.sh
echo "/usr/sbin/sshd"                                   >> $basedir/bin/start.sh
echo 'echo "Starting vista processes"'                  >> $basedir/bin/start.sh
echo 'cp '${basedir}'/cache.cpf '${basedir}'/cache.cpf-old' >> $basedir/bin/start.sh
echo 'rm '${basedir}'/cache.cpf_*'                      >> $basedir/bin/start.sh
echo 'cp '${basedir}'/cache.cpf-new '${basedir}'/cache.cpf' >> $basedir/bin/start.sh
echo 'find '${basedir}'/ -iname CACHE.DAT -exec touch {} \;' >>$basedir/bin/start.sh
echo "ccontrol start CACHE"                             >> $basedir/bin/start.sh
echo '# Create a fifo so that bash can read from it to' >> $basedir/bin/start.sh
echo '# catch signals from docker'                      >> $basedir/bin/start.sh
echo 'rm -f ~/fifo'                                     >> $basedir/bin/start.sh
echo 'mkfifo ~/fifo || exit'                            >> $basedir/bin/start.sh
echo 'chmod 400 ~/fifo'                                 >> $basedir/bin/start.sh
echo 'read < ~/fifo'                                    >> $basedir/bin/start.sh

# Ensure correct permissions for start.sh
chown cacheusr$instance:cachegrp$instance $basedir/bin/start.sh
chmod +x $basedir/bin/start.sh
