// RibOS default Plasma layout: runs once for every new user on first login.
//
//   [            [start][pinned / running apps]            ][tray][clock][|]
//
// One full-width bottom panel. Two expanding spacers keep the start button
// and the task icons centered; tray, clock and "show desktop" sit on the right.

var panel = new Panel;
panel.location = "bottom";
panel.height = 2 * Math.floor(gridUnit * 2.5 / 2);   // ~44-48 px
panel.floating = false;
panel.hiding = "none";

panel.addWidget("org.kde.plasma.panelspacer");

var start = panel.addWidget("org.kde.plasma.kickoff");
start.currentConfigGroup = ["General"];
start.writeConfig("icon", "ribos-start");
// Pinned apps in the start menu (first login only; users can re-pin).
start.writeConfig("favorites", [
    "preferred://browser",
    "org.kde.dolphin.desktop",
    "libreoffice-writer.desktop",
    "libreoffice-calc.desktop",
    "vlc.desktop",
    "org.kde.gwenview.desktop",
    "org.kde.kate.desktop",
    "org.kde.discover.desktop",
    "systemsettings.desktop",
    "ribos-dark-mode.desktop"
]);
start.writeConfig("favoritesDisplay", 0);          // pinned apps as a grid
start.writeConfig("applicationsDisplay", 1);       // "All apps" as a list
start.writeConfig("showActionButtonCaptions", true);
start.writeConfig("primaryActions", 0);            // footer shows power buttons (sleep/restart/shut down)

var tasks = panel.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", [
    "applications:firefox-esr.desktop",
    "applications:org.kde.dolphin.desktop",
    "applications:libreoffice-startcenter.desktop",
    "applications:org.kde.discover.desktop"
]);
tasks.writeConfig("fill", false);                  // shrink to content so it can be centered
tasks.writeConfig("iconSpacing", 2);
tasks.writeConfig("maxStripes", 1);

panel.addWidget("org.kde.plasma.panelspacer");

panel.addWidget("org.ribos.darkmode");
panel.addWidget("org.kde.plasma.systemtray");

var clock = panel.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", true);
clock.writeConfig("dateDisplayFormat", 2);         // 2 = date below the time
clock.writeConfig("dateFormat", "shortDate");

panel.addWidget("org.kde.plasma.showdesktop");     // thin "peek" button at the far right

// Desktop: RibOS wallpaper, icons arranged in columns from the top-left.
var allDesktops = desktops();
for (var i = 0; i < allDesktops.length; i++) {
    var d = allDesktops[i];
    d.wallpaperPlugin = "org.kde.image";
    d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    d.writeConfig("Image", "file:///usr/share/wallpapers/RibOS/");
    d.currentConfigGroup = ["General"];
    d.writeConfig("arrangement", 1);
    d.writeConfig("alignment", 0);
}
