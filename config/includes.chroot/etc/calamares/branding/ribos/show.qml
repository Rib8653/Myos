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
            source: "slide-1.png"
            anchors.top: parent.top
            anchors.bottom: caption1.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 8
            fillMode: Image.PreserveAspectFit
            smooth: true
        }
        Text {
            id: caption1
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 40
            text: qsTr("Welcome to RibOS. Sit back: the installation is automatic and takes a few minutes.")
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 15
        }
    }

    Slide {
        Image {
            source: "slide-2.png"
            anchors.top: parent.top
            anchors.bottom: caption2.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 8
            fillMode: Image.PreserveAspectFit
            smooth: true
        }
        Text {
            id: caption2
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 40
            text: qsTr("A familiar desktop: start menu, centered taskbar, snap windows to edges and corners.")
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 15
        }
    }

    Slide {
        Image {
            source: "slide-3.png"
            anchors.top: parent.top
            anchors.bottom: caption3.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 8
            fillMode: Image.PreserveAspectFit
            smooth: true
        }
        Text {
            id: caption3
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 40
            text: qsTr("Get thousands of apps from Discover, including Flathub, in one click.")
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 15
        }
    }

    Slide {
        Image {
            source: "slide-4.png"
            anchors.top: parent.top
            anchors.bottom: caption4.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 8
            fillMode: Image.PreserveAspectFit
            smooth: true
        }
        Text {
            id: caption4
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 40
            text: qsTr("Firefox, LibreOffice and VLC are ready to go. Built on Debian: safe and stable.")
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 15
        }
    }
}
