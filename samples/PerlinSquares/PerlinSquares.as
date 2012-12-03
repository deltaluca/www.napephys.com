package {

    /**
     *
     * Sample: Perlin Squares
     * Author: Luca Deltodesco
     *
     * Using a quick implementation of 3D Perlin Noise,
     * this sample serves as both a demonstration, and a
     * stress test of Nape's MarchingSquares API and GeomPoly
     * decompositions.
     *
     * Sadly, neither the BitmapDebug, or ShapeDebug are
     * sufficiently fast at drawing filled polygons, that a
     * profiler will easily show 20% of time being spent on
     * rendering! sigh.
     *
     */

    import nape.geom.AABB;
    import nape.geom.GeomPoly;
    import nape.geom.GeomPolyList;
    import nape.geom.IsoFunction;
    import nape.geom.Mat23;
    import nape.geom.MarchingSquares;
    import nape.geom.Vec2;

    // Template class is used so that this sample may
    // be as concise as possible in showing Nape features without
    // any of the boilerplate that makes up the sample interfaces.
    import Template;

    public class PerlinSquares  extends Template implements IsoFunction {
        public function PerlinSquares():void {
            // We use ShapeDebug as rendering large amounts of filled polygons
            // is slower with BitmapDebug.
            //
            // We aren't running any simulation so we don't need any Space nor
            // do we care about fixed time steps.
            super({
                shapeDebug: true,
                noSpace: true,
                variableStep: true
            });
        }

        // Parameters for MarchingSquares
        private var bounds:AABB;
        private var cellSize:Vec2;
        private var gridSize:Vec2;
        private var quality:int = 2;

        // Perlin Noise parameters
        private var perlinZ:Number = 0.0;
        private var threshold:Number = 0.0;

        // Polygon lists for MarchingSquares and GeomPoly decompositions
        // to avoid constantly creating new ones.
        private var output:GeomPolyList;
        private var output2:GeomPolyList;

        override protected function init():void {
            // Scale up debug draw so we can use a smaller area to use
            // for marching squares. Drawing the polygons with either
            // ShapeDebug or BitmapDebug is pretty damn expensive, so this
            // means we end up with less to draw!
            debug.transform = Mat23.scale(1.5, 1.5);
            bounds = new AABB(0, 0, stage.stageWidth/1.5, stage.stageHeight/1.5);
            cellSize = Vec2.get(10, 10);
            gridSize = Vec2.get(100, 100);

            Perlin3D.initNoise();
            output = new GeomPolyList();
            output2 = new GeomPolyList();
        }


        override protected function preStep(deltaTime:Number):void {
            perlinZ += deltaTime;
            threshold = 0.35 * Math.cos(0.3 * perlinZ);

            // Use marching squares to produce set of weakly-simple polygons
            // representing thresholded PerlinNoise.
            //
            // Here, we're supplying a GeomPolyList in which to return the results
            // to avoid creating a new List every single time.
            var polygons:GeomPolyList = MarchingSquares.run(
                this, bounds, cellSize, 2,
                gridSize, true, output
            );

            for (var i:int = 0; i < polygons.length; i++) {
                var p:GeomPoly = polygons.at(i);
                // Decompose section of perlin noise into convex polygons.
                // Making use of the second polygon list to avoid creating
                // a new List every single time.
                var decomposed:GeomPolyList = p.convexDecomposition(true, output2);
                for (var j:int = 0; j < decomposed.length; j++) {
                    var q:GeomPoly = decomposed.at(j);
                    debug.drawFilledPolygon(q, colour(q));
                    // Release to object pool
                    q.dispose();
                }
                // Recycle list nodes, clearing list for next time.
                decomposed.clear();

                debug.drawPolygon(p, 0x000000);
                // Release to object pool
                p.dispose();
            }

            // Recycle list nodes, clearing list for next time.
            polygons.clear();
        }

        public function iso(x:Number, y:Number):Number {
            return Perlin3D.noise(x/40, y/30, perlinZ) - threshold;
        }

    	private function colour(p:GeomPoly):int {
            //hue
            var h:Number = p.area()/3000*360; while(h>360) h -= 360;
            var f:Number = (h%60)/60;

            var r:Number, g:Number, b:Number;
            if     (h<=60 ) { r = 1;   g = f;   b = 0;   }
            else if(h<=120) { r = 1-f; g = 1;   b = 0;   }
            else if(h<=180) { r = 0;   g = 1;   b = f;   }
            else if(h<=240) { r = 0;   g = 1-f; b = 1;   }
            else if(h<=300) { r = f;   g = 0;   b = 1;   }
            else            { r = 1;   g = 0;   b = 1-f; }

            return (int(r*0xff)<<16)|(int(g*0xff)<<8)|int(b*0xff);
        }
    }
}

class Perlin3D {
    public static function noise(x:Number, y:Number, z:Number):Number {
        var X:int = int(x); x -= X; X &= 0xff;
        var Y:int = int(y); y -= Y; Y &= 0xff;
        var Z:int = int(z); z -= Z; Z &= 0xff;
        var u:Number = fade(x); var v:Number = fade(y); var w:Number = fade(z);
        var A:Number = p(X)  +Y; var AA:Number = p(A)+Z; var AB:Number = p(A+1)+Z;
        var B:Number = p(X+1)+Y; var BA:Number = p(B)+Z; var BB:Number = p(B+1)+Z;
        return lerp(w, lerp(v, lerp(u, grad(p(AA  ), x  , y  , z   ),
                                       grad(p(BA  ), x-1, y  , z   )),
                               lerp(u, grad(p(AB  ), x  , y-1, z   ),
                                       grad(p(BB  ), x-1, y-1, z   ))),
                       lerp(v, lerp(u, grad(p(AA+1), x  , y  , z-1 ),
                                       grad(p(BA+1), x-1, y  , z-1 )),
                               lerp(u, grad(p(AB+1), x  , y-1, z-1 ),
                                       grad(p(BB+1), x-1, y-1, z-1 ))));
    }

    private static function fade(t:Number):Number {
        return t*t*t*(t*(t*6-15)+10);
    }
    private static function lerp(t:Number, a:Number, b:Number):Number {
         return a + t*(b-a);
    }
    private static function grad(hash:int, x:Number, y:Number, z:Number):Number {
        var h:int = hash&15;
        var u:Number = h<8 ? x : y;
        var v:Number = h<4 ? y : h==12||h==14 ? x : z;
        return ((h&1) == 0 ? u : -u) + ((h&2) == 0 ? v : -v);
    }

    private static function p(i:int):int {
        return perm[i];
    }
    private static var perm:Vector.<int>;

    public static function initNoise():void {
        perm = new Vector.<int>(512,true);

        var p:Array = [151,160,137,91,90,15,
        131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
        190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
        88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
        77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
        102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
        135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
        5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
        223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
        129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
        251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
        49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
        138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180];

        for (var i:int = 0; i < 256; i++) {
            perm[i]=    p[i];
            perm[256+i]=p[i];
        }
    }
}
