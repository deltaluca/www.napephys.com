package {

    import flash.display.StageQuality;
    import flash.display.Sprite;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.events.Event;
    import flash.system.System;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.utils.getTimer;

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

    public class Template extends Sprite {

        protected var space:Space;
        protected var debug:Debug;
        protected var hand:PivotJoint;

        protected var variableStep:Boolean;
        protected var prevTime:int;

        protected var smoothFps:Number = -1;
        protected var textField:TextField;
        protected var baseMemory:Number;

        protected var velIterations:int = 10;
        protected var posIterations:int = 10;
        protected var customDraw:Boolean = false;

        protected var params:Object;
        protected var useHand:Boolean;

        public function Template(params:Object):void {
            baseMemory = System.totalMemoryNumber;
            super();

            if (params.velIterations != null) {
                velIterations = params.velIterations;
            }
            if (params.posIterations != null) {
                posIterations = params.posIterations;
            }
            if (params.customDraw != null) {
                customDraw = params.customDraw;
            }

            this.params = params;
            if (stage != null) {
                start(null);
            }
            else {
               addEventListener(Event.ADDED_TO_STAGE, start);
            }
        }

        private function start(ev:Event):void {
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
            prevTime = getTimer();
            addEventListener(Event.ENTER_FRAME, enterFrame);

            init();

            textField = new TextField();
            textField.defaultTextFormat = new TextFormat("Arial", null, 0xffffff);
            textField.selectable = false;
            textField.width = 128;
            textField.height = 80;
            addChild(textField);
        }

        protected function random():Number {
            return Math.random();
        }

        protected function createBorder():void {
            var border:Body = new Body(BodyType.STATIC);
            border.shapes.add(new Polygon(Polygon.rect(0, 0, -2, stage.stageHeight)));
            border.shapes.add(new Polygon(Polygon.rect(0, 0, stage.stageWidth, -2)));
            border.shapes.add(new Polygon(Polygon.rect(stage.stageWidth, 0, 2, stage.stageHeight)));
            border.shapes.add(new Polygon(Polygon.rect(0, stage.stageHeight, stage.stageWidth, 2)));
            border.space = space;
            border.debugDraw = false;
        }

        // to be overriden
        protected function init():void {}
        protected function update(deltaTime:Number):void {}
        protected function postUpdate(deltaTime:Number):void {}

        private var resetted:Boolean = false;
        private function keyUp(ev:KeyboardEvent):void {
            // 'r'
            if (ev.keyCode == 82) {
                resetted = false;
            }
        }
        private function keyDown(ev:KeyboardEvent):void {
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

        private var bodyList:BodyList = null;
        private function mouseDown(ev:MouseEvent):void {
            var mp:Vec2 = Vec2.get(mouseX, mouseY);
            if (useHand) {
                // re-use same list each time.
                bodyList = space.bodiesUnderPoint(mp, null, bodyList);
                for (var i:uint = 0; i < bodyList.length; i++) {
                    var body:Body = bodyList.at(i);
                    if (body.isDynamic()) {
                        hand.body2 = body;
                        hand.anchor2 = body.worldPointToLocal(mp, true);
                        hand.active = true;
                        break;
                    }
                }

                // recycle nodes
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

        private function handMouseUp(ev:MouseEvent):void {
            hand.active = false;
        }

        private function enterFrame(ev:Event):void {
            var curTime:uint = getTimer();
            var deltaTime:Number = (curTime - prevTime);
            if (deltaTime == 0) {
                return;
            }

            var fps:Number = (1000 / deltaTime);
            smoothFps = (smoothFps == -1 ? fps : (smoothFps * 0.99) + (fps * 0.01));
            var text:String = "fps: " + ((""+smoothFps).substr(0, 5)) + "\n" +
                              "mem: " + ((""+(System.totalMemoryNumber - baseMemory) / (1024 * 1024)).substr(0, 5)) + "Mb";
            if (space != null) {
                text += "\n\n"+
                        "velocity-iterations: " + velIterations + "\n" +
                        "position-iterations: " + posIterations + "\n";
            }
            textField.text = text;

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
                    space.step(deltaTime * 0.001, velIterations, posIterations);
                }
                prevTime = curTime;
            }
            else {
                var stepSize:Number = (1000 / stage.frameRate);
                stepSize = 1000/60;
                var steps:uint = Math.round(deltaTime / stepSize);

                var delta:Number = Math.round(deltaTime - (steps * stepSize));
                prevTime = (curTime - delta);
                if (steps > 4) {
                    steps = 4;
                }
                deltaTime = steps * stepSize;

                while (steps-- > 0) {
                    update(stepSize * 0.001);
                    if (space != null) {
                        space.step(stepSize * 0.001, velIterations, posIterations);
                    }
                }
            }

            if (space != null && !customDraw) {
                debug.draw(space);
            }
            postUpdate(deltaTime * 0.001);
            debug.flush();
        }
    }
}
