#!/bin/bash

dir=$(pwd)
repS="python3 $dir/bin/strRep.py"
repM="python3 $dir/bin/strM.py"
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

    lang_dir="$dir/module/lang"
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

	  s3=$(find -name 'PackageManagerService$PackageManagerInternalImpl.smali' )
	  [[ -f $s3 ]] && $repS $dir/signature/'PackageManagerService$PackageManagerInternalImpl'/isPlatformSigned.config.ini $s3

	  s4=$(find -name "PackageManagerServiceUtils.smali")
	  [[ -f $s4 ]] && $repS $dir/signature/PackageManagerServiceUtils/verifySignatures.config.ini $s4

	  s5=$(find -name "ReconcilePackageUtils.smali")
	  [[ -f $s5 ]] && $repS $dir/signature/ReconcilePackageUtils/reconcilePackages.config.ini $s5

	  s6=$(find -name "ScanPackageUtils.smali")
	  [[ -f $s6 ]] && $repS $dir/signature/ScanPackageUtils/assertMinSignatureSchemeIsValid.config.ini $s6
	  #[[ -f $s6 ]] && $repS $dir/signature/ScanPackageUtils/applyPolicy.configs.ini $s6

    repM 'isPlatformSigned' true 'PackageManagerService$PackageManagerInternalImpl.smali'
    repM 'isSignedWithPlatformKey' true 'PackageImpl.smali'

    apk_util a "services.jar"
}

if [[ ! -d $dir/jar_temp ]]; then
    mkdir $dir/jar_temp
fi

services
