/* RibOS installer slideshow, shown while files are copied.
 * SPDX-License-Identifier: GPL-3.0-or-later (based on the Calamares example)
 */
import QtQuick 2.0
import calamares.slideshow 1.0

Presentation {
    id: presentation

    function onActivate() { }
    function onLeave() { }

    Timer {
        interval: 12000
        running: presentation.activatedInCalamares
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    Slide {
        Image {
            id: pic1
            source: "slide-1.png"
            width: 800; height: 440
            fillMode: Image.PreserveAspectFit
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
        }
        Text {
            anchors.top: pic1.bottom
            anchors.topMargin: 16
            anchors.horizontalCenter: parent.horizontalCenter
            width: 760
            text: qsTr("Welcome to RibOS. Sit back: the installation is automatic and takes a few minutes.")
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 16
        }
    }

    Slide {
        Image {
            id: pic2
            source: "slide-2.png"
            width: 800; height: 440
            fillMode: Image.PreserveAspectFit
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
        }
        Text {
            anchors.top: pic2.bottom
            anchors.topMargin: 16
            anchors.horizontalCenter: parent.horizontalCenter
            width: 760
            text: qsTr("A familiar desktop: start menu, centered taskbar, snap windows to edges and corners.")
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 16
        }
    }

    Slide {
        Image {
            id: pic3
            source: "slide-3.png"
            width: 800; height: 440
            fillMode: Image.PreserveAspectFit
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
        }
        Text {
            anchors.top: pic3.bottom
            anchors.topMargin: 16
            anchors.horizontalCenter: parent.horizontalCenter
            width: 760
            text: qsTr("Get thousands of apps from Discover, including Flathub, in one click.")
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 16
        }
    }

    Slide {
        Image {
            id: pic4
            source: "slide-4.png"
            width: 800; height: 440
            fillMode: Image.PreserveAspectFit
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
        }
        Text {
            anchors.top: pic4.bottom
            anchors.topMargin: 16
            anchors.horizontalCenter: parent.horizontalCenter
            width: 760
            text: qsTr("Firefox, LibreOffice and VLC are ready to go. Built on Debian: safe and stable.")
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 16
        }
    }
}
