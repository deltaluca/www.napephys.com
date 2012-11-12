package;

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
import nape.phys.Compound;
import nape.phys.Material;
import nape.shape.Circle;
import nape.shape.Polygon;

// Template class is used so that this sample may
// be as concise as possible in showing Nape features without
// any of the boilerplate that makes up the sample interfaces.
import Template;

class Test extends Template {
    static function main() {
        flash.Lib.current.addChild(new Test());
    }

    var SPIKES       :CbType;
    var TRACTIONBEAM :CbType;
    var TELEPORTER   :CbType;
    var ONEWAY       :CbType;

    function new() {
        super({
            gravity : Vec2.get(0, 600),
            variableStep : false,
            generator : genBlock
        });

        SPIKES        = new CbType();
        TRACTIONBEAM  = new CbType();
        TELEPORTER    = new CbType();
        ONEWAY        = new CbType();
    }

    override function init() {
        {
            // Create stage borders.
            var border = new Body(BodyType.STATIC);

            // Left/Right walls.
            border.shapes.add(new Polygon(Polygon.rect(0,   -10, -1, 610, true)));
            border.shapes.add(new Polygon(Polygon.rect(800, -10,  1, 610, true)));

            // Top-bar (one way platform)
            var topBar = new Polygon(Polygon.rect(0, 0, 800, -1, true));
            topBar.userData.direction = Vec2.get(0, 1);
            topBar.cbTypes.add(ONEWAY);
            topBar.body = border;

            // Disable debug drawing for the border.
            border.debugDraw = false;
            border.space = space;
        }
        {
            // Bottom-segments of stage.
            var bottom = new Body(BodyType.STATIC);
            bottom.shapes.add(new Polygon([
                Vec2.weak(0, 650),
                Vec2.weak(0, 580),
                Vec2.weak(530, 580),
                Vec2.weak(550, 600),
                Vec2.weak(550, 650)
            ]));
            bottom.shapes.add(new Polygon([
                Vec2.weak(700, 650),
                Vec2.weak(700, 600),
                Vec2.weak(720, 580),
                Vec2.weak(800, 580),
                Vec2.weak(800, 650)
            ]));

            // Teleporter sensor
            var teleporter = new Polygon(Polygon.rect(550, 600, 150, 1));
            teleporter.sensorEnabled = true;
            teleporter.cbTypes.add(TELEPORTER);
            teleporter.body = bottom;
            bottom.space = space;

            // Generate some blocks above teleporter
            genBlock(Vec2.weak(625, 200));
            genBlock(Vec2.weak(625, 250));
            genBlock(Vec2.weak(625, 300));
            genBlock(Vec2.weak(625, 350));
        }
        {
            // Traction Beam
            var beamBody = new Body(BodyType.STATIC);
            var tractionBeam = new Polygon(Polygon.rect(0, 100, 800, 50));
            // We use a fluid so that we can make use of buoyancy and drag to counteract
            // gravity and provide dampening of body in traction beam.
            tractionBeam.fluidEnabled = true;
            tractionBeam.fluidProperties.density = 1;
            tractionBeam.fluidProperties.viscosity = 8;

            tractionBeam.userData.direction = Vec2.get(-1, 0);
            tractionBeam.userData.position = Vec2.get(0, 125);

            tractionBeam.cbTypes.add(TRACTIONBEAM);
            tractionBeam.body = beamBody;
            beamBody.space = space;
        }
        {
            // Middle platforms
            var middle = new Body(BodyType.STATIC);
            middle.shapes.add(new Polygon([
                Vec2.weak(260, 290),
                Vec2.weak(310, 290),
                Vec2.weak(310, 400)
            ]));
            middle.shapes.add(new Polygon([
                Vec2.weak(470, 290),
                Vec2.weak(520, 290),
                Vec2.weak(470, 400)
            ]));

            // Mid-bars (one way platform)
            var midBar = new Polygon(Polygon.rect(310, 290, 160, 1, true));
            midBar.userData.direction = Vec2.get(0, -1);
            midBar.cbTypes.add(ONEWAY);
            midBar.body = middle;

            midBar = new Polygon(Polygon.rect(310, 400, 160, -1, true));
            midBar.userData.direction = Vec2.get(0, -1);
            midBar.cbTypes.add(ONEWAY);
            midBar.body = middle;

            middle.space = space;

            // Generate some blocks inside of mid block.
            genBlock(Vec2.weak(340, 375));
            genBlock(Vec2.weak(390, 375));
            genBlock(Vec2.weak(440, 375));
        }
        {
            // Spike sets.
            function genSpikes(count) {
                var spikeWidth = 20;
                var spikeHeight = 20;
                var deltaX = -(count / 2) * spikeWidth;

                var body = new Body(BodyType.STATIC);
                for (i in 0...count) {
                    body.shapes.add(new Polygon([
                        Vec2.weak(deltaX + (i * spikeWidth), 0),
                        Vec2.weak(deltaX + ((i + 0.5) * spikeWidth), -spikeHeight),
                        Vec2.weak(deltaX + ((i + 1) * spikeWidth), 0)
                    ]));
                }

                body.cbTypes.add(SPIKES);
                return body;
            }

            var spikes = genSpikes(10);
            spikes.position.setxy(80, 580);
            spikes.space = space;

            spikes = genSpikes(6);
            spikes.rotation = (Math.PI * 0.5);
            spikes.position.setxy(0, 125);
            spikes.space = space;

            // Generate some blocks above bottom spikes.
            genBlock(Vec2.weak(80, 200));
            genBlock(Vec2.weak(80, 250));
            genBlock(Vec2.weak(80, 300));
            genBlock(Vec2.weak(80, 350));
        }
        {
            // Set up listeners

            // One-way platforms.
            // Marked as a pure handler so that objects may go to sleep
            space.listeners.add(new PreListener(
                InteractionType.COLLISION,
                ONEWAY,
                CbType.ANY_BODY,
                oneWayHandler,
                0,
                true
            ));

            // Teleporter.
            space.listeners.add(new InteractionListener(
                CbEvent.END,
                InteractionType.SENSOR,
                TELEPORTER,
                CbType.ANY_BODY,
                teleportHandler
            ));

            // Light beam.
            space.listeners.add(new InteractionListener(
                CbEvent.ONGOING,
                InteractionType.FLUID,
                TRACTIONBEAM,
                CbType.ANY_BODY,
                lightBeamHandler
            ));

            // Spikes
            space.listeners.add(new InteractionListener(
                CbEvent.ONGOING,
                InteractionType.COLLISION,
                SPIKES,
                CbType.ANY_BODY,
                spikeBreakHandler
            ));
        }
    }

