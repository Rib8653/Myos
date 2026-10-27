// RibOS default Plasma layout: runs once for every new user on first login.
//
//   [            [start][pinned / running apps]            ][dark][tray][clock][|]
//
// One full-width bottom panel. Two expanding spacers keep the start button
// and the task icons centered; tray, clock and "show desktop" sit on the right.

var panel = new Panel;
panel.location = "bottom";
panel.height = 2 * Math.floor(gridUnit * 2.5 / 2);   // ~44-48 px
panel.floating = false;
panel.hiding = "none";

panel.addWidget("org.kde.plasma.panelspacer");

// RibOS start menu (Windows 11 style: search, pinned apps, recommended files,
// all apps, user and power). Its default pins are in the widget's
// contents/config/main.xml under /usr/share/plasma/plasmoids/org.ribos.startmenu.
var start = panel.addWidget("org.ribos.startmenu");

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
