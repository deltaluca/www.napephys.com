package;

/**
 *
 * Sample: One-Way Platforms
 * Author: Luca Deltodesco
 *
 * Using the PreListener callbacks to selectively ignore
 * collisions based on contact normals enabling one-way
 * platforms.
 *
 * Additionally, demonstrate the use of Body surfaceVel to
 * provide conveyor belts and standard InteractionListeners
 * to teleport bodies instantly on overlap.
 *
 * As well as the use of Kinematic bodies.
 *
 */

import nape.callbacks.CbEvent;
import nape.callbacks.CbType;
import nape.callbacks.InteractionCallback;
import nape.callbacks.InteractionListener;
import nape.callbacks.InteractionType;
import nape.callbacks.PreCallback;
import nape.callbacks.PreFlag;
import nape.callbacks.PreListener;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.phys.Material;
import nape.shape.Circle;
import nape.shape.Polygon;

// Template class is used so that this sample may
// be as concise as possible in showing Nape features without
// any of the boilerplate that makes up the sample interfaces.
import Template;

class OneWayPlatforms extends Template {
    function new() {
        super({
            gravity: Vec2.get(0, 600)
        });
    }

    var oneWayType:CbType;
    var teleporterType:CbType;
    var kinematics:Array<Body>;

    override function init() {
        var w = stage.stageWidth;
        var h = stage.stageHeight;

        // Set up one-way platform logic.
        //
        // We pass 'true' for the pure argument of PreListener constructor
        // so that (though not technically possible in this sample case due
        // to conveyor belts) objects may go to sleep whilst resting on the
        // platform. This is valid as the handler logic depends purely on
        // the input Arbiter data.
        //
        oneWayType = new CbType();
        space.listeners.add(new PreListener(
            InteractionType.COLLISION,
            oneWayType,
            CbType.ANY_BODY,
            oneWayHandler,
            /*precedence*/ 0,
            /*pure*/ true
        ));

        conveyor(1*h/5, 200);
        conveyor(2*h/5, 100);
        conveyor(3*h/5, -100);
        conveyor(4*h/5, 200);

        // Set up teleporter logic.
        teleporterType = new CbType();
        space.listeners.add(new InteractionListener(
            CbEvent.BEGIN,
            InteractionType.SENSOR,
            CbType.ANY_BODY,
            teleporterType,
            teleporterHandler
        ));

        // Create border at top and one at bottom to catch teleported
        // objects before platforms lift them up.
        var border = new Body(BodyType.STATIC);
        border.shapes.add(new Polygon(Polygon.rect(-20, 0, w+40, -1)));
        border.shapes.add(new Polygon(Polygon.rect(-20, 680, w+40, -1)));

        // Create teleporters on left and right
        var leftWall = new Polygon(Polygon.rect(-20, 0, -1, 680));
        leftWall.sensorEnabled = true;
        leftWall.cbTypes.add(teleporterType);
        leftWall.body = border;

        var rightWall = new Polygon(Polygon.rect(w+20, 0, 1, 680));
        rightWall.sensorEnabled = true;
        rightWall.cbTypes.add(teleporterType);
        rightWall.body = border;

        border.space = space;

        // Create kinematic platforms to lift objects up.
        var iw = (w+40)/4;
        kinematics = [];
        kinematic(-20, iw, 60, 480);
        kinematic(-20 + iw, iw, 120, 360);
        kinematic(-20 + iw*2, iw, 240, 120);
        kinematic(-20 + iw*3, iw, 180, 240);

        // Create a load of bodies to play with.
        for (i in 0...100) {
            var body = new Body();

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
        }
    }

    override function postUpdate(deltaTime:Float) {
        // Teleport kinematic to bottom of screen once it reaches top belt.
        for (k in kinematics) {
            if (k.position.y < k.userData.targetHeight) {
                k.position.y = 680;
            }
        }
    }

    function kinematic(x:Float, width:Float, speed:Float, target:Float) {
        var platform = new Body(BodyType.KINEMATIC);
        platform.position.setxy(x, 680);
        platform.shapes.add(new Polygon(Polygon.rect(0, 0, width, 1)));
        platform.velocity.y = -speed;
        platform.space = space;
        platform.userData.targetHeight = target;
        kinematics.push(platform);
    }

    function conveyor(height:Float, speed:Float) {
        var belt = new Body(BodyType.STATIC);

        belt.shapes.add(new Polygon(Polygon.rect(-20, height, 840, 10)));
        belt.surfaceVel.x = speed;
        belt.cbTypes.add(oneWayType);
        belt.setShapeMaterials(Material.rubber());
        belt.space = space;
    }

    function teleporterHandler(cb:InteractionCallback) {
        // Always valid given that we used CbType.ANY_BODY for first option type.
        var object = cb.int1.castBody;

        // However, since we did use CbType.ANY_BODY, we have to ensure we aren't
        // teleporting one of the kinematic platforms... (Hint: Not always a good
        // idea to use the ANY_# CbTypes even if it may seem handy)
        if (object.type == BodyType.KINEMATIC) return;

        // Teleport object under the screen for kinematic platforms to lift into view.
        object.position.x = Math.random()*800;
        object.position.y = 660;

        // Reset body velocities
        object.velocity.setxy(0, 0);
        object.angularVel = 0;
    }

    function oneWayHandler(cb:PreCallback):PreFlag {
        // We assigned the listener to have the one-way platform as first
        // interactor.
        //
        // PreCallback 'swapped' property as API docs describe tells us that
        // if true; arbiter.normal points from int2 to int1, else from int1 to int2
        //
        // To allow objects to move upwards through one-way platforms we must
        // ignore collisions with arbiter (pointing from one-way platform) whose normal
        // points down (y > 0). Taking swapped into account we have:
        //
        // Equally we gave the interactino type as COLLISION so that accessing
        // arbiter.collisionArbiter is always valid (non-null).
        var colArb = cb.arbiter.collisionArbiter;

        if ((colArb.normal.y > 0) != cb.swapped) {
            return PreFlag.IGNORE;
        }
        else {
            return PreFlag.ACCEPT;
        }
    }

    static function main() {
        flash.Lib.current.addChild(new OneWayPlatforms());
    }
}
