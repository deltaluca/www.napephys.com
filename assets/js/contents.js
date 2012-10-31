$(document).ready(function () {
    var contents = $(".contents");
    if (!contents) return;

    var chapters = $(".chapter");
    chapters = jQuery.map(chapters, function (chapter, index) {
        var title = $(chapter).find(".title");
        title.before($('<span class="chapter-number">'+(index+1)+'</span>'));
        title.after($('<br/>'));
        $(chapter).attr("id", title.html().split(" ").join("_"));

        var sections = jQuery.map($(chapter).find(".section"), function (section, index2) {
            var stitle = $(section).html();
            $(section).before($('<span class="section-number">'+(index+1)+"."+(index2+1)+'</span>'));
            $(section).after($('<br/>'));
            $(section).attr("id", title.html().split(" ").join("_")+"."+stitle.split(" ").join("_"));
            return {
                section : section,
                title : stitle.split(" ").join("_")
            }
        });

        return {
            chapter : chapter,
            title : title.html().split(" ").join("_"),
            sections : sections
        }
    });

    contents.addClass("contents");
    jQuery.each(chapters, function (index, chapter) {
        jQuery.each(contents, function (_, content) {
            if ($(content).attr("id").substr(5).split(" ").join("_") != chapter.title) {
                $(content).append($('<span><a href="#'+chapter.title+'">'+(index + 1) + " " + chapter.title.split("_").join(" ") + '</a></span><br/>'));
            }
            else {
                $(content).append($('<span><a class="disabled">'+(index + 1) + " " + chapter.title.split("_").join(" ") + '</a></span><br/>'));
                var table = $('<table class="section-contents"></table>');
                $(content).append(table);
                jQuery.each(chapter.sections, function (i, section) {
                    table.append($('<tr></tr>').
                          append($('<td></td>').
                          append($('<span class="subcontent"><a href="#'+chapter.title+'.'+section.title+'">'+(index + 1)+"."+(i + 1)+" "+section.title.split("_").join(" ") + '</a></span><br/>'))
                    ));
                });
            }
        });
    });
});
