#!/bin/bash

dir=$(pwd)
repS="python3 $dir/bin/strRep.py"
repM="python3 $dir/bin/strS.py"
apktool="java -jar $dir/bin/apktool.jar"

apk_util() {
    cd $dir || exit

    if [[ $1 == "d" ]]; then
        echo -ne "====> Patching $2 : "
        if [[ -f $dir/services.jar ]]; then
            sudo cp $dir/services.jar $dir/jar_temp || exit
            sudo chown $(whoami) $dir/jar_temp/$2 || exit
            $apktool d -o $dir/jar_temp/$2.out $dir/jar_temp/$2 >/dev/null 2>&1
        fi
    elif [[ $1 == "a" ]]; then 
        if [[ -d $dir/jar_temp/$2.out ]]; then
            $apktool b $dir/jar_temp/$2.out -o $dir/jar_temp/$2
            zipalign 4 $dir/jar_temp/$2 $dir/jar_temp/$2-aligned
            if [[ -f $dir/jar_temp/$2-aligned ]]; then
                sudo cp -rf $dir/jar_temp/$2-aligned $dir/module/system/framework
                echo "Success"
                rm -rf $dir/jar_temp/$2.out $dir/jar_temp/$2 $dir/jar_temp/$2-aligned
            else
                echo "Fail"
            fi
        fi
    fi
}

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

services() {
    apk_util d "services.jar"

    # patch signature
    local files=("PermissionManagerServiceImpl.smali" "PermissionManagerServiceStub.smali" 
                 "ParsingPackageUtils.smali" "PackageManagerService\$PackageManagerInternalImpl.smali" 
                 "PackageManagerServiceUtils.smali" "ReconcilePackageUtils.smali" "ScanPackageUtils.smali")

    for file in "${files[@]}"; do
        smali_file=$(find . -name "$file")
        if [[ -f $smali_file ]]; then
            case $file in
                "PermissionManagerServiceImpl.smali")
                    $repS $dir/bin/apr/PermissionManagerServiceImpl/updatePermissionFlags.config.ini $smali_file
                    $repS $dir/bin/apr/PermissionManagerServiceImpl/shouldGrantPermissionBySignature.config.ini $smali_file
                    $repS $dir/bin/apr/PermissionManagerServiceImpl/revokeRuntimePermissionNotKill.config.ini $smali_file
                    $repS $dir/bin/apr/PermissionManagerServiceImpl/revokeRuntimePermission.config.ini $smali_file
                    $repS $dir/bin/apr/PermissionManagerServiceImpl/grantRuntimePermission.config.ini $smali_file
                    ;;
                "PermissionManagerServiceStub.smali")
                    echo "$(cat $dir/bin/apr/PermissionManagerServiceStub/onAppPermFlagsModified.config.ini)" >> $smali_file
                    ;;
                "ParsingPackageUtils.smali")
                    $repS $dir/bin/apr/ParsingPackageUtils/getSigningDetails.config.ini $smali_file
                    ;;
                "PackageManagerService\$PackageManagerInternalImpl.smali")
                    $repS $dir/bin/apr/'PackageManagerService$PackageManagerInternalImpl'/isPlatformSigned.config.ini $smali_file
                    ;;
                "PackageManagerServiceUtils.smali")
                    $repS $dir/bin/apr/PackageManagerServiceUtils/verifySignatures.config.ini $smali_file
                    ;;
                "ReconcilePackageUtils.smali")
                    $repS $dir/bin/apr/ReconcilePackageUtils/reconcilePackages.config.ini $smali_file
                    ;;
                "ScanPackageUtils.smali")
                    $repS $dir/bin/apr/ScanPackageUtils/assertMinSignatureSchemeIsValid.config.ini $smali_file
                    ;;
            esac
        fi
    done

    repM 'isPlatformSigned' true 'PackageManagerService$PackageManagerInternalImpl.smali'
    repM 'isSignedWithPlatformKey' true 'PackageImpl.smali'

    apk_util a "services.jar"
}

if [[ ! -d $dir/jar_temp ]]; then
    mkdir $dir/jar_temp
fi

services
