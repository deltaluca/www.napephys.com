package;

/**
 *
 * Sample: Basic Simulation
 * Author: Luca Deltodesco
 *
 * In this sample, I show how to construct the most basic of Nape
 * simulations, together with a debug display.
 *
 */

import flash.display.Sprite;
import flash.events.Event;
import flash.events.KeyboardEvent;

import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.shape.Circle;
import nape.shape.Polygon;
import nape.space.Space;
import nape.util.BitmapDebug;
import nape.util.Debug;

class BasicSimulation extends Sprite {

    var space:Space;
    var debug:Debug;

    function new() {
        super();

        if (stage != null) {
            initialise(null);
        }
        else {
            addEventListener(Event.ADDED_TO_STAGE, initialise);
        }
    }

    function initialise(ev:Event):Void {
        if (ev != null) {
            removeEventListener(Event.ADDED_TO_STAGE, initialise);
        }

        // Create a new simulation Space.
        //   Weak Vec2 will be automatically sent to object pool.
        //   when used as argument to Space constructor.
        var gravity = Vec2.weak(0, 600);
        space = new Space(gravity);

        // Create a new BitmapDebug screen matching stage dimensions and
        // background colour.
        //   The Debug object itself is not a DisplayObject, we add its
        //   display property to the display list.
        debug = new BitmapDebug(stage.stageWidth, stage.stageHeight, stage.color);
        addChild(debug.display);

        setUp();

        stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
        stage.addEventListener(Event.ENTER_FRAME, enterFrameHandler);
    }

    function setUp() {
        var w = stage.stageWidth;
        var h = stage.stageHeight;

        // Create the floor for the simulation.
        //   We use a STATIC type object, and give it a single
        //   Polygon with vertices defined by Polygon.rect utility
        //   whose arguments are (x, y) of top-left corner and the
        //   width and height.
        //
        //   A static object does not rotate, so we don't need to
        //   care that the origin of the Body (0, 0) is not in the
        //   centre of the Body's shapes.
        var floor = new Body(BodyType.STATIC);
        floor.shapes.add(new Polygon(Polygon.rect(50, (h - 50), (w - 100), 1)));
        floor.space = space;

        // Create a tower of boxes.
        //   We use a DYNAMIC type object, and give it a single
        //   Polygon with vertices defined by Polygon.box utility
        //   whose arguments are the width and height of box.
        //
        //   Polygon.box(w, h) === Polygon.rect((-w / 2), (-h / 2), w, h)
        //   which means we get a box whose centre is the body origin (0, 0)
        //   and that when this object rotates about its centre it will
        //   act as expected.
        for (i in 0...16) {
            var box = new Body(BodyType.DYNAMIC);
            box.shapes.add(new Polygon(Polygon.box(16, 32)));
            box.position.setxy((w / 2), ((h - 50) - 32 * (i + 0.5)));
            box.space = space;
        }

        // Create the rolling ball.
        //   We use a DYNAMIC type object, and give it a single
        //   Circle with radius 50px. Unless specified otherwise
        //   in the second optional argument, the circle is always
        //   centered at the origin.
        //
        //   we give it an angular velocity so when it touched
        //   the floor it will begin rolling towards the tower.
        var ball = new Body(BodyType.DYNAMIC);
        ball.shapes.add(new Circle(50));
        ball.position.setxy(50, h / 2);
        ball.angularVel = 10;
        ball.space = space;

        // In each case we have used for adding a Shape to a Body
        //    body.shapes.add(shape);
        // We can also use:
        //    shape.body = body;
        //
        // And for adding the Body to a Space:
        //    body.space = space;
        // We can also use:
        //    space.bodies.add(body);
    }

    function enterFrameHandler(ev:Event):Void {
        // Step forward in simulation by the required number of seconds.
        space.step(1 / stage.frameRate);

        // Render Space to the debug draw.
        //   We first clear the debug screen,
        //   then draw the entire Space,
        //   and finally flush the draw calls to the screen.
        debug.clear();
        debug.draw(space);
        debug.flush();
    }

    function keyDownHandler(ev:KeyboardEvent):Void {
        if (ev.keyCode == 82) { // 'R'
            // space.clear() removes all bodies (and constraints of
            // which we have none) from the space.
            space.clear();

            setUp();
        }
    }

    static function main() {
        flash.Lib.current.addChild(new BasicSimulation());
    }
}
