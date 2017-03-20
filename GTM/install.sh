#!/usr/bin/env bash
#---------------------------------------------------------------------------
# Copyright 2011-2012 The Open Source Electronic Health Record Agent
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

# Install GT.M using gtminstall script
# This utility requires root privliges

# Make sure we are root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

# Options
# instance = name of instance
# used http://rsalveti.wordpress.com/2007/04/03/bash-parsing-arguments-with-getopts/
# for guidance

usage()
{
    cat << EOF
    usage: $0 options

    This script will automatically install GT.M

    DEFAULTS:
      GT.M Version = V6.2-000

    OPTIONS:
      -h    Show this message
      -s    Skip setting shared memory parameters
      -v    GT.M version to install

EOF
}

while getopts ":hsv:" option
do
    case $option in
        h)
            usage
            exit 1
            ;;
        s)
            sharedmem=false
            ;;
        v)
            gtm_ver=$OPTARG
            ;;
    esac
done

# Set defaults for options
if [ -z $gtm_ver ]; then
    gtm_ver=V6.2-000
fi

if [ -z $sharedmem ]; then
    sharedmem=true
fi

# Download gtminstall script from SourceForge
echo "Downloading gtminstall"
curl -s --remote-name -L http://downloads.sourceforge.net/project/fis-gtm/GT.M%20Installer/v0.13/gtminstall

# Get kernel.shmmax to determine if we can use 32k strings
if $sharedmem; then
    shmmax=$(sysctl -n kernel.shmmax)

    if [ $shmmax -ge 67108864 ]; then
        echo "Current shared memory maximum is equal to or greater than 64MB"
        echo "Current shmmax is: " $shmmax
    else
        echo "Current shared memory maximum is less than 64MB"
        echo "Current shmmax is: " $shmmax
        echo "Setting shared memory maximum to 64MB"
        echo "kernel.shmmax = 67108864" >> /etc/sysctl.conf
        sysctl -w kernel.shmmax=67108864
    fi
fi

# Make it executable
chmod +x gtminstall

# Determine processor architecture - used to determine if we can use GT.M
#                                    Shared Libraries
# Default to x86 (32bit) - algorithm similar to gtminstall script
arch=$(uname -m | tr -d _)
if [ $arch == "x8664" ]; then
    gtm_arch="x86_64"
else
    gtm_arch="x86"
fi

# Accept most defaults for gtminstall
# --ucaseonly-utils - override default to install only uppercase utilities
#                     this follows VistA convention of uppercase only routines
./gtminstall --ucaseonly-utils --installdir /opt/lsb-gtm/"$gtm_ver"_"$gtm_arch" $gtm_ver
# Remove installgtm script as it is unnecessary
rm ./gtminstall

#pushd /opt/lsb-gtm/"$gtm_ver"_"$gtm_arch"
#ld --shared -o libgtmutil.so *.o
#popd

# Link GT.M shared library where the linker can find it and refresh the cache
if [[ $RHEL || -z $ubuntu ]]; then
    echo "/usr/local/lib" >> /etc/ld.so.conf
fi
ln -s /opt/lsb-gtm/"$gtm_ver"_"$gtm_arch"/libgtmshr.so /usr/local/lib
ln -s /opt/lsb-gtm/"$gtm_ver"_"$gtm_arch"/libgtmutil.so /usr/local/lib
ldconfig
echo "Done installing GT.M"
