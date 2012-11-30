package;

/**
 *
 * Sample: Spatial Queries
 * Author: Luca Deltodesco
 *
 * This sample demonstrates the majority of the spatial query
 * methods available through the Space object.
 *
 * Ray casts (single result mode): Useful for things like bullets
 * and line-of-sight.
 *
 * Convex casts (single result mode): Useful for things like very-fast
 * moving grenades and rockets, as well as adaptive path finding perhaps.
 *
 * Sampling methods like bodiesInAABB to find the set of bodies intersecting
 * an AABB, as well as using the same method to find those bodies entirely
 * contained.
 *
 * etc.
 */

import nape.dynamics.InteractionFilter;
import nape.geom.AABB;
import nape.geom.Ray;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyList;
import nape.phys.BodyType;
import nape.shape.Circle;
import nape.shape.Polygon;
import nape.shape.Shape;

// Template class is used so that this sample may
// be as concise as possible in showing Nape features without
// any of the boilerplate that makes up the sample interfaces.
import Template;

class SpatialQueries extends Template {
    function new() {
        super({
            gravity: Vec2.get(0, 0)
        });
    }

    // cannonball we use in convex queries.
    var cannonBall:Body;
    var cannonBallShape:Shape;
    var cannon:Body;
    var cannonGunFilter:InteractionFilter;

    // gun reference to seed ray shots
    var gun:Body;
    var ray:Ray;

    // Body-list for re-use in sample methods.
    var output:BodyList;

    // AABB used for sampling
    var sampleAABB:AABB;

    // Shape and its Body used for sample
    var sampleBody:Body;
    var sampleShape:Shape;

    override function init() {
        var w = stage.stageWidth;
        var h = stage.stageHeight;

        createBorder();

        // High drag to stop things moving quickly.
        space.worldLinearDrag = 4;
        space.worldAngularDrag = 4;

        // Cannon for 'firing' cannonballs
        cannon = new Body();
        cannon.position.setxy(w/3,h - 60);
        cannon.shapes.add(new Polygon(Polygon.box(10,40)));
        cannon.shapes.add(new Polygon(Polygon.rect(-10,-20,20,10)));
        cannon.space = space;

        // Gun for 'firing' bullets.
        gun = new Body();
        gun.position.setxy(2*w/3,h - 60);
        gun.shapes.add(new Polygon(Polygon.box(10,40)));
        gun.shapes.add(new Polygon(Polygon.rect(-10,-20,20,10)));
        gun.space = space;

        // Filter for cannon/gun shapes so we can exclude it from queries
        // we set the mask so that we use this both for the cannon/gun
        // themselves and for the spatial queries too.
        cannonGunFilter = new InteractionFilter(
            /*collisionGroup*/2,
            /*collisionMask*/~2
        );

        cannon.setShapeFilters(cannonGunFilter);
        gun.setShapeFilters(cannonGunFilter);

        cannonBall = new Body();
        // Square cannonball, bit more interesting! :P
        cannonBallShape = new Polygon(Polygon.box(20,10));
        cannonBallShape.body = cannonBall;

        ray = new Ray(Vec2.weak(), Vec2.weak());

        output = new BodyList();
        sampleAABB = new AABB();
        sampleBody = new Body();
        sampleShape = new Polygon(Polygon.regular(110,110,5));
        sampleShape.body = sampleBody;

        // Generate some random objects!
        for (i in 0...50) {
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
            body.position.setxy(Math.random() * w, Math.random() * h * 0.5);
            body.space = space;
        }
    }

