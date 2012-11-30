package {

    /**
     *
     * Sample: Pyramid Stress-Test
     * Author: Luca Deltodesco
     *
     * This sample serves as a stress-test of Nape collision detection
     * and contact physics.
     *
     * We have a very large pyramid (820 blocks), and use a very large
     * amount of iterations in the physics that permit it to be very stable
     * at the cost of performance.
     *
     * Even so, many people (Especcially with newer desktops) will find this
     * sample has a high FPS! In a real world scenario, we will likely use
     * far fewer iterations and not have such large stacks of blocks!
     *
     */

    import nape.geom.Vec2;
    import nape.phys.Body;
    import nape.phys.BodyType;
    import nape.shape.Circle;
    import nape.shape.Polygon;
    import nape.space.Broadphase;

    // Template class is used so that this sample may
    // be as concise as possible in showing Nape features without
    // any of the boilerplate that makes up the sample interfaces.
    import Template;

    public class PyramidStressTest extends Template {
        public function PyramidStressTest():void {
            super({
                gravity: Vec2.get(0, 600),
                // SWEEP_AND_PRUNE is a bit more effecient in this very simple
                // stress test. Real life scenarios are generally far more
                // suited to the default DYN_AABB_TREE broadphase.
                broadphase: Broadphase.SWEEP_AND_PRUNE,

                // To keep pyramid somewhat stable, we need to use more velocity iterations
                // Default is 10, and we use 35 here! This is A LOT.
                //
                // Position iterations are not as expensive, nor important
                // for stability, but this is still an extreme example, so we use 15.
                velIterations : 35,
                posIterations : 15,

                // Stress test is likely going to be far below 60fps
                // for many people, trying to use fixed time steps
                // will just bog us down even more! so allow
                // variable steps to trade accuracy for performance.
                variableStep : true
            });
        }

        override protected function init():void {
            var w:int = stage.stageWidth;
            var h:int = stage.stageHeight;

            createBorder();

            // Disable angle indicators on shapes
            debug.drawShapeAngleIndicators = false;

            var boxWidth:Number = 10;
            var boxHeight:Number = 14;
            var pyramidHeight:int = 40; //820 blocks

            for (var y:int = 1; y <= pyramidHeight; y++) {
            for (var x:int = 0; x < y; x++) {
                var block:Body = new Body();
                // We initialise the blocks to be slightly overlapping so that
                // all contact points will be created in very first step before the blocks
                // begin to fall.
                block.position.x = (w/2) - boxWidth*((y-1)/2 - x)*0.99;
                block.position.y = h - boxHeight*(pyramidHeight - y + 0.5)*0.99;
                block.shapes.add(new Polygon(Polygon.box(boxWidth, boxHeight)));
                block.space = space;
            }}
        }
    }
}
