package;

import flash.display.StageQuality;
import flash.display.Sprite;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.Event;
import flash.system.System;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.Lib;

import nape.space.Space;
import nape.space.Broadphase;
import nape.phys.Body;
import nape.phys.BodyList;
import nape.phys.BodyType;
import nape.shape.Polygon;
import nape.geom.Vec2;
import nape.util.Debug;
import nape.util.BitmapDebug;
import nape.util.ShapeDebug;
import nape.constraint.PivotJoint;

typedef TemplateParams = {
    ?gravity : Vec2,
    ?shapeDebug : Bool,
    ?broadphase : Broadphase,
    ?noSpace : Bool,
    ?noHand : Bool,
    ?generator : Vec2->Void,
    ?variableStep : Bool,
    ?noReset : Bool
};

class Template extends Sprite {

    var space:Space;
    var debug:Debug;
    var hand:PivotJoint;

    var variableStep:Bool;
    var prevTime:Int;

    var smoothFps:Float = -1;
    var textField:TextField;
    var baseMemory:Float;

    var params:TemplateParams;
    var useHand:Bool;
    function new(params:TemplateParams) {
        baseMemory = System.totalMemoryNumber;
        super();

        this.params = params;
        if (stage != null) {
            start(null);
        }
        else {
           addEventListener(Event.ADDED_TO_STAGE, start);
        }
    }

    function start(ev) {
        if (ev != null) {
            removeEventListener(Event.ADDED_TO_STAGE, start);
        }

        if (params.noSpace == null || !params.noSpace) {
            space = new Space(params.gravity, params.broadphase);

            if (useHand = (params.noHand == null || !params.noHand)) {
                hand = new PivotJoint(space.world, null, Vec2.weak(), Vec2.weak());
                hand.active = false;
                hand.stiff = false;
                hand.maxForce = 5e4;
                hand.space = space;
                stage.addEventListener(MouseEvent.MOUSE_UP, handMouseUp);
            }
            stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
        }

        if (params.noReset == null || !params.noReset) {
            stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
            stage.addEventListener(KeyboardEvent.KEY_UP, keyUp);
        }

        if (params.shapeDebug == null || !params.shapeDebug) {
            debug = new BitmapDebug(stage.stageWidth, stage.stageHeight, stage.color);
        }
        else {
            debug = new ShapeDebug(stage.stageWidth, stage.stageHeight, stage.color);
            stage.quality = StageQuality.LOW;
        }

        debug.drawConstraints = true;
        addChild(debug.display);

        variableStep = (params.variableStep != null && params.variableStep);
        prevTime = Lib.getTimer();
        addEventListener(Event.ENTER_FRAME, enterFrame);

        init();

        textField = new TextField();
        textField.defaultTextFormat = new TextFormat("Arial", null, 0xffffff);
        textField.selectable = false;
        textField.width = 128;
        textField.height = 64;
        addChild(textField);
    }

    function random() return Math.random()

    function createBorder() {
        var border = new Body(BodyType.STATIC);
        border.shapes.add(new Polygon(Polygon.rect(0, 0, -2, stage.stageHeight)));
        border.shapes.add(new Polygon(Polygon.rect(0, 0, stage.stageWidth, -2)));
        border.shapes.add(new Polygon(Polygon.rect(stage.stageWidth, 0, 2, stage.stageHeight)));
        border.shapes.add(new Polygon(Polygon.rect(0, stage.stageHeight, stage.stageWidth, 2)));
        border.space = space;
        border.debugDraw = false;
    }

    // to be overriden
    function init() {}
    function update(deltaTime:Float) {}
    function postUpdate() {}

    var resetted = false;
    function keyUp(ev:KeyboardEvent) {
        // 'r'
        if (ev.keyCode == 82) {
            resetted = false;
        }
    }
    function keyDown(ev:KeyboardEvent) {
        // 'r'
        if (ev.keyCode == 82 && !resetted) {
            resetted = true;
            if (space != null) {
                space.clear();
                if (hand != null) {
                    hand.active = false;
                    hand.space = space;
                }
            }
            System.pauseForGCIfCollectionImminent(0);
            init();
        }
    }

    var bodyList:BodyList = null;
    function mouseDown(_) {
        var mp = Vec2.get(mouseX, mouseY);
        if (useHand) {
            // re-use the same list each time.
            bodyList = space.bodiesUnderPoint(mp, null, bodyList);

            for (body in bodyList) {
                if (body.isDynamic()) {
                    hand.body2 = body;
                    hand.anchor2 = body.worldPointToLocal(mp, true);
                    hand.active = true;
                    break;
                }
            }

            // recycle nodes.
            bodyList.clear();

            if (!hand.active) {
                if (params.generator != null) {
                    params.generator(mp);
                }
            }
        }
        else {
            if (params.generator != null) {
                params.generator(mp);
            }
        }
        mp.dispose();
    }

    function handMouseUp(_) {
        hand.active = false;
    }

    function enterFrame(_) {
        var curTime = Lib.getTimer();
        var deltaTime:Float = (curTime - prevTime);
        if (deltaTime == 0) {
            return;
        }

        var fps = (1000 / deltaTime);
        smoothFps = (smoothFps == -1 ? fps : (smoothFps * 0.99) + (fps * 0.01));
        textField.text = "fps: " + ((""+smoothFps).substr(0, 5)) + "\n" +
                         "mem: " + ((""+(System.totalMemoryNumber - baseMemory) / (1024 * 1024)).substr(0, 5)) + "Mb";

        if (hand != null && hand.active) {
            hand.anchor1.setxy(mouseX, mouseY);
            hand.body2.angularVel *= 0.9;
        }

        debug.clear();

        if (variableStep) {
            if (deltaTime > (1000 / 30)) {
                deltaTime = (1000 / 30);
            }
            update(deltaTime * 0.001);
            if (space != null) {
                space.step(deltaTime * 0.001);
            }
            prevTime = curTime;
        }
        else {
            var stepSize = (1000 / stage.frameRate);
            stepSize = 1000/60;
            var steps = Math.round(deltaTime / stepSize);

            var delta = Math.round(deltaTime - (steps * stepSize));
            prevTime = (curTime - delta);
            if (steps > 4) {
                steps = 4;
            }

            while (steps-- > 0) {
                update(stepSize * 0.001);
                if (space != null) {
                    space.step(stepSize * 0.001);
                }
            }
        }

        if (space != null) {
            debug.draw(space);
        }
        postUpdate();
        debug.flush();
    }
}
