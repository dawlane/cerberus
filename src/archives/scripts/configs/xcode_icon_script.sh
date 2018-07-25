# Quick and dirty way to get the application you use user icons.
# The project folder must have a directory called icons at root source level with a sub directory call 'png' using Apple's naming for icons is required e.g icon_XresoulionxYresolution.png and icon_XresoulionxYresolution@2x.png for this to work.

# Add /usr/local/bin to the systems PATH for any extra tool that may be needed.
# Tools of note: iconutil. See the man pag
PATH=${PATH}:/usr/local/bin
# Default icons for Mac as in XCODE 7.3
ICON_LIST=('16x16' '16x16@2x' '32x32' '32x32@2x' '128x128' '128x128@2x' '256x256' '256x256@2x' '512x512' '512x512@2x')

# Get the root directory.
IFS=$'\n'
CPRJ_ROOT="$( cd "$( dirname "${SRCROOT}" )"/../../ && pwd) "

# Function to copy over the icons from A to B
function copy(){
    local src=$1
    local dst="${SRCROOT}/CerberusGame/Images.xcassets/AppIcon.appiconset"
    
    # Loop through the ICON_LIST array for the icon files supported
    for icon_size in ${ICON_LIST[@]}; do
    if [ -f "$dst/icon_$icon_size.png" ]; then rm -f $dst/icon_$icon_size.png; fi # Remove the old file before copying over a new one.
    if [ -f "$src/icon_$icon_size.png" ]; then cp $src/icon_$icon_size.png $dst/icon_$icon_size.png; fi # Only copy if it's the right file.
    done
}

# Check the paths and select
function CheckPath(){
    # The clean up the path for the projects root location.
    # Don't know why, but $CPRJ_ROOT ends up with space at the end. So Trim any white space off.
    USER_RESOURCE=$(echo "${CPRJ_ROOT}" | awk '{gsub(/^ +| +$/,"")}1')

    # The default location for the icon set in Cerberus
    CERBERUS_RESOURCE=$(echo "${CERBERUS_PATH}" | awk '{gsub(/^ +| +$/,"")}1')
    CERBERUS_RESOURCE="$CERBERUS_RESOURCE/src/archives/icons/cerberus.iconset"

    echo "USER RESOURCE PATH: $USER_RESOURCE"
    echo "CERBERUS RESOURCE PATH: $CERBERUS_RESOURCE"
    
    # Check to see if a user has used a full path to the icons.
    if [ -d "${CERBERUS_ICONSET_PATH}.iconset" ]; then
        echo "Setting iconset to full user named path."
        USER_RESOURCE="${CERBERUS_ICONSET_PATH}.iconset"
        echo "ICON SET: $USER_RESOURCE"
        copy "$USER_RESOURCE"
    else
        # check the local icon resource directory
        if [ -d "$USER_RESOURCE/icons/${CERBERUS_ICONSET_PATH}.iconset" ]; then
            echo "Setting iconset to local project user named resource."
            USER_RESOURCE="$USER_RESOURCE/icons/${CERBERUS_ICONSET_PATH}.iconset"
            echo "ICON SET: $USER_RESOURCE"
            copy "$USER_RESOURCE"
        else
            # Check the local icon resource for anything names icon
            if [ -d "$USER_RESOURCE/icons/icon.iconset" ]; then
                echo "Setting iconset to local project icon resource."
                USER_RESOURCE="$USER_RESOURCE/icons/icon.iconset"
                echo "ICON SET: $USER_RESOURCE"
                copy "$USER_RESOURCE"
            else
                # Fall back to Cereberus icons
                if [ -d "$CERBERUS_RESOURCE" ]; then
                    echo "Setting iconset to Cerberus default resource directory."
                    USER_RESOURCE="$CERBERUS_RESOURCE"
                    echo "ICON SET: $USER_RESOURCE"
                    copy "$USER_RESOURCE"
                else
                    echo "No iconset found. Failing back to Apple default or whatever was last used."
                fi
            fi
        fi
    fi
}

echo ""; echo "RUNNING ICON COPY SCRIPT"
echo "COPYING ICON DATA"
echo ""
CheckPath
echo "FINISHED RUNNING ICON COPY SCRIPT"; echo ""
