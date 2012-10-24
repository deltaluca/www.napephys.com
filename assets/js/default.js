$(document).ready(function () {
    // Menu.
    (function() {
        var menu = $("#menu");
        if (!menu) return;

        var navbar = $('<div class="nav-bar"></div>');
        menu.append(navbar);
        navbar.append($('<div class="nav-left"></div>'));

        var items = ["Home","Samples","Downloads","Help","Contributors"];
        for (var i = 0; i < items.length; i++) {
            var navitem = $('<div class="nav-item"></div>');
            navbar.append(navitem);
            var name = items[i];
            var url = (name == "Home" ? "index" : name.toLowerCase());
            if (page == name) {
                navitem.append($('<a class="nav-disabled">'+name+'</a>'));
            }
            else {
                navitem.append($('<a class="nav-scroll" href="'+root+url+'.html">'+name+'</a>'));
            }
        }
    })();

    // Title.
    (function() {
        var title = $("#title");
        if (!title) return;

        title.addClass("title");
        var rt = root;
        var left = $('<img class="title-image" src="'+rt+'assets/nape.png" alt="nape-logo"/>');
        var right = $('<table class="title-right"></table>');
        var topRow = $('<tr></tr>');
        right.append(topRow);
        topRow.append($('<td></td>').
              append($('<span class="title-font">Nape Physics Engine</span>')).
              append($('<span class="title-font-sm"> / Cross platform 2D physics for AS3/Haxe</span>'))
        );
        topRow.append($('<td width="auto"></td>').
              append($('<a href="http://www.github.com/deltaluca"><img class="github" src="'+rt+'assets/github.png" alt="github"/></a>'))
        );
        right.append($('<tr class="menu-space"><td></td></tr>'));


        title.append($('<table style="width: 100%"></table>').append($('<tr></tr>').
                append($('<td></td>').append(left)).
                append($('<td></td>').append(right))
        ));
    })();
});
