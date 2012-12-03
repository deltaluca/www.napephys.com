package;

/**
 *
 * Sample: Soft Bodies
 * Author: Luca Deltodesco
 *
 * Nape does not support Soft Bodies natively, however there
 * are many ways of creating soft bodies regardless. This sample
 * demonstrates a succesful (if expensive) approach that has many
 * nice properties, stable stacking of bodies with inter-collisions
 * and even self-collisions of a soft body.
 *
 * We achieve this by using polygonal segments discretising the
 * perimeter of the body which are connected on the outside via
 * stiff PivotJoints, and on the inside by elastic PivotJoints.
 *
 * Additionally to help with making bodies more rigid, a gas
 * pressure force is computed per-body and applied to each segment
 * outwards.
 *
 * Even though this is an expensive method with LOTS of Bodies
 * and Constraints, it is still highly performant!
 *
 */

import nape.constraint.MotorJoint;
import nape.constraint.PivotJoint;
import nape.geom.GeomPoly;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.phys.Compound;
import nape.shape.Circle;
import nape.shape.Edge;
import nape.shape.Polygon;

import flash.display.Sprite;

// Template class is used so that this sample may
// be as concise as possible in showing Nape features without
// any of the boilerplate that makes up the sample interfaces.
import Template;

typedef SoftBody = Compound;

class SoftBodies extends Template {
    function new() {
        super({
            gravity: Vec2.get(0, 600),

            // Use higher than default iteration counts in both cases to increase
            // stability of the soft bodies.
            velIterations: 15,
            posIterations: 15
        });
    }

    var softBodies:Array<SoftBody>;

    override function init() {
        var w = stage.stageWidth;
        var h = stage.stageHeight;

        createBorder();

        // Set debug draw to disable angle indicators and constraints
        debug.drawShapeAngleIndicators = false;
        debug.drawConstraints = false;

        var staticBody = new Body(BodyType.STATIC);

        // Add a water level at bottom
        var water = new Polygon(Polygon.rect(0, h, w, -150));
        water.fluidEnabled = true;
        water.fluidProperties.density = 3;
        water.fluidProperties.viscosity = 5;
        water.body = staticBody;

        // Add middle platform
        var platform = new Polygon(Polygon.rect(200, h - 3.5 * 60, w - 400, 1));
        platform.body = staticBody;

        staticBody.space = space;
        softBodies = [];

        // Add some box shaped soft-bodies.
        var poly = new GeomPoly(Polygon.box(60, 60));
        for (y in 4...7) {
        for (x in -2...3) {
            var body = polygonalBody(
                Vec2.get(w/2 + x * 60, h - (y + 0.5) * 60),
                /*thickness*/ 10, /*discretisation*/ 15,
                /*frequency*/ 30, /*damping*/ 10,
                poly
            );
            softBodies.push(body);
            body.space = space;
        }}

        // Add some pentangonol shaped soft-bodies.
        var poly = new GeomPoly(Polygon.regular(30, 30, 5));
        for (y in 7...10) {
        for (x in -2...3) {
            var body = polygonalBody(
                Vec2.get(w/2 + x * 60, h - (y + 0.5) * 60),
                /*thickness*/ 10, /*discretisation*/ 15,
                /*frequency*/ 30, /*damping*/ 10,
                poly
            );
            softBodies.push(body);
            body.space = space;
        }}
    }

    override function preStep(deltaTime:Float) {
        // Iterate over the soft bodies, computing a pressure force
        // and applying this force to each edge of the soft body.
        for (s in softBodies) {
            var pressure = deltaTime * (s.userData.area - polygonalArea(s));

            var refEdges:Array<Edge> = s.userData.refEdges;
            for (e in refEdges) {
                var body = e.polygon.body;

                // We pass 'true' for third argument since this pressure impulse is
                // dependent only on the positions of the segments in the soft body.
                // So that if the soft body is at rest, application of the impulse
                // does not need to wake up the body. This permits the soft body
                // to sleep.
                body.applyImpulse(e.worldNormal.mul(pressure, true), body.position, true);
            }
        }
    }

