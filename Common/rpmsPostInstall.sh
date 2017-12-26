#!/bin/bash
#set -x

# Get GT.M Optimized Routines from Kernel-GTM project (newer version) and unzip
pushd ~
rm -f virgin_install.zip
curl -fsSLO https://github.com/shabiel/Kernel-GTM/releases/download/XU-8.0-10002/virgin_install.zip

# Unzip file, put routines, delete old objects, recompile
unzip -qo ~/virgin_install.zip -d $basedir/r/
unzip -l ~/virgin_install.zip | awk '{print $4}' | grep '\.m' | sed 's/.m/.o/' | xargs -i rm -fv r/$gtmver/{}
rm -f $basedir/r/$gtmver/_*.o
pushd $basedir/r/$gtmver/
unzip -l ~/virgin_install.zip | awk '{print $4}' | grep '\.m' | xargs -i -n 1 $gtm_dist/mumps -nowarning ../{}
popd # now in ~

# Get the Auto-configurer for VistA/RPMS and run
curl -fsSLO https://raw.githubusercontent.com/shabiel/random-vista-utilities/master/KBANTCLN.m
mv KBANTCLN.m $basedir/r/
rm -f $basedir/r/$gtmver/KBANTCLN.o

# Download the VueCentric templates and registrations
mkdir ~/tmp/vuecentric_files
pushd ~/tmp/vuecentric_files
curl -fsSLO https://code.osehra.org/files/clients/RPMS/automated_installer_files/OSEHRA_P23_2017.vtr
curl -fsSLO https://code.osehra.org/files/clients/RPMS/automated_installer_files/IHSReferredCare.PatientReferral.vor
curl -fsSLO https://code.osehra.org/files/clients/RPMS/automated_installer_files/IHSReferredCare.Referral.vor
popd # now in ~

# popd goes back to our docker files
popd # now in /opt/vista
# Run RPMS Post Install Code
cp ./Common/rpmsPostInstall.m $basedir/r/

# Make sure .mjo and .mje files end up in the ~/tmp directory
pushd ~/tmp/
$gtm_dist/mumps -run ^rpmsPostInstall
popd # now in /opt/vista
