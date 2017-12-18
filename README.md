# Dockerized VistA instances

## Requirements
This has only been tested using:

* Docker for Mac
* Docker on Linux (Thanks: George Lilly)
* Docker Toolkit on Windows 7 (Thanks: Sam Habiel)

## Pre-requisites
A working [Docker](https://www.docker.com/community-edition#/download) installation on the platform of choice.

## Note
You cannot use docker exec -it osehravista bash to get access to the mumps prompt. This is likely due to how docker permission schemes for shared memory access works. Instead always gain access via the ssh commands below

## Pre-built images
Pre-built images using this repository are available on [docker hub](https://hub.docker.com/r/krmassociates/)

### Running a Pre-built image
1) Pull the image
    ```
    docker pull krmassociates/osehravista # subsitute worldvista or vxvista if you want one of those instead
    ```
2) Run the image
  Non QEWD enabled images
    ```
    docker run -p 9430:9430 -p 8001:8001 -p 2222:22 -d -P --name=osehravista krmassociates/osehravista # subsitute worldvista or vxvista if you want one of those instead
    ```
  QEWD enabled images
    ```
    docker run -p 9430:9430 -p 8001:8001 -p 2222:22 -p 8080:8080 -d -P --name=osehravista krmassociates/osehravista-qewd
    ```

## Build Steps
1) Build the docker image
    ```
    docker build -t osehra .
    ```
2) Run the created image
    ```
    docker run -p 9430:9430 -p 8001:8001 -p 2222:22 -d -P --name=osehravista osehra
    ```

## Build Steps for Caché installs
Caché will not have any pre-built images due to license restrictions and needing licensed versions of Caché to be used.

The Caché install assumes that you are using a pre-built CACHE.DAT and will perform no configuration to the CACHE.DAT. The default install is done with "minimal" security.

The initial docker container startup will take a bit of time as it needs to perform a workaround due to limitations of the OverlayFS that docker uses (see: https://docs.docker.com/engine/userguide/storagedriver/overlayfs-driver/#limitations-on-overlayfs-compatibility)

Also, many options (EWD, Panorama, etc) are not valid for Caché installs and will be ignored.

1) Copy the Caché installer (kit) to the root of this repository
2) Copy your cache.key to the root of this repository
3) Copy your CACHE.DAT to the root of this repository
4) Make sure that the correct block is uncommented and other install blocks are commented
5) Build the image
   ```
   docker build -t cache .
   ```
6) Run the image:
   ```
   docker run -p 9430:9430 -p 8001:8001 -p2222:22 -p57772:57772 -d -P --name=cache cache
   ```
## Roll-and-Scroll Access for non Caché installs

1) Tied VistA user:

    ssh osehratied@localhost -p 2222 # subsitute worldvistatied or vxvistatied if you used one of those images

password tied

2) Programmer VistA user:

    ssh osehraprog@localhost -p 2222 # subsitute worldvistaprog or vxvistaprog if you used one of those images

password: prog

3) Root access:

    ssh root@localhost -p 2222

password: docker

## VistA Access/Verify codes for non Caché installs

OSEHRA VistA:

Regular doctor:
Access Code: FakeDoc1
Verify Code: 1Doc!@#$

System Manager:
Access Code: SM1234
Verify Code: SM1234!!!

WorldVistA:

Displayed in the VistA greeting message

vxVistA:

Displayed in the VistA greeting message

## QEWD passwords for non Caché installs

Monitor:
keepThisSecret!

## Tests
Deployment tests are written using [bats](https://github.com/sstephenson/bats)
The tests make sure that deployment directories, scripts, RPC Broker, VistALink
are all working and how they should be.

There are two special tests:
 * fifo

   The fifo test is for docker containers and assumes that the tests are ran as root
   (currently) as that is who owns the fifo
 * VistALink

   This test installs java, retrieves a zip file of a github repo and makes a VistALink
   connection. This test does take a few seconds to complete and modifies the installed
   packages of the system. It also needs to have 2 environemnt variables defined: accessCode
   and verifyCode. These should be a valid access/verify code of a system manager user
   that has access to VistALink

