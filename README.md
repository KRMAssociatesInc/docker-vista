# Dockerized VistA instances

## Requirements
This has only been tested using:

* Docker for Mac
* Docker on Linux (Thanks: George Lilly)
* Docker Toolkit on Windows 7 (Thanks: Sam Habiel)

## Pre-requisites
A working [Docker](https://www.docker.com/community-edition#/download) installation on the platform of choice.

## Build Steps
1) Build the docker image
    ```
    docker build -t osehra .
    ```
2) Run the created image
    ```
    docker run -p 9430:9430 -p 8001:8001 -p 2222:22 -d -P --name=osehravista osehra
    ```
## Roll-and-Scroll Access

1) Tied VistA user:

    ssh osehratied@localhost -p 2222

password tied

2) Programmer VistA user:

    ssh osehraprog@localhost -p 2222

password: prog

3) Root access:

    ssh root@localhost -p 2222

password: docker

