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

# Add cacheusr to system to own Caché files
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

    This script will create the necessary users and groups for Caché

    OPTIONS:
      -h    Show this message
      -i    Instance name
EOF
}

while getopts ":hi:" option
do
    case $option in
        h)
            usage
            exit 1
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

# Used ideas from:
# http://www.debian.org/doc/manuals/securing-debian-howto/ch9.en.html
# to create daemon accounts & groups

SERVER_HOME=/opt/cachesys/$instance
SERVER_USER=cacheusr$instance
SERVER_NAME="Intersystems Cache $instance instance"
SERVER_GROUP=cachegrp$instance

# create user to avoid running server as root
# create group if not existing
if ! getent group | grep -q "^$SERVER_GROUP:" ; then
    # TODO: echo this to log
    #echo -n "Adding group $SERVER_GROUP.."
    groupadd --system $SERVER_GROUP 2>/dev/null ||true
    # TODO: echo this to log
    #echo "..done"
fi
# create homedir if not existing
test -d $SERVER_HOME || mkdir -p $SERVER_HOME
# create user if not existing
if ! getent passwd | grep -q "^$SERVER_USER:"; then
    # TODO: echo this to log
    #echo -n "Adding system user $SERVER_USER.."
    adduser --system \
            --groups $SERVER_GROUP \
            --no-create-home \
            $SERVER_USER 2>/dev/null || true
    # TODO: echo this to log
    #echo "..done"
fi
# adjust passwd entry
usermod -c "$SERVER_NAME" \
        -d $SERVER_HOME   \
        -g $SERVER_GROUP  \
        $SERVER_USER
# adjust file and directory permissions
chown -R $SERVER_USER:$SERVER_GROUP $SERVER_HOME
chmod u=rwx,g=rxs,o= $SERVER_HOME
