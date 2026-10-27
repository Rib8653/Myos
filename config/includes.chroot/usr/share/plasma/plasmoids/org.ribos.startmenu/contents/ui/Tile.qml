/*
    A pinned app in the start menu grid: icon with the name underneath.
    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami

MouseArea {
    id: tile

    property string label
    property var iconSource
    property bool current: false

    signal activated()
    signal menuRequested(real x, real y)

    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: mouse => mouse.button === Qt.RightButton ? menuRequested(mouse.x, mouse.y) : activated()

    Accessible.name: label
    Accessible.role: Accessible.Button

    Rectangle {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing / 2
        radius: Kirigami.Units.cornerRadius
        color: Kirigami.Theme.textColor
        opacity: tile.pressed ? 0.12 : (tile.containsMouse || tile.current ? 0.07 : 0)
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width - Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: Kirigami.Units.iconSizes.medium
            implicitHeight: Kirigami.Units.iconSizes.medium
            source: tile.iconSource
            animated: false
        }
        PC3.Label {
            Layout.fillWidth: true
            text: tile.label
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            wrapMode: Text.Wrap
            maximumLineCount: 2
            font: Kirigami.Theme.smallFont
        }
    }
}
