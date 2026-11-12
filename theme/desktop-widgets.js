// Steel desktop widgets on the right: big clock, CPU/GPU/RAM rings, network graph.
// Re-running replaces the ones it added before.
var d = desktops()[0];
d.widgets().forEach(function (w) {
    if (w.type === "org.kde.plasma.digitalclock" || w.type.indexOf("org.kde.plasma.systemmonitor") === 0) w.remove();
});
var sw = screenGeometry(d.screen).width, x = sw - 400, y = 70;
var BLUE = "122,162,247", TEAL = "115,184,201", STEEL = "169,177,214";

var clock = d.addWidget("org.kde.plasma.digitalclock", x, y, 360, 150);
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", true);
clock.writeConfig("dateDisplayFormat", "BelowTime");
clock.writeConfig("dateFormat", "custom");
clock.writeConfig("customDateFormat", "dddd d MMMM");
clock.writeConfig("use24hFormat", 2);
clock.currentConfigGroup = [];
clock.writeConfig("UserBackgroundHints", "NoBackground");
y += 165;

function monitor(px, py, w, h, title, face, high, total, colors) {
    var m = d.addWidget("org.kde.plasma.systemmonitor", px, py, w, h);
    m.currentConfigGroup = ["Appearance"];
    m.writeConfig("chartFace", face);
    m.writeConfig("title", title);
    m.writeConfig("showTitle", true);
    m.currentConfigGroup = ["Sensors"];
    m.writeConfig("highPrioritySensorIds", JSON.stringify(high));
    if (total) m.writeConfig("totalSensors", JSON.stringify(total));
    m.currentConfigGroup = ["SensorColors"];
    for (var k in colors) m.writeConfig(k, colors[k]);
    m.currentConfigGroup = [];
    m.writeConfig("UserBackgroundHints", "ShadowBackground");
    return m;
}
var ring = "org.kde.ksysguard.piechart";
monitor(x,       y, 112, 140, "CPU", ring, ["cpu/all/usage"], ["cpu/all/usage"], {"cpu/all/usage": BLUE});
monitor(x + 124, y, 112, 140, "GPU", ring, ["gpu/gpu0/usage"], ["gpu/gpu0/usage"], {"gpu/gpu0/usage": TEAL});
monitor(x + 248, y, 112, 140, "RAM", ring, ["memory/physical/usedPercent"], ["memory/physical/usedPercent"], {"memory/physical/usedPercent": STEEL});
y += 160;
monitor(x, y, 360, 170, "Network", "org.kde.ksysguard.linechart",
        ["network/all/download", "network/all/upload"], null,
        {"network/all/download": TEAL, "network/all/upload": BLUE});
