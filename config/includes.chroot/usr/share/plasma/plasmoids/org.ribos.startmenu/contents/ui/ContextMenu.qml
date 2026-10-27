/*
    Right-click menu for start menu entries: "Pin to Start"/"Unpin from Start"
    plus the entry's own actions from the Kicker model (e.g. pin to taskbar,
    open containing folder). SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import org.kde.plasma.extras as PlasmaExtras

Item {
    id: root
    visible: false

    property var entries: []
    property var targetModel: null
    property int targetIndex: -1

    // Opens the menu for row `index` of `model` at (x, y) inside `parentItem`.
    function show(parentItem, x, y, model, index, favoritesModel, favoriteId, actionList) {
        let list = []
        if (favoritesModel && favoriteId) {
            if (favoritesModel.isFavorite(favoriteId)) {
                list.push({ text: i18n("Unpin from Start"), icon: "window-unpin",
                            run: () => favoritesModel.removeFavorite(favoriteId) })
            } else {
                list.push({ text: i18n("Pin to Start"), icon: "window-pin",
                            run: () => favoritesModel.addFavorite(favoriteId) })
            }
        }
        const extra = actionList ? Array.from(actionList) : []
        if (list.length > 0 && extra.length > 0) {
            list.push({ type: "separator" })
        }
        root.entries = list.concat(extra.filter(a => !a.subActions))
        root.targetModel = model
        root.targetIndex = index
        if (root.entries.length > 0) {
            menu.visualParent = parentItem
            menu.open(x, y)
        }
    }

    PlasmaExtras.Menu {
        id: menu
        visualParent: null
    }

    Instantiator {
        model: root.entries
        delegate: PlasmaExtras.MenuItem {
            required property var modelData
            text: modelData.text ?? ""
            icon: modelData.icon ?? null
            separator: modelData.type === "separator"
            section: modelData.type === "title"
            enabled: modelData.type !== "title" && (modelData.enabled ?? true)
            onClicked: {
                if (modelData.run) {
                    modelData.run()
                } else if (root.targetModel && root.targetModel.trigger) {
                    root.targetModel.trigger(root.targetIndex, modelData.actionId, modelData.actionArgument)
                }
            }
        }
        onObjectAdded: (index, object) => menu.addMenuItem(object)
        onObjectRemoved: (index, object) => menu.removeMenuItem(object)
    }
}
