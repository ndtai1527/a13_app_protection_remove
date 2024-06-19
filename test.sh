#!/bin/bash

dir=$(pwd)
repS="python3 $dir/bin/strRep.py"
repM="python3 $dir/bin/strS.py"
apkE="java -jar $dir/bin/apkE.jar"
mkdir -p $dir/tmp/services/
mkdir $dir/jar_temp

repM() {
    if [[ $4 == "r" ]]; then
        if [[ -f $3 ]]; then
            $repM "$1" "$2" "$3"
        fi
    elif [[ $4 == "f" ]]; then
        for i in $3; do
            $repM "$1" "$2" "$i"
        done
    else
        local file
        file=$(sudo find . -name "$3")
        if [[ $file ]]; then
            $repM "$1" "$2" "$file"
        fi
    fi
}

if [[ -f $dir/services.jar ]]; then
    mkdir $dir/jar_temp
    sudo cp $dir/services.jar $dir/jar_temp
fi


echo "Running apkE decompilation..."
$apkE d -f -i $dir/jar_temp/services.jar -o $dir/tmp/services  > /dev/null 2>&1  
echo "Searching and modifying smali files..."
s0=$(find -name "PermissionManagerServiceImpl.smali")
[[ -f $s0 ]] && $repS $dir/signature/PermissionManagerServiceImpl/updatePermissionFlags.config.ini $s0
[[ -f $s0 ]] && $repS $dir/signature/PermissionManagerServiceImpl/shouldGrantPermissionBySignature.config.ini $s0
[[ -f $s0 ]] && $repS $dir/signature/PermissionManagerServiceImpl/revokeRuntimePermissionNotKill.config.ini $s0
[[ -f $s0 ]] && $repS $dir/signature/PermissionManagerServiceImpl/revokeRuntimePermission.config.ini $s0
[[ -f $s0 ]] && $repS $dir/signature/PermissionManagerServiceImpl/grantRuntimePermission.config.ini $s0

s1=$(find -name "PermissionManagerServiceStub.smali")
[[ -f $s1 ]] && echo $(cat $dir/signature/PermissionManagerServiceStub/onAppPermFlagsModified.config.ini) >> $s1

s2=$(find -name "ParsingPackageUtils.smali")
[[ -f $s2 ]] && $repS $dir/signature/ParsingPackageUtils/getSigningDetails.config.ini $s2

s3=$(find -name "PackageManagerService\$PackageManagerInternalImpl.smali")
[[ -f $s3 ]] && $repS $dir/signature/PackageManagerService\$PackageManagerInternalImpl/isPlatformSigned.config.ini $s3

s4=$(find -name "PackageManagerServiceUtils.smali")
[[ -f $s4 ]] && $repS $dir/signature/PackageManagerServiceUtils/verifySignatures.config.ini $s4

s5=$(find -name "ReconcilePackageUtils.smali")
[[ -f $s5 ]] && $repS $dir/signature/ReconcilePackageUtils/reconcilePackages.config.ini $s5

s6=$(find -name "ScanPackageUtils.smali")
[[ -f $s6 ]] && $repS $dir/signature/ScanPackageUtils/assertMinSignatureSchemeIsValid.config.ini $s6

repM 'isPlatformSigned' true 'PackageManagerService$PackageManagerInternalImpl.smali'
repM 'isSignedWithPlatformKey' true 'PackageImpl.smali'

echo "Running apkE compilation..."
$apkE b -f -i $dir/tmp/services -o $dir/tmp/services_patched.jar > /dev/null 2>&1



echo "Setting up directories..."
sudo cp -rf $dir/tmp/services_patched.jar $dir/module/system/framework

echo "Starting services function..."

