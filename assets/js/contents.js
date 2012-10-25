$(document).ready(function () {
    var contents = $(".contents");
    if (!contents) return;

    var chapters = $(".chapter");
    chapters = jQuery.map(chapters, function (chapter, index) {
        var title = $(chapter).find(".title");
        title.before($('<span class="chapter-number">'+(index+1)+'</span>'));
        title.after($('<br/>'));
        $(chapter).attr("id", title.html());

        var sections = jQuery.map($(chapter).find(".section"), function (section, index2) {
            var stitle = $(section).html();
            $(section).before($('<span class="section-number">'+(index+1)+"."+(index2+1)+'</span>'));
            $(section).after($('<br/>'));
            $(section).attr("id", title.html()+"."+stitle);
            return {
                section : section,
                title : stitle
            }
        });

        return {
            chapter : chapter,
            title : title.html(),
            sections : sections
        }
    });

    contents.addClass("contents");
    jQuery.each(chapters, function (index, chapter) {
        jQuery.each(contents, function (_, content) {
            if ($(content).attr("id").substr(5) != chapter.title) {
                $(content).append($('<span><a href="#'+chapter.title+'">'+(index + 1) + " " + chapter.title + '</a></span><br/>'));
            }
            else {
                $(content).append($('<span><a class="disabled">'+(index + 1) + " " + chapter.title + '</a></span><br/>'));
                var table = $('<table class="section-contents"></table>');
                $(content).append(table);
                jQuery.each(chapter.sections, function (i, section) {
                    table.append($('<tr></tr>').
                          append($('<td></td>').
                          append($('<span class="subcontent"><a href="#'+chapter.title+'.'+section.title+'">'+(index + 1)+"."+(i + 1)+" "+section.title + '</a></span><br/>'))
                    ));
                });
            }
        });
    });
});
