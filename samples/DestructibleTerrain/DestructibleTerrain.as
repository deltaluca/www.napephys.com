package {

    /**
     *
     * Sample: Destructible Terrain
     * Author: Luca Deltodesco
     *
     * Yet another sample featuring MarchingSquares,
     * this time used to implement destructible terrain with
     * use of a Bitmap for controlling removal from terrain.
     *
     * Terrain is chunked so that only necessary regions are
     * recomputed enabling higher performance.
     *
     */

    import nape.geom.AABB;
    import nape.geom.Vec2;
    import nape.phys.Body;
    import nape.phys.BodyType;
    import nape.shape.Circle;
    import nape.shape.Polygon;

    // Template class is used so that this sample may
    // be as concise as possible in showing Nape features without
    // any of the boilerplate that makes up the sample interfaces.
    import Template;

    import flash.display.BitmapData;
    import flash.display.BitmapDataChannel;
    import flash.display.BlendMode;
    import flash.display.Sprite;
    import flash.geom.Matrix;

    public class DestructibleTerrain extends Template {
        public function DestructibleTerrain():void {
            super({
                gravity: Vec2.get(0, 600),
                staticClick: explosion,
                generator: createObject
            });
        }

        private var terrain:Terrain;
        private var bomb:Sprite;

        override protected function init():void {
            var w:uint = stage.stageWidth;
            var h:uint = stage.stageHeight;

            createBorder();

            // Initialise terrain bitmap.
            var bit:BitmapData = new BitmapData(w, h, true, 0);
            bit.perlinNoise(200, 200, 2, 0x3ed, false, true, BitmapDataChannel.ALPHA, false);

            // Create initial terrain state, invalidating the whole screen.
            terrain = new Terrain(bit, 30, 5);
            terrain.invalidate(new AABB(0, 0, w, h), space);

            // Create bomb sprite for destruction
            bomb = new Sprite();
            bomb.graphics.beginFill(0xffffff, 1);
            bomb.graphics.drawCircle(0, 0, 40);
        }

        private function explosion(pos:Vec2):void {
            // Erase bomb graphic out of terrain.
            terrain.bitmap.draw(bomb, new Matrix(1, 0, 0, 1, pos.x, pos.y), null, BlendMode.ERASE);

            // Invalidate region of terrain effected.
            var region:AABB = AABB.fromRect(bomb.getBounds(bomb));
            region.x += pos.x;
            region.y += pos.y;
            terrain.invalidate(region, space);
        }

        private function createObject(pos:Vec2):void {
            var body:Body = new Body(BodyType.DYNAMIC, pos);
            if (Math.random() < 0.333) {
                body.shapes.add(new Circle(10 + Math.random()*20));
            }
            else {
                body.shapes.add(new Polygon(Polygon.regular(
                        /*radiusX*/ 10 + Math.random()*20,
                        /*radiusY*/ 10 + Math.random()*20,
                        /*numVerts*/ int(Math.random()*3 + 3)
                )));
            }
            body.space = space;
        }
    }
}

import nape.geom.AABB;
import nape.geom.GeomPoly;
import nape.geom.GeomPolyList;
import nape.geom.IsoFunction;
import nape.geom.MarchingSquares;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.shape.Polygon;
import nape.space.Space;

import flash.display.BitmapData;

class Terrain implements IsoFunction {
    public var bitmap:BitmapData;

    private var cellSize:Number;
    private var subSize:Number;

    private var width:int;
    private var height:int;
    private var cells:Array;

    private var isoBounds:AABB;
    public var isoGranularity:Vec2;
    public var isoQuality:int = 8;

    public function Terrain(bitmap:BitmapData, cellSize:Number, subSize:Number):void {
        this.bitmap = bitmap;
        this.cellSize = cellSize;
        this.subSize = subSize;

        cells = [];
        width = Math.ceil(bitmap.width / cellSize);
        height = Math.ceil(bitmap.height / cellSize);
        for (var i:int = 0; i < width*height; i++) {
            cells.push(null);
        }

        isoBounds = new AABB(0, 0, cellSize, cellSize);
        isoGranularity = Vec2.get(subSize, subSize);
    }

    public function invalidate(region:AABB, space:Space):void {
        // compute effected cells.
        var x0:int = int(region.min.x/cellSize); if(x0<0) x0 = 0;
        var y0:int = int(region.min.y/cellSize); if(y0<0) y0 = 0;
        var x1:int = int(region.max.x/cellSize); if(x1>= width) x1 = width-1;
        var y1:int = int(region.max.y/cellSize); if(y1>=height) y1 = height-1;

        for (var y:int = y0; y <= y1; y++) {
        for (var x:int = x0; x <= x1; x++) {
            var b:Body = cells[y*width + x];
            if (b != null) {
                // If body exists, we'll simply re-use it.
                b.space = null;
                b.shapes.clear();
            }

            isoBounds.x = x*cellSize;
            isoBounds.y = y*cellSize;
            var polys:GeomPolyList = MarchingSquares.run(
                this,
                isoBounds,
                isoGranularity,
                isoQuality
            );
            if (polys.empty()) continue;

            if (b == null) {
                cells[y*width + x] = b = new Body(BodyType.STATIC);
            }

            for (var i:int = 0; i < polys.length; i++) {
                var p:GeomPoly = polys.at(i);
                var qolys:GeomPolyList = p.convexDecomposition(true);

                for (var j:int = 0; j < qolys.length; j++) {
                    var q:GeomPoly = qolys.at(j);
                    b.shapes.add(new Polygon(q));

                    // Recycle GeomPoly and its vertices
                    q.dispose();
                }

                // Recycle list nodes
                qolys.clear();

                // Recycle GeomPoly and its vertices
                p.dispose();
            }

            // Recycle list nodes
            polys.clear();

            b.space = space;
        }}
    }

    //iso-function for terrain, computed as a linearly-interpolated
    //alpha threshold from bitmap.
    public function iso(x:Number,y:Number):Number {
        var ix:int = int(x); if(ix<0) ix = 0; else if(ix>=bitmap.width)  ix = bitmap.width -1;
        var iy:int = int(y); if(iy<0) iy = 0; else if(iy>=bitmap.height) iy = bitmap.height-1;
        var fx:Number = x - ix; if(fx<0) fx = 0; else if(fx>1) fx = 1;
        var fy:Number = y - iy; if(fy<0) fy = 0; else if(fy>1) fy = 1;
        var gx:Number = 1-fx;
        var gy:Number = 1-fy;

        var a00:int = bitmap.getPixel32(ix,iy)>>>24;
        var a01:int = bitmap.getPixel32(ix,iy+1)>>>24;
        var a10:int = bitmap.getPixel32(ix+1,iy)>>>24;
        var a11:int = bitmap.getPixel32(ix+1,iy+1)>>>24;

        var ret:Number = gx*gy*a00 + fx*gy*a10 + gx*fy*a01 + fx*fy*a11;
        return 0x80-ret;
    }
}