    function genBlock(position:Vec2) {
        var block = new Body();
        block.shapes.add(new Polygon(Polygon.box(50, 50)));
        block.position.set(position);
        block.space = space;

        block.userData.size = 50;
        block.userData.breakCount = 3;
    }

    function oneWayHandler(cb:PreCallback) {
        var platform = cb.int1.castShape;
        var direction:Vec2 = platform.userData.direction;
        var arbiter = cb.arbiter.collisionArbiter;
        // If contact normal is pointing in wrong direction then
        // we ignore the interaction completely.
        // (Using cb.swapped to handle case that the platform shape
        //  is not the same as arbiter.shapeA and that the normal
        //  needs to be reversed)
        if ((arbiter.normal.dot(direction) < 0) != cb.swapped) {
            return PreFlag.IGNORE;
        }
        else {
            return null;
        }
    }

    function teleportHandler(cb:InteractionCallback) {
        var otherBody = cb.int2.castBody;

        // Check object exited teleporter below!
        if (otherBody.position.y < 600) {
            return;
        }

        // Disable hand constraint if teleporting body being dragged.
        if (hand.body2 == otherBody) {
            hand.active = false;
        }

        // Teleport body to top of stage.
        otherBody.position.y = -otherBody.bounds.height;
    }

    function lightBeamHandler(cb:InteractionCallback) {
        var otherBody = cb.int2.castBody;
        var beamShape = cb.int1.castShape;

        var direction:Vec2 = beamShape.userData.direction;
        var position:Vec2 = beamShape.userData.position;

        var scale = otherBody.mass;
        // Impulse to push body along beam.
        var beamImpulse = direction.mul(scale * 45, true);

        // Impulse to keep body in centre of beam.
        var guideImpulse = Vec2.weak(direction.y, -direction.x);
        var guideStrength = direction.cross(otherBody.position.sub(position, true));
        guideImpulse.muleq(guideStrength * scale * 2);

        otherBody.applyImpulse(beamImpulse);
        otherBody.applyImpulse(guideImpulse);
    }

    function spikeBreakHandler(cb:InteractionCallback) {
        var otherBody = cb.int2.castBody;

        // Body may have hit more than one set of spikes (In general case)
        if (otherBody.space == null) {
            return;
        }

        // Assert collision impulse is high enough to warrant breaking apart.
        var sumImpulses = 0.0;
        for (arb in cb.arbiters) {
            var vec = arb.collisionArbiter.normalImpulse(otherBody);
            sumImpulses += vec.length;
            vec.dispose();
        }
        if (sumImpulses < (800 * otherBody.mass)) {
            return;
        }

        // Remove body from space.
        otherBody.space = null;
        if (hand.body2 == otherBody) {
            hand.active = false;
        }

        // Split body into 2x2 sub-grid of boxes.
        var size:Float = otherBody.userData.size;
        var breakCount:Int = otherBody.userData.breakCount;

        size /= 2;
        breakCount -= 1;

        // Break limit reached, don't divide.
        if (breakCount == 0) {
            return;
        }

        for (x in 0...2) {
        for (y in 0...2) {
            // Local position of new body.
            var localPoint = Vec2.get(
                (size / 2) * ((2 * x) - 1),
                (size / 2) * ((2 * y) - 1)
            );

            var body = new Body();
            body.shapes.add(new Polygon(Polygon.box(size, size, true)));

            // Set body properties to inherit from parent.
            body.position.set(otherBody.localPointToWorld(localPoint, true));
            body.rotation = otherBody.rotation;
            body.velocity.set(otherBody.velocity);
            body.angularVel = otherBody.angularVel;

            // Add additional velocity to burst shapes apart.
            var burst = 20;
            body.velocity.addeq(otherBody.localVectorToWorld(localPoint, true).muleq(burst));

            body.userData.size = size;
            body.userData.breakCount = breakCount;

            body.space = space;

            localPoint.dispose();
        }}

    }

    override function update(deltaTime:Float) {
        // Template takes care of calling space.step() and
        // debug drawing calls for space.
    }
}
