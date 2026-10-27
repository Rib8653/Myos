/*
    A row in the start menu (all apps, recommended files, search results):
    icon, title and an optional grey subtitle. SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami

MouseArea {
    id: row

    property string label
    property string subtitle
    property var iconSource
    property bool current: false
    property int iconSize: Kirigami.Units.iconSizes.medium

    signal activated()
    signal menuRequested(real x, real y)

    implicitHeight: Math.max(iconSize, contents.implicitHeight) + Kirigami.Units.largeSpacing
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: mouse => mouse.button === Qt.RightButton ? menuRequested(mouse.x, mouse.y) : activated()

    Accessible.name: label
    Accessible.role: Accessible.Button

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Kirigami.Units.cornerRadius
        color: Kirigami.Theme.textColor
        opacity: row.pressed ? 0.12 : (row.containsMouse || row.current ? 0.07 : 0)
    }

    RowLayout {
        id: contents
        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.largeSpacing
        anchors.rightMargin: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.largeSpacing

        Kirigami.Icon {
            implicitWidth: row.iconSize
            implicitHeight: row.iconSize
            source: row.iconSource
            animated: false
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            PC3.Label {
                Layout.fillWidth: true
                text: row.label
                elide: Text.ElideRight
            }
            PC3.Label {
                Layout.fillWidth: true
                visible: text.length > 0
                text: row.subtitle
                elide: Text.ElideMiddle
                font: Kirigami.Theme.smallFont
                opacity: 0.7
            }
        }
    }
}
