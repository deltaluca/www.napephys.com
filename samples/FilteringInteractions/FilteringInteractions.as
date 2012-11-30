package {

    /**
     *
     * Sample: Filtering Interactions
     * Author: Luca Deltodesco
     *
     * In this sample, I show to make use of the InteractionFilter
     * object, together with the fluidEnabled and sensorEnabled Shape
     * flags to control what type of interaction occurs between various
     * types of object.
     *
     */

    import nape.geom.Vec2;
    import nape.phys.Body;
    import nape.phys.BodyType;
    import nape.shape.Shape;
    import nape.shape.Circle;
    import nape.shape.Polygon;

    // Template class is used so that this sample may
    // be as concise as possible in showing Nape features without
    // any of the boilerplate that makes up the sample interfaces.
    import Template;

    public class FilteringInteractions extends Template {
        public function FilteringInteractions():void {
            super({
                gravity: Vec2.get(0, 600)
            });
        }

        override protected function init():void {
            var w:uint = stage.stageWidth;
            var h:uint = stage.stageHeight;

            createBorder();

            // Set debug draw to draw all interaction types.
            debug.drawCollisionArbiters = true;
            debug.drawSensorArbiters = true;
            debug.drawFluidArbiters = true;

            // We create 3 classes of objects.
            //
            // A) Boxes which collide with other boxes and border only.
            // B) Circles which sense with other circles, but nothing else.
            //    Circles will collide with border of world and the pentagons.
            // C) Pentagons which interact with the overlayed fluid object with
            //    buoyancy, but collide with border of world and circles.
            // Neither circles or boxes will interact with the fluid.
            //
            // We achieve this behaviour by appropriate group/mask values
            // on the shapes.

            // Create the fluid object to cover lower half of the stage.
            //
            //   We make it static so it is not itself moved by buoyancy/drag
            //   of the other objets.
            //
            //   We set the shape's collisionMask to 0 so that it can not
            //   collide with anything, and its fluidMask to 2 so that it
            //   will only interact as fluid with pentagons whose fluidGroup
            //   we also set to 2.
            //
            var fluidBody:Body = new Body(BodyType.STATIC);
            var fluidShape:Shape = new Polygon(Polygon.rect(0, h/2, w, h/2));

            fluidShape.filter.collisionMask = 0;
            fluidShape.fluidEnabled = true;
            fluidShape.filter.fluidMask = 2;

            fluidShape.fluidProperties.density = 3;
            fluidShape.fluidProperties.viscosity = 6;

            fluidShape.body = fluidBody;
            fluidBody.space = space;

            // Create sets of Boxes.
            //
            //  We set box collision mask to (~2) (everything but 2)
            //  which is the collision group we will give to circles and pentagons
            //  in this way, boxes will not collide with circles or pentagons, but
            //  will collide with the border and other boxes whose collisionGroup
            //  is left at the default of 1.
            //
            for (var i:uint = 0; i < 20; i++) {
                var boxBody:Body = new Body();
                boxBody.position.setxy(Math.random() * w, Math.random() * h);
                var boxShape:Shape = new Polygon(Polygon.box(50, 50));

                boxShape.filter.collisionMask = ~2;

                boxShape.body = boxBody;
                boxBody.space = space;
            }

            // Create sets of Circles.
            //
            //  We give as explained above, the circle a collisionGroup of 2.
            //  We also give it a sensorGroup and sensorMask of 2 so that it
            //  will sense with other circles, and only other circles.
            //
            //  Sensor interaction takes higher precedence than collisions so that
            //  this indirectly disables collisions between circles.
            //
            //  We set the circleBody force to counteract gravity.
            //
            for (i = 0; i < 20; i++) {
                var circleBody:Body = new Body();
                circleBody.position.setxy(Math.random() * w, Math.random() * h);
                var circleShape:Shape = new Circle(25);

                circleShape.filter.collisionGroup = 2;
                circleShape.sensorEnabled = true;
                circleShape.filter.sensorGroup = 2;
                circleShape.filter.sensorMask = 2;

                circleShape.body = circleBody;
                circleBody.force.set(space.gravity.mul(-circleBody.gravMass, true));
                circleBody.space = space;
            }

            // Create sets of Pentagons.
            //
            // We give as explained above, the pentagon a collisionGroup and
            // fluidGroup of 2.
            //
            for (i = 0; i < 20; i++) {
                var pentagonBody:Body = new Body();
                pentagonBody.position.setxy(Math.random() * w, Math.random() * h);
                var pentagonShape:Shape = new Polygon(Polygon.regular(25, 25, 5));

                pentagonShape.filter.collisionGroup = 2;
                pentagonShape.filter.fluidGroup = 2;

                pentagonShape.body = pentagonBody;
                pentagonBody.space = space;
            }
        }
    }
}