    override function postUpdate(_:Float) {

        // Shoot cannon through Space to look for collision.
        // we use the convexCast for this which uses a Shape
        // to define the colliding entity, and a Body's position and velocities
        // to define the casting path.
        cannonBall.position.set(cannon.localPointToWorld(Vec2.weak(0,-20),true));
        cannonBall.velocity.set(cannon.localVectorToWorld(Vec2.weak(0,-1000),true));
        cannonBall.velocity.rotate(-0.5);
        cannonBall.angularVel = 20;

        for (i in 0...20) {
            cannonBall.velocity.rotate(0.05);

            // We set the cannon ball to have a large velocity of 1000px/s
            // so we just use 1 second of integration time for path.
            var result = space.convexCast(
                cannonBallShape,
                /*deltaTime*/ 1,
                /*liveSweep*/ false,
                cannonGunFilter
            );

            if (result != null) {
                // Integrate cannonball to collision time for rendering
                var oldPosition = cannonBall.position.copy();
                cannonBall.integrate(result.toi);
                debug.draw(cannonBall);
                debug.drawLine(oldPosition, cannonBall.position, 0xaa0000);
                oldPosition.dispose();

                // Move back for next cast
                cannonBall.integrate(-result.toi);

                // Draw circle at collision point, and collision normal.
                debug.drawFilledCircle(result.position, 3, 0xaa00);
                debug.drawLine(
                    result.position,
                    result.position.addMul(result.normal, 15, true),
                    0xaa00
                );
                // release result object to pool.
                result.dispose();
            }
        }

        // Shoot gun through Space to look for collision.
        // we use the rayCast for this treating the bullets as infinitesimal points.
        ray.origin.set(gun.localPointToWorld(Vec2.weak(0,-20),true));
        ray.direction.set(gun.localVectorToWorld(Vec2.weak(0,-1),true));
        ray.maxDistance = 1000; // cast as far as 1000px

        ray.direction.rotate(-0.5);
        for (i in 0...20) {
            ray.direction.rotate(0.05);

            var result = space.rayCast(
                ray,
                /*inner*/ false,
                cannonGunFilter
            );

            if (result != null) {
                var collision = ray.at(result.distance);
                debug.drawLine(ray.origin, collision, 0xaa00);
                // Draw circle at collision point, and collision normal.
                debug.drawFilledCircle(collision, 3, 0xaa0000);
                debug.drawLine(
                    collision,
                    collision.addMul(result.normal, 15, true),
                    0xaa0000
                );
                collision.dispose();

                // release result object to pool.
                result.dispose();
            }
        }

        // Sample all bodies under mouse in a circle
        debug.drawCircle(Vec2.weak(mouseX, mouseY), 100, 0xffff);
        // With intersection only check.
        output = space.bodiesInCircle(
            Vec2.weak(mouseX, mouseY),
            /*radius*/ 100,
            /*strict-containment*/ false,
            /*filter*/ null,
            output
        );
        for (b in output) {
            debug.drawCircle(b.position, 5, 0xffff);
        }
        output.clear();

        // With strict containment check.
        output = space.bodiesInCircle(
            Vec2.weak(mouseX, mouseY),
            /*radius*/ 100,
            /*strict-containment*/ true,
            /*filter*/ null,
            output
        );
        for (b in output) {
            debug.drawFilledCircle(b.position, 5, 0xffff);
        }
        output.clear();

        // Sample all bodies under mouse in an AABB
        sampleAABB.width = 160;
        sampleAABB.height = 160;
        sampleAABB.x = mouseX - 260;
        sampleAABB.y = mouseY - 80;
        debug.drawAABB(sampleAABB, 0xff00ff);
        // With intersection only check.
        output = space.bodiesInAABB(
            sampleAABB,
            /*strict-containment*/ false,
            /*strict-check*/ true,
            /*filter*/ null,
            output
        );
        for (b in output) {
            debug.drawCircle(b.position, 4, 0xff00ff);
        }
        output.clear();

        // With strict containment check.
        output = space.bodiesInAABB(
            sampleAABB,
            /*strict-containment*/ true,
            /*strict-check*/ true,
            /*filter*/ null,
            output
        );
        for (b in output) {
            debug.drawFilledCircle(b.position, 4, 0xff00ff);
        }
        output.clear();

        // Sample all bodies under mouse in an Pentagon.
        sampleBody.position.x = mouseX + 190;
        sampleBody.position.y = mouseY;
        debug.drawPolygon(sampleShape.castPolygon.worldVerts, 0xffff00);
        // With intersection only check.
        output = space.bodiesInShape(
            sampleShape,
            /*strict-containment*/ false,
            /*filter*/ null,
            output
        );
        for (b in output) {
            debug.drawCircle(b.position, 4, 0xffff00);
        }
        output.clear();

        // With strict containment check.
        output = space.bodiesInShape(
            sampleShape,
            /*strict-containment*/ true,
            /*filter*/ null,
            output
        );
        for (b in output) {
            debug.drawFilledCircle(b.position, 4, 0xffff00);
        }
        output.clear();
    }

    static function main() {
        flash.Lib.current.addChild(new SpatialQueries());
    }
}
