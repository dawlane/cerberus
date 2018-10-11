﻿Param(
    [string]$android_sdk = "",
    [string]$android_ndk = "",
    [string]$flex_sdk = "",
    [string]$flash_player = "",
    [string]$jdk_path = "",
    [string]$ant_path = "",
    [string]$msvs_path = "",
    [string]$mingw = "",
    [switch]$h,
    [switch]$help
)

if($h -Or $help){
    Write-Host "Usage:"
    Write-Host "      ./config.winnt.ps1 {--option path}"
    Write-Host "      switch:"
    Write-Host "          -android_sdk .... path to android sdk location."
    Write-Host "          -android_ndk .... path to android ndk location."
    Write-Host "          -flex_sdk  .... path to flex (flash) sdk location."
    Write-Host "          -flash_player  .... path to stand-alone Flash Player."
    Write-Host "          -jdk_path .... path to Java Development Kit location."
    Write-Host "          -ant_path .... path to Apache Ants location."
    Exit 0
}

$config="
'--------------------
'Cerberus modules path
'
'Can be overriden via transcc cmd line
'
MODPATH=`"`${CERBERUSDIR}/modules;`${CERBERUSDIR}/modules_ext`"
'--------------------

'--------------------
'HTML player path.
'
'Must be set for HTML5 target support.
'
'for opening .html files...
'
HTML_PLAYER=`"`${CERBERUSDIR}\bin\cserver_winnt.exe`"
'--------------------

'--------------------
'MinGW path.
'
'Must be set to a valid dir for desktop/stdcpp target support.
'
'MinGW is currently here:
'
'***** DO NOT use mingw64-5.1.0 as it has a linker bug *****

'***** 64 bit mingw *****
MINGW_PATH=`"C:\MinGW`"
'--------------------

'--------------------
'Java dev kit path
'
'Must be set to a valid dir for ANDROID and FLASH target support
'
'The Java JDK is currently available here: http://www.oracle.com/technetwork/java/javase/downloads/index.html
'
JDK_PATH=`"d:\programme\JavaSDK`"
'--------------------

'--------------------
'Android SDK and tool paths.
'
'Must be set to a valid dir for ANDROID target support
'
ANDROID_PATH=`"d:\programme\AndroidSDK`"
'--------------------

'--------------------
'Android NDK
'
'Must be set to a valid dir for ANDROID NDK target support
'
ANDROID_NDK_PATH=`"d:\devtools\android-ndk-r9`"
'--------------------

'--------------------
'Ant build tool path
'
'Must be set to a valid dir for FLASH target support
'
'Ant is currently available here: http://ant.apache.org/bindownload.cgi
'
ANT_PATH=`"D:\Programme\apache-ant-1.9.7`"
'--------------------

'--------------------
'Flex SDK and flash player path.
'
'FLEX_PATH Must be set for FLASH target support.
'
'Either HTML_PLAYER or FLASH_PLAYER must be set for FLASH target support.
'
FLEX_PATH=`"d:\devtools\flex-sdk`"
'for opening .swf files...cerberus will use HTML_PLAYER if this is not set.
'FLASH_PLAYER=`"...?...`"
'--------------------

'--------------------
'Play Station Mobile SDK path.
'
'PSM_PATH must be set for PSM target support.
'
PSM_PATH=`"d:\devtools\PSM_SDK`"
'--------------------

'--------------------
'MSBUILD path.
'
'Must be set for XNA and GLFW target support.
'
' Remember that on a 64 bit OS the paths to Visual Studio require (x86)
' Visual Studio Community 2017
MSBUILD_PATH=`"`${PROGRAMFILES(x86)}\Microsoft Visual Studio\2017\Community\MSBuild\15.0\Bin\MSBuild.exe`"
'MSBUILD_PATH=`"`${PROGRAMFILES}\Microsoft Visual Studio\2017\Community\MSBuild\15.0\Bin\MSBuild.exe`"

' Visual Studio 2015
'MSBUILD_PATH=`"`${PROGRAMFILES(x86)}\MSBuild\14.0\Bin\MSBuild.exe`"
'MSBUILD_PATH=`"`${PROGRAMFILES}\MSBuild\14.0\Bin\MSBuild.exe`"

' Visual Studio 2013
'MSBUILD_PATH=`"`${PROGRAMFILES(x86)}\MSBuild\12.0\Bin\MSBuild.exe`"
'MSBUILD_PATH=`"`${PROGRAMFILES}\MSBuild\12.0\Bin\MSBuild.exe`"

' Visual Studio 2012/2010
'MSBUILD_PATH=`"`${WINDIR}\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe`"

'--------------------
' The default Visual Studio version to use
VS_VERSION=2017

' AppGameKit path.
'
'Must be set for AGK support.
'
AGK_PATH=`"C:/Program Files (x86)/The Game Creators/AGK2`"
'
'--------------------

'Third-party Sources
'This is the path where any external third-party library source code should be placed
THIRDPARTY_PATH=`"`${CERBERUSDIR}/src/thirdparty`"
"
if(-Not($android_sdk -eq "")){
   $config -replace "d:\programme\AndroidSDK", "$android_sdk" 
}

if(-Not($android_ndk -eq "")){
   $config -replace "d:\devtools\android-ndk-r9", "$android_ndk" 
}

if(-Not($flex_sdk -eq "")){
   $config -replace "d:\devtools\flex-sdk", "$flex_sdk" 
}

if(-Not($flash_player -eq "")){
   $config -replace "'FLASH_PLAYER=`"...?...`"", "'FLASH_PLAYER=`"$flash_player`""
}

if(-Not($ant_path -eq "")){
   $config -replace "D:\Programme\apache-ant-1.9.7", "$ant_path" 
}

if(-Not($jdk_path -eq "")){
   $config -replace "d:\programme\JavaSDK", "$jdk_path" 
}

if(-Not($msvs_path -eq "")){
   $config -replace '${PROGRAMFILES(x86)}\Microsoft Visual Studio\2017\Community\MSBuild\15.0\Bin\MSBuild.exe', "$msvs_path" 
}

if(-Not($mingw -eq "")){
   $config -replace "C:\MinGW", "$mingw" 
}

$source_root=Resolve-Path -Path "$PSScriptRoot\..\..\..\.."

$config | Out-File -Encoding utf8  "$source_root\bin\config.winnt.txt"
