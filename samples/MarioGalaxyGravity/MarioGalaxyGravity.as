package {

    /**
     *
     * Sample: Mario Galaxy Gravity
     * Author: Luca Deltodesco
     *
     * Demonstrating applying impulses to Bodies
     * and use of the distance methods available through the
     * Geom object.
     *
     * Also demonstrates the use of MarchingSquares, convex
     * decompositions and polygon simplification.
     */

    import nape.geom.AABB;
    import nape.geom.Geom;
    import nape.geom.GeomPoly;
    import nape.geom.GeomPolyList;
    import nape.geom.MarchingSquares;
    import nape.geom.Vec2;
    import nape.phys.Body;
    import nape.phys.BodyType;
    import nape.phys.Material;
    import nape.shape.Circle;
    import nape.shape.Polygon;
    import nape.space.Broadphase;

    // Template class is used so that this sample may
    // be as concise as possible in showing Nape features without
    // any of the boilerplate that makes up the sample interfaces.
    import Template;

    public class MarioGalaxyGravity extends Template {
        public function MarioGalaxyGravity():void {
            super({
                generator: generateObject
            });
        }

        private var planetaryBodies:Array;
        private var samplePoint:Body;

        override protected function init():void {
            var w:uint = stage.stageWidth;
            var h:uint = stage.stageHeight;

            var border:Body = createBorder();

            // We want to find for each body, the closest point on the planet to the bodys
            // centre of mass. Geom provides us with a method distanceBody which finds the
            // distance between two bodies and closest points, so if we create a Body having
            // only a very small circle in it, and position it at the body centre of mass
            // we can get the closest point to the centre of mass.
            //
            // In future, Nape may implement an automatic way of doing this for an arbitrary
            // point; perhaps simply using this trick internally.
            samplePoint = new Body();
            samplePoint.shapes.add(new Circle(0.001));

            // make the border a planet too!
            planetaryBodies = [border];

            // Create the central planet.
            var planet:Body = new Body(BodyType.STATIC);
            var polys:GeomPolyList = MarchingSquares.run(
                new StarIso(),
                new AABB(0, 0, w, h),
                new Vec2(5, 5)
            );
            for (var i:int = 0; i < polys.length; i++) {
                var poly:GeomPoly = polys.at(i);
                var convexPolys:GeomPolyList = poly.simplify(1).convexDecomposition(true);
                for (var j:int = 0; j < convexPolys.length; j++) {
                    var p:GeomPoly = convexPolys.at(j);
                    planet.shapes.add(new Polygon(p));
                }
            }
            planet.space = space;
            planetaryBodies.push(planet);

            // Create additional planets
            // Platform in top right
            planet = new Body(BodyType.STATIC);
            planet.position.setxy(680, 120);
            planet.rotation = Math.PI/4;
            planet.shapes.add(new Polygon(Polygon.box(100, 1)));
            planet.space = space;
            planetaryBodies.push(planet);

            // Box in bottom right
            planet = new Body(BodyType.STATIC);
            planet.position.setxy(680, 480);
            planet.rotation = Math.PI/4;
            planet.shapes.add(new Polygon(Polygon.box(80, 80)));
            planet.space = space;
            planetaryBodies.push(planet);

            // Triangle in bottom left
            planet = new Body(BodyType.STATIC);
            planet.position.setxy(120, 480);
            planet.rotation = -Math.PI/4;
            planet.shapes.add(new Polygon(Polygon.regular(50, 50, 3)));
            planet.space = space;
            planetaryBodies.push(planet);

            // Pentagon in bottom left
            planet = new Body(BodyType.STATIC);
            planet.position.setxy(120, 120);
            planet.rotation = Math.PI/4;
            planet.shapes.add(new Polygon(Polygon.regular(50, 50, 5)));
            planet.space = space;
            planetaryBodies.push(planet);

            // Generate some random objects!
            for (i = 0; i < 180; i++) {
                var body:Body = new Body();

                // Add random one of either a Circle, Box or Pentagon.
                if (Math.random() < 0.33) {
                    body.shapes.add(new Circle(10));
                }
                else if (Math.random() < 0.5) {
                    body.shapes.add(new Polygon(Polygon.box(20, 20)));
                }
                else {
                    body.shapes.add(new Polygon(Polygon.regular(10, 10, 5)));
                }

                var angle:Number = Math.PI * 2 / 60 * i;
                var radius:Number = 200 + 25 * int(i / 60);
                body.position.x = 400 + radius * Math.cos(angle);
                body.position.y = 300 + radius * Math.sin(angle);
                body.space = space;
            }
        }

        override protected function preStep(deltaTime:Number):void {
            for (var i:int = 0; i < planetaryBodies.length; i++) {
                var planet:Body = planetaryBodies[i];
                planetaryGravity(planet, deltaTime);
            }
        }

        private function planetaryGravity(planet:Body, deltaTime:Number):void {
            // Apply a gravitational impulse to all bodies
            // pulling them to the closest point of a planetary body.
            //
            // Because this is a constantly applied impulse, whose value depends
            // only on the positions of the objects, we can set the 'sleepable'
            // of applyImpulse to be true and permit these bodies to still go to
            // sleep.
            //
            // Applying a 'sleepable' impulse to a sleeping Body has no effect
            // so we may as well simply iterate over the non-sleeping bodies.
            var closestA:Vec2 = Vec2.get();
            var closestB:Vec2 = Vec2.get();

            for (var i:int = 0; i < space.liveBodies.length; i++) {
                var body:Body = space.liveBodies.at(i);
                // Find closest points between bodies.
                samplePoint.position.set(body.position);
                var distance:Number = Geom.distanceBody(planet, samplePoint, closestA, closestB);

                // Cut gravity off, well before distance threshold.
                if (distance > 100) {
                    continue;
                }

                // Gravitational force.
                var force:Vec2 = closestA.sub(body.position, true);

                // We don't use a true description of gravity, as it doesn't 'play' as nice.
                force.length = body.mass * 1e6 / (distance * distance);

                // Impulse to be applied = force * deltaTime
                body.applyImpulse(
                    /*impulse*/ force.muleq(deltaTime),
                    /*position*/ null, // implies body.position
                    /*sleepable*/ true
                );
            }

            closestA.dispose();
            closestB.dispose();
        }

        private function generateObject(pos:Vec2):void {
            var body:Body = new Body();
            body.position = pos;

            // Add random one of either a Circle, Box or Pentagon.
            if (Math.random() < 0.33) {
                body.shapes.add(new Circle(10));
            }
            else if (Math.random() < 0.5) {
                body.shapes.add(new Polygon(Polygon.box(20, 20)));
            }
            else {
                body.shapes.add(new Polygon(Polygon.regular(10, 10, 5)));
            }

            body.space = space;
        }
    }
}

import nape.geom.IsoFunction;

class StarIso implements IsoFunction {
    public function StarIso():void {}
    public function iso(x:Number, y:Number):Number {
        x -= 400;
        y -= 300;
        return 7000 * Math.sin(5 * Math.atan2(y, x)) + x * x + y * y - 150*150;
    }
}
