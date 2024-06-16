#!/bin/bash

dir=$(pwd)
repS="python3 $dir/bin/strRep.py"

echo "Starting script in directory: $dir"

apk_util() {
    cd $dir
    echo "Inside apk_util, current directory: $(pwd)"
    
    if [[ $1 == "d" ]]; then
        echo -ne "====> Patching $2 : "
        if [[ -f $dir/services.jar ]]; then
            sudo cp $dir/services.jar $dir/jar_temp
            sudo chown $(whoami) $dir/jar_temp/$2
            apktool d $dir/jar_temp/$2 -o $dir/jar_temp/$2.out
            if [[ -d $dir/jar_temp/"$2.out" ]]; then
                rm -rf $dir/jar_temp/$2
            fi
        fi
    else 
        if [[ $1 == "a" ]]; then 
            if [[ -d $dir/jar_temp/$2.out ]]; then
                cd $dir/jar_temp/$2.out
                echo "Inside apk_util (assemble), current directory: $(pwd)"
                apktool b $dir/jar_temp/$2.out -o $dir/jar_temp/$2
                if [[ -f $dir/jar_temp/$2 ]]; then
                    sudo cp -rf $dir/jar_temp/$2 $dir/module/system/framework
                    final_dir="$dir/module/*"
                    echo "Success"
                    rm -rf $dir/jar_temp/$2.out
                else
                    echo "Fail"
                fi
            fi
        fi
    fi
}

services() {
    lang_dir="$dir/module/lang"
    apk_util d "services.jar"

    s0=$(find $dir/jar_temp/services.jar.out -name "PermissionManagerServiceImpl.smali")
    [[ -f $s0 ]] && $repS $dir/signature/PermissionManagerServiceImpl/updatePermissionFlags.config.ini $s0
    [[ -f $s0 ]] && $repS $dir/signature/PermissionManagerServiceImpl/shouldGrantPermissionBySignature.config.ini $s0
    [[ -f $s0 ]] && $repS $dir/signature/PermissionManagerServiceImpl/revokeRuntimePermissionNotKill.config.ini $s0
    [[ -f $s0 ]] && $repS $dir/signature/PermissionManagerServiceImpl/revokeRuntimePermission.config.ini $s0
    [[ -f $s0 ]] && $repS $dir/signature/PermissionManagerServiceImpl/grantRuntimePermission.config.ini $s0

    s1=$(find $dir/jar_temp/services.jar.out -name "PermissionManagerServiceStub.smali")
    [[ -f $s1 ]] && echo $(cat $dir/signature/PermissionManagerServiceStub/onAppPermFlagsModified.config.ini) >> $s1
    
    s2=$(find $dir/jar_temp/services.jar.out -name "ParsingPackageUtils.smali")
    [[ -f $s2 ]] && $repS $dir/signature/ParsingPackageUtils/getSigningDetails.config.ini $s2

    s3=$(find $dir/jar_temp/services.jar.out -name 'PackageManagerService$PackageManagerInternalImpl.smali')
    [[ -f $s3 ]] && $repS $dir/signature/'PackageManagerService$PackageManagerInternalImpl'/isPlatformSigned.config.ini $s3

    s4=$(find $dir/jar_temp/services.jar.out -name "PackageManagerServiceUtils.smali")
    [[ -f $s4 ]] && $repS $dir/signature/PackageManagerServiceUtils/verifySignatures.config.ini $s4

    s5=$(find $dir/jar_temp/services.jar.out -name "ReconcilePackageUtils.smali")
    [[ -f $s5 ]] && $repS $dir/signature/ReconcilePackageUtils/reconcilePackages.config.ini $s5

    s6=$(find $dir/jar_temp/services.jar.out -name "ScanPackageUtils.smali")
    [[ -f $s6 ]] && $repS $dir/signature/ScanPackageUtils/assertMinSignatureSchemeIsValid.config.ini $s6

    apk_util a "services.jar"
}

if [[ ! -d $dir/jar_temp ]]; then
    mkdir $dir/jar_temp
fi

services
