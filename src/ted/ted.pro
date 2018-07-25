#-------------------------------------------------
#
# Project created by QtCreator 2012-04-28T10:44:05
#
#-------------------------------------------------
# Change log
# 2018-07-23 - Dawlane
#						Updated to use with Qt5.6+
#						Linux should now no longer rely on the distributions repositories for Qt. Qt5.9.2 tested only.

QT -= qml quick location positioning quickcontrols2
QT += core gui network widgets

equals(QT_MAJOR_VERSION, 5):!greaterThan(QT_MINOR_VERSION, 5){
    QT += webkit webkitwidgets
} else {
    QT +=  webenginewidgets
}

TEMPLATE = app

SOURCES += main.cpp\
        mainwindow.cpp \
    codeeditor.cpp \
    colorswatch.cpp \
    projecttreemodel.cpp \
    std.cpp \
    debugtreemodel.cpp \
    finddialog.cpp \
    prefs.cpp \
    prefsdialog.cpp \
    process.cpp \
    findinfilesdialog.cpp

HEADERS  += mainwindow.h \
    codeeditor.h \
    colorswatch.h \
    projecttreemodel.h \
    std.h \
    debugtreemodel.h \
    finddialog.h \
    prefs.h \
    prefsdialog.h \
    process.h \
    findinfilesdialog.h

FORMS    += mainwindow.ui \
    finddialog.ui \
    prefsdialog.ui \
    findinfilesdialog.ui

RESOURCES += resources.qrc

TARGET = Ted
#OK, this seems to prevent latest Windows QtCreator from being able to run Ted (builds fine).
#Solved by using qtcreator-2.4.1
DESTDIR = ../../bin

win32{
        RC_FILE = appicon.rc
}

linux{
        CONFIG += C++11
# Suppress warings
        QMAKE_STRIP = echo

        # Make a linux application search for libraries here.
        QMAKE_RPATHDIR = $ORIGIN/lib

        # Copy over all the required libraries
        QTLIBS += $$[QT_INSTALL_DATA]/lib/libicudata.so.56
        QTLIBS += $$[QT_INSTALL_DATA]/lib/libicui18n.so.56
        QTLIBS += $$[QT_INSTALL_DATA]/lib/libicuuc.so.56
        QTLIBS += $$[QT_INSTALL_DATA]/lib/libQt5Core.so.5
        QTLIBS += $$[QT_INSTALL_DATA]/lib/libQt5DBus.so.5
        QTLIBS += $$[QT_INSTALL_DATA]/lib/libQt5Gui.so.5
        QTLIBS += $$[QT_INSTALL_DATA]/lib/libQt5Network.so.5
        QTLIBS += $$[QT_INSTALL_DATA]/lib/libQt5Positioning.so.5
        QTLIBS += $$[QT_INSTALL_DATA]/lib/libQt5PrintSupport.so.5
        QTLIBS += $$[QT_INSTALL_DATA]/lib/libQt5Qml.so.5
        QTLIBS += $$[QT_INSTALL_DATA]/lib/libQt5Quick.so.5
        QTLIBS += $$[QT_INSTALL_DATA]/lib/libQt5QuickWidgets.so.5
        QTLIBS += $$[QT_INSTALL_DATA]/lib/libQt5WebChannel.so.5
        QTLIBS += $$[QT_INSTALL_DATA]/lib/libQt5WebEngineCore.so.5
        QTLIBS += $$[QT_INSTALL_DATA]/lib/libQt5WebEngineWidgets.so.5
        QTLIBS += $$[QT_INSTALL_DATA]/lib/libQt5Widgets.so.5
        QTLIBS += $$[QT_INSTALL_DATA]/lib/libQt5XcbQpa.so.5

        libs.files += $$QTLIBS
        libs.path += $(DESTDIR)/lib

        # Plugins
        # NOT USED, BUT KEPT AS REFERENCE: bearer imageformats platforminputcontexts position printsupport

        platforms.files += $$[QT_INSTALL_PLUGINS]/platforms/libqxcb.so
        platforms.path += $(DESTDIR)/plugins/platforms

        xcbglintegrations.files += $$[QT_INSTALL_PLUGINS]/xcbglintegrations/libqxcb-glx-integration.so
        xcbglintegrations.path += $(DESTDIR)/plugins/xcbglintegrations

        # translations. Don't need the qml stuff
        translations.files += $$[QT_INSTALL_TRANSLATIONS]/qtwebengine_locales/*.pak
        translations.path += $(DESTDIR)/translations/qtwebengine_locales

        # resources
        resources.files += $$[QT_INSTALL_DATA]/resources/*
        resources.path += $(DESTDIR)/resources

        # WebEngineProcess
        webengineprocess.files += $$[QT_INSTALL_DATA]/libexec/QtWebEngineProcess
        webengineprocess.path += $(DESTDIR)/libexec

        config1.files += $(_PRO_FILE_PWD_)/configs/bin/qt.conf
        config1.path += $(DESTDIR)

        config2.files += $(_PRO_FILE_PWD_)/configs/libexec/qt.conf
        config2.path += $(DESTDIR)/libexec

        #target.extra = strip $(TARGET); cp -f $(TARGET) $${PREFIX}/bin/$(TARGET)
        INSTALLS += libs platforms translations resources webengineprocess config1 config2 xcbglintegrations
        install:   $(INSTALLS)
}

mac{
#        WTF..enabling this appears to *break* 10.6 compatibility!!!!!
        QMAKE_MACOSX_DEPLOYMENT_TARGET = 10.9
        QMAKE_INFO_PLIST = Info.plist
        ICON = ted.icns
        CONFIG += C++11
}

DISTFILES += \
    configs/libexec/qt.conf \
    configs/bin/qt.conf

