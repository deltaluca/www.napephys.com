$(document).ready(function () {
    (function () {
        var menu = $("#submenu");
        if (!menu) return;

        var navbar = $('<div class="subnav-bar"></div>');
        menu.append(navbar);

        var locations = page.split("~");
        locations.reverse();

        var i, loc;
        for (i = 0; i < locations.length; i ++) {
            loc = locations[i];
            var paths = loc.split("/");
            var cpage = paths.pop();
            locations[i] = {
                name : cpage.split(".")[0],
                path : (paths.length > 0 ? paths.join("/") + "/" : "") + cpage.toLowerCase()
            };
        }

        for (i = 0; i < locations.length; i ++) {
            loc = locations[i];
            var name = $('<span class="subspan"></span>');
            if (i !== 0) {
                name.append($('<a href="'+loc.path+'">'+loc.name+'</a>'));
                navbar.append($('<span class="subdiv">&gt;</span>'));
            }
            else {
                name.html(loc.name);
            }
            navbar.append(name);
        }
    })();
});
