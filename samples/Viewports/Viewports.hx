package;

/**
 *
 * Sample: Viewports
 * Author: Luca Deltodesco
 *
 * In this sample, I show how you can use the Nape callbacks system
 * to very effeciently keep track of what objects in a physics world
 * are visible.
 *
 * Whilst it is possible to use the spatial query methods of the Space
 * object such as bodiesInShape to achieve the same overall result,
 * we achieve greater performance by using the nape 'pipeline' as it
 * were instead: Both because we only perform actions when an object
 * changes its visible status, and because it is faster to determine
 * intersections in this way, than it is by using the spatial methods.
 */

import nape.callbacks.CbEvent;
import nape.callbacks.CbType;
import nape.callbacks.InteractionCallback;
import nape.callbacks.InteractionListener;
import nape.callbacks.InteractionType;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.phys.Compound;
import nape.shape.Circle;
import nape.shape.Polygon;
import nape.shape.Shape;
import nape.util.Debug;

// Template class is used so that this sample may
// be as concise as possible in showing Nape features without
// any of the boilerplate that makes up the sample interfaces.
import Template;

import flash.display.DisplayObject;

class Viewports extends Template {
    function new() {
        super({
            // We're going to draw things in a non-standard way
            // so tell Template not to auto-draw Space.
            customDraw: true
        });
    }

    var viewports:Compound;
    var viewableObjects:Array<Body>;

    override function init() {
        var w = stage.stageWidth;
        var h = stage.stageHeight;

        createBorder();

        // Super high drag.
        space.worldLinearDrag = 5;
        space.worldAngularDrag = 5;

        // and strength default hand joint settings.
        hand.maxForce = Math.POSITIVE_INFINITY;
        hand.frequency = 100;

        // Set up callback logic for viewport interactions.
        // We shove all viewport bodies into a single Compound
        // over which we listen for begin/end sensor events.
        //
        // like this we get a single begin/end when an object
        // leaves or enters the union of all viewport areas.
        var viewportType = new CbType();
        var viewableType = new CbType();

        viewports = new Compound();
        viewports.cbTypes.add(viewportType);
        viewports.space = space;

        space.listeners.add(new InteractionListener(
           CbEvent.BEGIN, InteractionType.SENSOR,
           viewportType,
           viewableType,
           enterViewportHandler
        ));
        space.listeners.add(new InteractionListener(
            CbEvent.END, InteractionType.SENSOR,
            viewportType,
            viewableType,
            exitViewportHandler
        ));

        // Create a couple of viewports
        var viewport = new Body();
        viewport.position.setxy(w/3, h/2);
        viewport.compound = viewports;

        var viewportShape:Shape = new Polygon(Polygon.box(150, 150));
        viewportShape.sensorEnabled = true;
        viewportShape.body = viewport;

        // Aaaand another.
        viewport = new Body();
        viewport.position.setxy(2*w/3, h/2);
        viewport.compound = viewports;

        viewportShape = new Circle(80);
        viewportShape.sensorEnabled = true;
        viewportShape.body = viewport;

        // Generate some random objects with graphics.

        if (viewableObjects != null) {
            // on reset need to remove old ones from stage.
            for (b in viewableObjects) {
                removeChild(b.userData.graphic);
            }
        }

        viewableObjects = [];
        for (i in 0...100) {
            var body = new Body();
            body.cbTypes.add(viewableType);
            viewableObjects.push(body);

            // Add random one of either a Circle, Box or Pentagon.
            if (Math.random() < 0.33) {
                body.shapes.add(new Circle(20));
            }
            else if (Math.random() < 0.5) {
                body.shapes.add(new Polygon(Polygon.box(40, 40)));
            }
            else {
                body.shapes.add(new Polygon(Polygon.regular(20, 20, 5)));
            }

            // Set to random position on stage and add to Space.
            body.position.setxy(Math.random() * w, Math.random() * h);
            body.space = space;

            // Create a debug-DisplayObject-graphic
            // We start off with a faded graphic until it enters a viewport.
            var graphic = Debug.createGraphic(body);
            graphic.alpha = 0.25;
            addChild(graphic);

            // Store in userData so viewport listeners can get access to it.
            body.userData.graphic = graphic;
        }
    }

    function enterViewportHandler(cb:InteractionCallback) {
        // We only assigned viewableType to Bodys, so this
        // is always safe.
        var viewableBody = cb.int2.castBody;

        var graphic:DisplayObject = viewableBody.userData.graphic;
        graphic.alpha = 1.0;
    }

    function exitViewportHandler(cb:InteractionCallback) {
        // We only assigned viewableType to Bodys, so this
        // is always safe.
        var viewableBody = cb.int2.castBody;

        var graphic:DisplayObject = viewableBody.userData.graphic;
        graphic.alpha = 0.25;
    }

    override function postUpdate(deltaTime:Float) {
        // draw hand constraint if active.
        if (hand.active) debug.draw(hand);

        // draw viewport bodies which have no graphic.
        debug.draw(viewports);

        // Update graphics for all other objects.
        for (b in viewableObjects) {
            var graphic:DisplayObject = b.userData.graphic;
            graphic.x = b.position.x;
            graphic.y = b.position.y;
            graphic.rotation = (b.rotation * 180/Math.PI) % 360;
        }
    }

    static function main() {
        flash.Lib.current.addChild(new Viewports());
    }
}
