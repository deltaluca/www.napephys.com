package {

    /**
     *
     * Sample: Body From Graphic
     * Author: Luca Deltodesco
     *
     * Using MarchingSquares to generate Nape bodies
     * from both a BitmapData and a standard DisplayObject.
     *
     */

    import nape.geom.Vec2;
    import nape.phys.Body;
    import nape.phys.BodyType;

    // Template class is used so that this sample may
    // be as concise as possible in showing Nape features without
    // any of the boilerplate that makes up the sample interfaces.
    import Template;

    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.display.StageQuality;

    public class BodyFromGraphic extends Template {
        public function BodyFromGraphic():void {
            super({
                gravity : Vec2.get(0, 600),
                noReset : true
            });
        }

        [Embed(source="cog.png")]
        private var Cog:Class;

        override protected function init():void {
            var w:uint = stage.stageWidth;
            var h:uint = stage.stageHeight;

            stage.quality = StageQuality.LOW;

            createBorder();

            // Create some Bodies generated from a Bitmap (the cogs)
            // With a body generated from a DisplayObject inside
            // (the intersected circles).
            var cogIso:BitmapDataIso = new BitmapDataIso((new Cog()).bitmapData, 0x80);
            var cogBody:Body = IsoBody.run(cogIso, cogIso.bounds);

            var circles:Function = function():DisplayObject {
                var displayObject:Sprite = new Sprite();
                displayObject.graphics.lineStyle(0,0,0);
                displayObject.graphics.beginFill(0, 1);
                displayObject.graphics.drawCircle(-10, 17.32, 30);
                displayObject.graphics.drawCircle(-10, -17.32, 30);
                displayObject.graphics.drawCircle(20, 0, 30);
                displayObject.graphics.endFill();
                return displayObject;
            }
            var objIso:DisplayObjectIso = new DisplayObjectIso(circles());
            // Flash requires an object to be on stage for hitTestPoint used
            // by the iso-function to work correctly. SIGH.
            addChild(objIso.displayObject);
            var objBody:Body = IsoBody.run(objIso, objIso.bounds);
            removeChild(objIso.displayObject);

            for (var i:int = 0; i < 4; i++) {
            for (var j:int = 0; j < 2; j++) {
                var body:Body = cogBody.copy();
                body.position.setxy(100 + 200*i, 400 - 200*j);
                body.space = space;

                var graphic:DisplayObject = cogIso.graphic();
                graphic.alpha = 0.6;
                addChild(graphic);
                body.userData.graphic = graphic;

                body = objBody.copy();
                body.position.setxy(100 + 200*i, 400 - 200*j);
                body.space = space;

                graphic = circles();
                graphic.alpha = 0.6;
                addChild(graphic);
                body.userData.graphic = graphic;
            }}
        }

        override protected function postUpdate(deltaTime:Number):void {
            // Update positions for Flash graphics.
            for (var i:int = 0; i < space.liveBodies.length; i++) {
                var body:Body = space.liveBodies.at(i);

                var graphic:DisplayObject = body.userData.graphic;
                if (graphic == null) continue;

                var graphicOffset:Vec2 = body.userData.graphicOffset;
                var position:Vec2 = body.localPointToWorld(graphicOffset);
                graphic.x = position.x;
                graphic.y = position.y;
                graphic.rotation = (body.rotation * 180/Math.PI) % 360;
                position.dispose();
            }
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
import nape.shape.Polygon;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.DisplayObject;

class IsoBody {
    public static function run(iso:IsoFunction, bounds:AABB, granularity:Vec2=null, quality:int=2, simplification:Number=1.5):Body {
        var body:Body = new Body();

        if (granularity==null) granularity = Vec2.weak(8, 8);
        var polys:GeomPolyList = MarchingSquares.run(iso, bounds, granularity, quality);
        for (var i:int = 0; i < polys.length; i++) {
            var p:GeomPoly = polys.at(i);

            var qolys:GeomPolyList = p.simplify(simplification).convexDecomposition(true);
            for (var j:int = 0; j < qolys.length; j++) {
                var q:GeomPoly = qolys.at(j);

                body.shapes.add(new Polygon(q));

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

        // Align body with its centre of mass.
        // Keeping track of our required graphic offset.
        var pivot:Vec2 = body.localCOM.mul(-1);
        body.translateShapes(pivot);

        body.userData.graphicOffset = pivot;
        return body;
    }
}

class DisplayObjectIso implements IsoFunction {
    public var displayObject:DisplayObject;
    public var bounds:AABB;

    public function DisplayObjectIso(displayObject:DisplayObject):void {
        this.displayObject = displayObject;
        this.bounds = AABB.fromRect(displayObject.getBounds(displayObject));
    }

    public function iso(x:Number, y:Number):Number {
        // Best we can really do with a generic DisplayObject
        // is to return a binary value {-1, 1} depending on
        // if the sample point is in or out side.

        return (displayObject.hitTestPoint(x, y, true) ? -1.0 : 1.0);
    }
}

class BitmapDataIso implements IsoFunction {
    public var bitmap:BitmapData;
    public var alphaThreshold:Number;
    public var bounds:AABB;

    public function BitmapDataIso(bitmap:BitmapData, alphaThreshold:Number = 0x80):void {
        this.bitmap = bitmap;
        this.alphaThreshold = alphaThreshold;
        bounds = new AABB(0, 0, bitmap.width, bitmap.height);
    }

    public function graphic():DisplayObject {
        return new Bitmap(bitmap);
    }

    public function iso(x:Number, y:Number):Number {
        // Take 4 nearest pixels to interpolate linearly.
        // This gives us a smooth iso-function for which
        // we can use a lower quality in MarchingSquares for
        // the root finding.

        var ix:int = int(x); var iy:int = int(y);
        //clamp in-case of numerical inaccuracies
        if(ix<0) ix = 0; if(iy<0) iy = 0;
        if(ix>=bitmap.width)  ix = bitmap.width-1;
        if(iy>=bitmap.height) iy = bitmap.height-1;

        // iso-function values at each pixel centre.
        var a11:Number = alphaThreshold - (bitmap.getPixel32(ix,iy)>>>24);
        var a12:Number = alphaThreshold - (bitmap.getPixel32(ix+1,iy)>>>24);
        var a21:Number = alphaThreshold - (bitmap.getPixel32(ix,iy+1)>>>24);
        var a22:Number = alphaThreshold - (bitmap.getPixel32(ix+1,iy+1)>>>24);

        // Bilinear interpolation for sample point (x,y)
        var fx:Number = x - ix; var fy:Number = y - iy;
        return a11*(1-fx)*(1-fy) + a12*fx*(1-fy) + a21*(1-fx)*fy + a22*fx*fy;
    }
}
