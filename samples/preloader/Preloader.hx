import flash.Lib;
import flash.display.Sprite;
import flash.events.Event;

class Preloader extends Sprite {
    static function main() {
        flash.Lib.current.addChild(new Preloader());
    }

    function new() {
        super();
        if (stage != null) {
            init(null);
        }
        else {
            addEventListener(Event.ADDED_TO_STAGE, init);
        }
    }

    function init(ev) {
        if (ev != null) {
            removeEventListener(Event.ADDED_TO_STAGE, init);
        }

        addEventListener(Event.ENTER_FRAME, enterFrame);
    }

    function enterFrame(ev) {
        var total = stage.loaderInfo.bytesTotal;
        var loaded = stage.loaderInfo.bytesLoaded;

        if (loaded == total) {
            removeEventListener(Event.ENTER_FRAME, enterFrame);
            dispatchEvent(new Event("nextFrame"));
            return;
        }

        var fraction = (loaded / total);
        var x = stage.stageWidth / 2;
        var y = stage.stageHeight / 2;

        var barWidth = 128;
        var barHeight = 8;

        graphics.clear();

        graphics.lineStyle(0, 0, 0);
        graphics.beginFill(0xa0a0a0, 1);
        graphics.drawRect(x - (barWidth / 2), y - (barHeight / 2), barWidth * fraction, barHeight);
        graphics.endFill();

        graphics.lineStyle(2, 0x000000, 1);
        graphics.drawRect(x - (barWidth / 2), y - (barHeight / 2), barWidth, barHeight);
    }

}
