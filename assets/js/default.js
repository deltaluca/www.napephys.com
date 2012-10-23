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
                navitem.append($('<a class="nav-scroll" href="'+url+'.html">'+name+'</a>'));
            }
        }
    })();

    // Title.
    (function() {
        var title = $("#title");
        if (!title) return;

        title.addClass("title");
        var left = $('<img class="title-image" src="assets/nape.png" alt="nape-logo"/>');
        var right = $('<table class="title-right"></table>');
        var topRow = $('<tr></tr>');
        right.append(topRow);
        topRow.append($('<td></td>').
              append($('<span class="title-font">Nape Physics Engine</span>')).
              append($('<span class="title-font-sm"> / Cross platform 2D physics for AS3/Haxe</span>'))
        );
        topRow.append($('<td width="auto"></td>').
              append($('<a href="http://www.github.com/deltaluca/nape"><img class="github" src="assets/github.png" alt="github"/></a>'))
        );
        right.append($('<tr class="menu-space"><td></td></tr>'));


        title.append($('<table style="width: 100%"></table>').append($('<tr></tr>').
                append($('<td></td>').append(left)).
                append($('<td></td>').append(right))
        ));
    })();

    // Sample panel.
    // ==========================================

    var oldHash;
    var sampleName
    function fadeInSample(name) {
        oldHash = window.location.hash;
        sampleName = name;

        // Fade in overlay and panels.
        var overlay = $("#sample-overlay");
        var panel = $("#sample-panel");

        overlay.css("display", "block");
        overlay.css("opacity", 0);
        overlay.fadeTo(200, 0.4);
        panel.css("dispaly", "block");
        panel.css("opactity", 0);
        panel.fadeTo(200, 1.0);

        // Set title name.
        $("#sample-title").html(name);
    }

    function sampleSWF() {
        window.location.hash = ("swf-" + sampleName);

        var name = $("#sample-title").html();
        $("#sample-panel-content").empty();
        $("#sample-panel-content").flash(
            { src: "samples/"+name+"/"+name+".swf",
              bgColor: 333333,
              width: 800,
              height: 600, },
            { version: '11.0.0' }
        );
        $("#sample-panel-content").removeAttr("style");
        $("#sample-panel-content").css("background-color", "#333333");

        $("#sample-tab-swf").addClass("tab-disabled").
                             removeClass("tab-enabled").
                             removeAttr('href');

        $("#sample-info").css("display", "inline");
        $("#sample-info").load("samples/"+name+"/instructions.html",
            function (_, status, _) {
                if (status === "error") {
                    $(this).html("Could not load file!");
                }
            });

        var as3 = $("#sample-tab-as3");
        if (as3.hasClass("tab-disabled")) {
            as3.addClass("tab-enabled").
                removeClass("tab-disabled").
                attr('href', '#as3');
        }

        var haxe = $("#sample-tab-haxe");
        if (haxe.hasClass("tab-disabled")) {
            haxe.addClass("tab-enabled").
                 removeClass("tab-disabled").
                 attr('href', '#haxe');
        }
    }

    function sampleAS3() {
        window.location.hash = ("as3-" + sampleName);

        $("#sample-panel-content").html('');
        $("#sample-panel-content").empty();
        var pre = $('<pre class="prettyprint darkered codestyle linenums"></pre>');
        $("#sample-panel-content").append(pre);

        $.ajax({
            url: "samples/"+sampleName+"/"+sampleName+".as",
            mimeType: "text/plain",
            processData: false,
            success : function (data) {
                pre.html(data);
                prettyPrint();
            },
            error : function () {
                pre.html("Could not load file!");
            }
        });

        $("#sample-info").css("display", "none");

        $("#sample-panel-content").css("overflow", "auto");
        $("#sample-tab-as3").addClass("tab-disabled").
                             removeClass("tab-enabled").
                             removeAttr('href');

        var swf = $("#sample-tab-swf");
        if (swf.hasClass("tab-disabled")) {
            $("#sample-panel-content").removeClass("flash-replaced");
            swf.addClass("tab-enabled").
                removeClass("tab-disabled").
                attr('href', '#swf');
        }

        var haxe = $("#sample-tab-haxe");
        if (haxe.hasClass("tab-disabled")) {
            haxe.addClass("tab-enabled").
                 removeClass("tab-disabled").
                 attr('href', '#haxe');
        }
    }

    function sampleHaxe() {
        window.location.hash = ("haxe-" + sampleName);

        $("#sample-panel-content").html('');
        $("#sample-panel-content").empty();
        var pre = $('<pre class="prettyprint darkered codestyle linenums"></pre>');
        $("#sample-panel-content").append(pre);

        $.ajax({
            url: "samples/"+sampleName+"/"+sampleName+".hx",
            mimeType: "text/plain",
            processData: false,
            success : function (data) {
                pre.html(data);
                prettyPrint();
            },
            error : function () {
                pre.html("Could not load file!");
            }
        });

        $("#sample-info").css("display", "none");

        $("#sample-panel-content").css("overflow", "auto");
        $("#sample-tab-haxe").addClass("tab-disabled").
                              removeClass("tab-enabled").
                              removeAttr('href');

        var swf = $("#sample-tab-swf");
        if (swf.hasClass("tab-disabled")) {
            $("#sample-panel-content").removeClass("flash-replaced");
            swf.addClass("tab-enabled").
                removeClass("tab-disabled").
                attr('href', '#swf');
        }

        var as3 = $("#sample-tab-as3");
        if (as3.hasClass("tab-disabled")) {
            as3.addClass("tab-enabled").
                removeClass("tab-disabled").
                attr('href', '#as3');
        }
    }


    $("#sample-close").click(function (event) {
        // Reset hash, keep current scroll positions.
        var x = $(window).scrollLeft();
        var y = $(window).scrollTop();
        window.location.hash = oldHash;
        window.scrollTo(x, y);
        event.preventDefault();

        // fade out sample box and overlay.
        $("#sample-overlay").fadeTo(200, 0, function () {
            $(this).css("display", "none");
        });
        $("#sample-panel").fadeTo(200, 0, function () {
            $(this).css("display", "none");
        });

        // Clear sample content.
        $("#sample-panel-content").html("");
    });

    $(".sample-link").click(function (event) {
        var name = $(this).attr("id");
        fadeInSample(name);
        sampleSWF();
    });

    $(".sample-link").hover(function (event) {
        $(this).fadeTo(100, 0.6);
    }, function (event) {
        $(this).fadeTo(100, 1.0);
    });

    $(".tab-enabled").click(function (event) {
        event.preventDefault();

        if ($(this).hasClass("tab-disabled")) {
            return;
        }

        console.log("hiya" + $(this).attr('href'));
        var href = $(this).attr('href');
        if (href === '#swf') {
            sampleSWF();
        }
        else if (href === '#as3') {
            sampleAS3();
        }
        else if (href === '#haxe') {
            sampleHaxe();
        }
    });

    $(window).resize(function () {
        var samplePanel = $("#sample-panel");

        var width  = $(window).width();
        var height = $(window).height();

        var boxWidth  = parseInt(samplePanel.css("width"));
        var boxHeight = parseInt(samplePanel.css("height"));

        var leftValue = (width  >= boxWidth  ? ((width / 2)  - (boxWidth / 2))  : (width  - boxWidth));
        var topValue  = (height >= boxHeight ? ((height / 2) - (boxHeight / 2)) : (height - boxHeight));

        samplePanel.css("left", (leftValue + "px"));
        samplePanel.css("top",  (topValue  + "px"));
    });
    $(window).resize();

    // Pretty Print code segments.
    // ==========================================
    prettyPrint();

    // Add doc links.
    // ==========================================
    applyDocLinks();

    // Handle sample #hash-tags
    // ==========================================
    var hash = window.location.hash;
    if (hash) {
        if (hash.substr(0, 5) === '#swf-') {
            var pos = $('#samples').offset();
            window.scrollTo(pos.left, pos.top);

            var name = hash.substr(5);
            fadeInSample(name);
            sampleSWF();
        }
        else if (hash.substr(0, 5) === '#as3-') {
            var pos = $('#samples').offset();
            window.scrollTo(pos.left, pos.top);

            var name = hash.substr(5);
            fadeInSample(name);
            sampleAS3();
        }
        else if (hash.substr(0, 6) === '#haxe-') {
            var pos = $('#samples').offset();
            window.scrollTo(pos.left, pos.top);

            var name = hash.substr(6);
            fadeInSample(name);
            sampleHaxe();
        }
    }
});
