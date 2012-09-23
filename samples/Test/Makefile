all:
	haxe -cp . -cp '\' -cp ../common \
         -main Test -swf main.swf -swf-header 800:600:60:333333 -swf-version 11 \
         -lib nape -D haxe3
	flib --combine ../preloader/preloader.swf main.swf Test.swf
