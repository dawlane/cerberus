#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cat <<'EOF' > $DIR/config.linux.txt

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
HTML_PLAYER="${CERBERUSDIR}/bin/cserver_linux"
'--------------------

'--------------------
'Java dev kit path
'
'Must be set to a valid dir for ANDROID and FLASH target support
'
'The Java JDK is currently available here:
'	http://www.oracle.com/technetwork/java/javase/downloads/index.html
'
JDK_PATH="${HOME}/jdk1.8.0_172" 
'JDK_PATH="${HOME}/jdk1.8.0_171" 
'JDK_PATH="${HOME}/jdk1.8.0_151" 
'JDK_PATH="${HOME}/jdk1.8.0_31"
'JDK_PATH="${HOME}/jdk1.7.0_09"
'--------------------

'--------------------
'Flex SDK and flash player path.
'
'FLEX_PATH Must be set for FLASH target support.
'
FLEX_PATH="${HOME}/flex_sdk_4.6"
'
'for opening .swf files...cerberus will use HTML_PLAYER if this is not set.
'FLASH_PLAYER="...?..."
'--------------------

'--------------------
'Android SDK and tool paths.
'
'Must be set to a valid for for ANDROID target support.
'
ANDROID_PATH="${HOME}/android-sdk-linux"
'--------------------

'--------------------
'Android NDK
'
'Must be set to a valid dir for ANDROID NDK target support
'
ANDROID_NDK_PATH="${HOME}/android-ndk-r9"
'--------------------

EOF

# If there were arguments passed to set up paths
# Parse arguments
while [[ $# -gt 0 ]]
do
	key="$1"
	case $key in
        --cerbroot )
            CERBROOT=$2
            shift; shift;;
        --android_sdk )
            sed -i 's#${HOME}/android-sdk-linux#'"$2"'#g' config.linux.txt
            shift; shift;;
        --android_ndk )
            sed -i 's#${HOME}/android-ndk-r9#'"$2"'#g' config.linux.txt
            shift; shift;;
        --flex_sdk )
            sed -i 's#${HOME}/flex_sdk_4.6#'"$2"'#g' config.linux.txt
            shift; shift;;
        --flash_player )
            sed -i "s#'FLASH_PLAYER=#FLASH_PLAYER=#g" config.linux.txt
            sed -i "s#...?...#$2#g" config.linux.txt
            shift; shift;;
        --jdk_path )
            sed -i 's#${HOME}/jdk1.8.0_31#'"$2"'#g' config.linux.txt
            shift; shift;;
        -h | --help )
            echo "Usage:"
            echo "      ./config.linux.sh {--option path}"
            echo "      switch:"
            echo "          --android_sdk .... path to android sdk location."
            echo "          --android_ndk .... path to android ndk location."
            echo "          --flex_sdk  .... path to flex (flash) sdk location."
            echo "          --flash_player  .... path to stand-alone Flash Player."
            echo "          --jdk_path .... path to Java Development Kit location."
            exit;;
        * )
            shift;;
    esac
done

mv $DIR/config.linux.txt $DIR/../../../../bin/config.linux.txt
exit 0