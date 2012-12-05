haxe:
	haxe -cp . -cp "/" -cp ../common \
		-main Portals -swf main.swf -swf-header 800:600:60:333333 -swf-version 11 \
		-lib nape -D haxe3 -D NAPE_RELEASE_BUILD --dce full
	flib --combine ../preloader/preloader.swf main.swf Portals.swf

as3:
	mxmlc Portals.as -o main.swf \
		--default-background-color 0x333333 \
        --default-frame-rate 60 \
        --default-size 800 600 \
        -source-path ../common \
		--include-libraries ../../nape-release.swc --static-link-runtime-shared-libraries
	flib --combine ../preloader/preloader.swf main.swf Portals.swf
