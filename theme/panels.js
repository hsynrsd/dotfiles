// Plasma layout: thin top bar (menu, workspaces | clock | tray) + centered floating dock.
// Run: qdbus-qt6 org.kde.plasmashell /PlasmaShell evaluateScript "$(cat panels.js)"
var dock = null;
panels().forEach(function (p) {
    if (p.widgets("org.kde.plasma.icontasks").length && !dock) { dock = p; }
    else { p.remove(); }   // old top bar from a previous run
});
if (!dock) { dock = new Panel; dock.addWidget("org.kde.plasma.icontasks"); }

// ── Dock: just the app icons ──
dock.widgets().forEach(function (w) {
    if (w.type !== "org.kde.plasma.icontasks") w.remove();
});
dock.location = "bottom";
dock.height = 56;
dock.alignment = "center";
dock.lengthMode = "fit";
dock.hiding = "autohide";
dock.floating = true;
var tasks = dock.widgets("org.kde.plasma.icontasks")[0];
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("iconSpacing", 2);
tasks.writeConfig("maxStripes", 1);
tasks.writeConfig("indicateAudioStreams", true);

// ── Top bar ──
var top = new Panel;
top.location = "top";
top.height = 30;
top.floating = false;
top.hiding = "none";
var menu = top.addWidget("org.kde.plasma.kickoff");
menu.currentConfigGroup = ["General"];
menu.writeConfig("icon", "fedora-logo-icon");
top.addWidget("org.kde.plasma.pager");
top.addWidget("org.kde.plasma.panelspacer");
var clock = top.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", true);
clock.writeConfig("dateDisplayFormat", "BesideTime");
clock.writeConfig("dateFormat", "custom");
clock.writeConfig("customDateFormat", "ddd d MMM");
clock.writeConfig("use24hFormat", 2);
top.addWidget("org.kde.plasma.panelspacer");
top.addWidget("org.kde.plasma.systemtray");
