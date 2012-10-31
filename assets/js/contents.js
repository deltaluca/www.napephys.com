$(document).ready(function () {
    var contents = $(".contents");
    if (!contents) return;

    function titleURL(title) {
        return title.split(" ").join("_").split("&amp;").join("__");
    }

    var chapters = $(".chapter");
    chapters = jQuery.map(chapters, function (chapter, index) {
        var title = $(chapter).find(".title");
        title.before($('<span class="chapter-number">'+(index+1)+'</span>'));
        title.after($('<br/>'));
        var title_url = titleURL(title.html());
        $(chapter).attr("id", title_url);

        var sections = jQuery.map($(chapter).find(".section"), function (section, index2) {
            var stitle = $(section).html();
            $(section).before($('<span class="section-number">'+(index+1)+"."+(index2+1)+'</span>'));
            $(section).after($('<br/>'));
            var stitle_url = titleURL(stitle);
            $(section).attr("id", title_url+"."+stitle_url);
            return {
                section : section,
                title : stitle,
                url : stitle_url
            }
        });

        return {
            chapter : chapter,
            title : title.html(),
            url : title_url,
            sections : sections
        }
    });

    contents.addClass("contents");
    jQuery.each(chapters, function (index, chapter) {
        jQuery.each(contents, function (_, content) {
            if ($(content).attr("id").substr(5) != chapter.title.split("&amp;").join("&")) {
                $(content).append($('<span><a href="#'+chapter.url+'">'+(index + 1) + " " + chapter.title + '</a></span><br/>'));
            }
            else {
                $(content).append($('<span><a class="disabled">'+(index + 1) + " " + chapter.title + '</a></span><br/>'));
                var table = $('<table class="section-contents"></table>');
                $(content).append(table);
                jQuery.each(chapter.sections, function (i, section) {
                    table.append($('<tr></tr>').
                          append($('<td></td>').
                          append($('<span class="subcontent"><a href="#'+chapter.url+'.'+section.url+'">'+(index + 1)+"."+(i + 1)+" "+section.title + '</a></span><br/>'))
                    ));
                });
            }
        });
    });
});
