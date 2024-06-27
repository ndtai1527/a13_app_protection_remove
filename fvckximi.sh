#!/bin/bash
dir=$(pwd)
repS="python3 $dir/bin/strRep.py"
tmp_dir="$dir/smali_tmp"
jar_util() 
{
	cd $dir
	#binary
	if [[ $3 == "fw" ]]; then 
		bak="java -jar $dir/bin/baksmali.jar d"
		sma="java -jar $dir/bin/smali.jar a"
	fi

	if [[ $1 == "d" ]]; then
		echo -ne "====> Patching $2 : "
		if [[ -f $dir/services.jar ]]; then
			sudo cp $dir/services.jar $dir/jar_temp
			sudo chown $(whoami) $dir/jar_temp/$2
			unzip $dir/jar_temp/$2 -d $dir/jar_temp/$2.out  >/dev/null 2>&1
			if [[ -d $dir/jar_temp/"$2.out" ]]; then
				rm -rf $dir/jar_temp/$2
				for dex in $(find $dir/jar_temp/"$2.out" -maxdepth 1 -name "*dex" ); do
						if [[ $4 ]]; then
							if [[ ! "$dex" == *"$4"* ]]; then
								$bak $dex -o "$dex.out"
								[[ -d "$dex.out" ]] && rm -rf $dex
							fi
						else
							$bak $dex -o "$dex.out"
							[[ -d "$dex.out" ]] && rm -rf $dex		
						fi

				done
			fi
		fi
	else 
		if [[ $1 == "a" ]]; then 
			if [[ -d $dir/jar_temp/$2.out ]]; then
				cd $dir/jar_temp/$2.out
				for fld in $(find -maxdepth 1 -name "*.out" ); do
					if [[ $4 ]]; then
						if [[ ! "$fld" == *"$4"* ]]; then
							$sma $fld -o $(echo ${fld//.out})
							[[ -f $(echo ${fld//.out}) ]] && rm -rf $fld
						fi
					else 
						$sma $fld -o $(echo ${fld//.out})
						[[ -f $(echo ${fld//.out}) ]] && rm -rf $fld	
					fi
				done
				7za a -tzip -mx=0 $dir/jar_temp/$2_notal $dir/jar_temp/$2.out/. >/dev/null 2>&1
				#zip -r -j -0 $dir/jar_temp/$2_notal $dir/jar_temp/$2.out/.
				zipalign 4 $dir/jar_temp/$2_notal $dir/jar_temp/$2
				if [[ -f $dir/jar_temp/$2 ]]; then
					sudo cp -rf $dir/jar_temp/$2 $dir/module/system/framework
					final_dir="$dir/module/*"
					#7za a -tzip "$dir/services_patched_$(date "+%d%m%y").zip" $final_dir
					echo "Success"
					rm -rf $dir/jar_temp/$2.out $dir/jar_temp/$2_notal 
				else
					echo "Fail"
				fi
			fi
		fi
	fi
}


services() {
    jar_util d "services.jar" fw

    # Create temporary directory
    [[ ! -d $tmp_dir ]] && mkdir $tmp_dir

    # Files to be patched
    files=("PermissionManagerServiceImpl.smali" "PermissionManagerServiceStub.smali" "ParsingPackageUtils.smali"
           "PackageManagerService\$PackageManagerInternalImpl.smali" "PackageManagerServiceUtils.smali"
           "ReconcilePackageUtils.smali" "ScanPackageUtils.smali")

    # Find and copy the files to the temporary directory
    for file in "${files[@]}"; do
        src_file=$(find $dir/jar_temp/services.jar.out -name "$file")
        if [[ -f $src_file ]]; then
            cp $src_file $tmp_dir/
            echo "Copied $src_file to $tmp_dir"
        else
            echo "File $file not found in $dir/jar_temp/services.jar.out"
        fi
    done

    # Apply strRep.py on the copied files
    s0="$tmp_dir/PermissionManagerServiceImpl.smali"
    [[ -f $s0 ]] && $repS $dir/signature/PermissionManagerServiceImpl/updatePermissionFlags.config.ini $s0
    [[ -f $s0 ]] && $repS $dir/signature/PermissionManagerServiceImpl/shouldGrantPermissionBySignature.config.ini $s0
    [[ -f $s0 ]] && $repS $dir/signature/PermissionManagerServiceImpl/revokeRuntimePermissionNotKill.config.ini $s0
    [[ -f $s0 ]] && $repS $dir/signature/PermissionManagerServiceImpl/revokeRuntimePermission.config.ini $s0
    [[ -f $s0 ]] && $repS $dir/signature/PermissionManagerServiceImpl/grantRuntimePermission.config.ini $s0

    s1="$tmp_dir/PermissionManagerServiceStub.smali"
    [[ -f $s1 ]] && echo $(cat $dir/signature/PermissionManagerServiceStub/onAppPermFlagsModified.config.ini) >> $s1

    s2="$tmp_dir/ParsingPackageUtils.smali"
    [[ -f $s2 ]] && $repS $dir/signature/ParsingPackageUtils/getSigningDetails.config.ini $s2

    s3="$tmp_dir/PackageManagerService\$PackageManagerInternalImpl.smali"
    [[ -f $s3 ]] && $repS $dir/signature/PackageManagerService\$PackageManagerInternalImpl/isPlatformSigned.config.ini $s3

    s4="$tmp_dir/PackageManagerServiceUtils.smali"
    [[ -f $s4 ]] && $repS $dir/signature/PackageManagerServiceUtils/verifySignatures.config.ini $s4

    s5="$tmp_dir/ReconcilePackageUtils.smali"
    [[ -f $s5 ]] && $repS $dir/signature/ReconcilePackageUtils/reconcilePackages.config.ini $s5

    s6="$tmp_dir/ScanPackageUtils.smali"
    [[ -f $s6 ]] && $repS $dir/signature/ScanPackageUtils/assertMinSignatureSchemeIsValid.config.ini $s6

    # Copy the modified files back to their original locations
    for file in "$tmp_dir"/*.smali; do
        base_name=$(basename $file)
        dest_file=$(find $dir/jar_temp/services.jar.out -maxdepth 1 -name "$base_name")
        if [[ -f $file ]]; then
            cp $file $dest_file
            echo "Copied $file to $dest_file"
        else
            echo "Modified file $file not found in $tmp_dir"
        fi
    done

    jar_util a "services.jar" fw  
}
if [[ ! -d $dir/jar_temp ]]; then

	mkdir $dir/jar_temp
	
fi

services

