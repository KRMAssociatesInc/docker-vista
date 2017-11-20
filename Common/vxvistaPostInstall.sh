#!/bin/bash
cp ./Common/vxvistaPostInstall.m $basedir/r/
$gtm_dist/mumps -run ^vxvistaPostInstall
