#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#cat <<'EOF' > ../bin/config.macos.txt
cat <<'EOF' > $DIR/config.macos.txt

'--------------------
'Cerberus modules path
'
'Can be overriden via transcc cmd line
'
MODPATH="${CERBERUSDIR}/modules;${CERBERUSDIR}/modules_ext"
'--------------------

'--------------------
'HTML player path.
'
'Must be set for HTML5 target support.
'
HTML_PLAYER=open -n "${CERBERUSDIR}/bin/cserver_macos.app" --args
'--------------------

'--------------------
'Ant build tool path
'
'Must be set to a valid dir for ANDROID target support on Mavericks ('coz Mavericks no longer includes Ant).
'
'Ant is currently available here: 
'	http://ant.apache.org/bindownload.cgi
'
ANT_PATH="${HOME}/apache-ant-1.9.7"
'--------------------

'--------------------
'Flex SDK and flash player path.
'
'Must be set for FLASH target support.
'
FLEX_PATH="${HOME}/flex_sdk_4.6"
'
'for opening .swf files...cerberus will use HTML_PLAYER if this is not set.
'FLASH_PLAYER="...?..."
'--------------------

'--------------------
'Android SDK and tool paths.
'
'Must be set to a valid for for ANDROID target support
'
'Android SDK

'This is where new android studio puts sdk on my macos machine...
ANDROID_PATH="${HOME}/Library/Android/sdk"

'Old sdk..
'ANDROID_PATH="${HOME}/android-sdk-macosx"
'--------------------

'--------------------
'Android NDK
'
'Must be set to a valid dir for ANDROID NDK target support
'
ANDROID_NDK_PATH="${HOME}/Library/Android/ndk-bundle"

'Old ndk..
ANDROID_NDK_PATH="${HOME}/android-ndk-r9"
'--------------------

EOF

# If there were arguments passed to set up paths
# Parse arguments
while [[ $# -gt 0 ]]
do
	key="$1"
	case $key in
        --android_sdk )
            sed -i 's#${HOME}/Library/Android/sdk#'"$2"'#g' config.macos.txt
            shift; shift;;
        --android_ndk )
            sed -i 's#${HOME}/Library/Android/ndk-bundle#'"$2"'#g' config.macos.txt
            shift; shift;;
        --flex_sdk )
            sed -i 's#${HOME}/flex_sdk_4.6#'"$2"'#g' config.macos.txt
            shift; shift;;
        --flash_player )
            sed -i "s#'FLASH_PLAYER=#FLASH_PLAYER=#g" config.macos.txt
            sed -i 's#...?...#'"$2"'#g' config.macos.txt
            shift; shift;;
        --ant_path )
            sed -i 's#${HOME}/apache-ant-1.9.7#'"$2"'#g' config.macos.txt
            shift; shift;;
        -h | --help )
            echo "Usage:"
            echo "      ./config.macos.sh {--option path}"
            echo "      switch:"
            echo "          --android_sdk .... path to android sdk location."
            echo "          --android_ndk .... path to android ndk location."
            echo "          --flex_sdk  .... path to flex (flash) sdk location."
            echo "          --flash_player  .... path to stand-alone Flash Player."
            echo "          --ant_path .... path to ant tool location."
            exit;;
        * )
            shift;;
    esac
done

mv $DIR/config.macos.txt $DIR/../../../../bin/config.macos.txt
exit 0