    function polygonalBody(
        position:Vec2,
        thickness:Float, discretisation:Float,
        frequency:Float, damping:Float,
        poly:GeomPoly
    ) {
        // We're going to collect all Bodies and Constraints into a SoftBody
        // for ease of use hereafter.
        var body = new SoftBody();

        // Lists of segments, and the outer and inner points for joint formations.
        var segments = [];
        var outerPoints = [];
        var innerPoints = [];

        // Set of Edge references to vertex of segments to be used in drawing bodies
        // and in determining area for gas forces.
        var refEdges = [];
        body.userData.refEdges = refEdges;

        // Deflate the input polygon for inner vertices
        var inner = poly.inflate(-thickness);

        // Create Bodies about the border of polygon.
        var start = poly.current();
        do {
            // Current and next vertex along polygon.
            var current = poly.current();
            poly.skipForward(1);
            var next = poly.current();

            // Current and next vertex along inner-polygon.
            var iCurrent = inner.current();
            inner.skipForward(1);
            var iNext = inner.current();

            var delta = next.sub(current);
            var iDelta = iNext.sub(iCurrent);

            var length = Math.max(delta.length, iDelta.length);
            var numSegments = Math.ceil(length / discretisation);
            var gap = (1 / numSegments);

            for (i in 0...numSegments) {
                // Create softBody segment.
                // We are careful to create weak Vec2 for the polygon
                // vertices so that all Vec2 are automatically released
                // to object pool.
                var segment = new Body();

                var outerPoint = current.addMul(delta, gap * i);
                var innerPoint = iCurrent.addMul(iDelta, gap * i);
                var polygon = new Polygon([
                    outerPoint,
                    current.addMul(delta, gap * (i + 1), true),
                    iCurrent.addMul(iDelta, gap * (i + 1), true),
                    innerPoint
                ]);
                polygon.body = segment;
                segment.compound = body;
                segment.align();

                segments.push(segment);
                outerPoints.push(outerPoint);
                innerPoints.push(innerPoint);

                refEdges.push(polygon.edges.at(0));
            }

            // Release vectors to object pool.
            delta.dispose();
            iDelta.dispose();
        }
        while (poly.current() != start);

        // Create sets of PivotJoints to link segments together.
        for (i in 0...segments.length) {
            var leftSegment = segments[(i - 1 + segments.length) % segments.length];
            var rightSegment = segments[i];

            // We create a stiff PivotJoint for outer edge
            var current = outerPoints[i];
            var pivot = new PivotJoint(
                leftSegment, rightSegment,
                leftSegment.worldPointToLocal(current, true),
                rightSegment.worldPointToLocal(current, true)
            );
            current.dispose();
            pivot.compound = body;

            // And an elastic one for inner edge
            current = innerPoints[i];
            pivot = new PivotJoint(
                leftSegment, rightSegment,
                leftSegment.worldPointToLocal(current, true),
                rightSegment.worldPointToLocal(current, true)
            );
            current.dispose();
            pivot.compound = body;
            pivot.stiff = false;
            pivot.frequency = frequency;
            pivot.damping = damping;

            // And set one of them to have 'ignore = true' so that
            // adjacent segments do not interact.
            pivot.ignore = true;
        }

        // Release vertices of inner polygon to object pool.
        inner.clear();

        // Move segments by required offset
        for (s in segments) {
            s.position.addeq(position);
        }

        body.userData.area = polygonalArea(body);

        return body;
    }

    static var areaPoly = new GeomPoly();
    static function polygonalArea(s:SoftBody) {
        // Computing the area of the soft body, we use the vertices of its edges
        // to populate a GeomPoly and use its area function.
        var refEdges:Array<Edge> = s.userData.refEdges;
        for (edge in refEdges) {
            areaPoly.push(edge.worldVertex1);
        }
        var ret = areaPoly.area();

        // We use the same GeomPoly object, and recycle the vertices
        // to avoid increasing memory.
        areaPoly.clear();

        return ret;
    }

    static function main() {
        flash.Lib.current.addChild(new SoftBodies());
    }
}
