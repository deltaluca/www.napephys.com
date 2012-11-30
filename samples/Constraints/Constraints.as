package {

    /**
     *
     * Sample: Constraints
     * Author: Luca Deltodesco
     *
     * Simple demonstrations of all the in-built Nape constraints.
     * All of these constraints can be used in complement to
     * produce more complex behaviours.
     *
     * What is not demonstrated in this sample, is the use of the
     * UserConstraint API, and of the nape-symbolic module.
     *
     */

    import nape.constraint.AngleJoint;
    import nape.constraint.Constraint;
    import nape.constraint.DistanceJoint;
    import nape.constraint.LineJoint;
    import nape.constraint.MotorJoint;
    import nape.constraint.PivotJoint;
    import nape.constraint.PulleyJoint;
    import nape.constraint.WeldJoint;
    import nape.geom.Vec2;
    import nape.phys.Body;
    import nape.phys.BodyType;
    import nape.shape.Circle;
    import nape.shape.Polygon;

    // Template class is used so that this sample may
    // be as concise as possible in showing Nape features without
    // any of the boilerplate that makes up the sample interfaces.
    import Template;

    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    import flash.text.TextLineMetrics;

    public class Constraints extends Template {
        public function Constraints():void {
            super({
                gravity: Vec2.get(0, 600),
                noReset: true
            });
        }

        // Cell sizes
        private const cellWcnt:int = 3;
        private const cellHcnt:int = 3;
        private const cellWidth:Number = 800 / cellWcnt;
        private const cellHeight:Number = 600 / cellHcnt;
        private const size:Number = 22;

        override protected function init():void {
            var w:uint = stage.stageWidth;
            var h:uint = stage.stageHeight;

            createBorder();

            // Set debug draw to draw constraints
            debug.drawConstraints = true;

            // Constraint settings.
            var frequency:Number = 20.0;
            var damping:Number = 1.0;

            // Create regions for each constraint demo
            var regions:Body = new Body(BodyType.STATIC);
            var i:int;
            for (i = 1; i < cellWcnt; i++) {
                regions.shapes.add(new Polygon(Polygon.rect(i*cellWidth-0.5,0,1,h)));
            }
            for (i = 1; i < cellHcnt; i++) {
                regions.shapes.add(new Polygon(Polygon.rect(0,i*cellHeight-0.5,w,1)));
            }
            regions.space = space;

            // Common formatting of constraints.
            var format:Function = function (c:Constraint):void {
                c.stiff = false;
                c.frequency = frequency;
                c.damping = damping;
                c.space = space;
            };

            withCell(1, 0, "PivotJoint", function (x:Function, y:Function):void {
                var b1:Body = box(x(1*cellWidth/3),y(cellHeight/2),size);
                var b2:Body = box(x(2*cellWidth/3),y(cellHeight/2),size);

                var pivotPoint:Vec2 = Vec2.get(x(cellWidth/2),y(cellHeight/2));
                format(new PivotJoint(
                    b1, b2,
                    b1.worldPointToLocal(pivotPoint, true),
                    b2.worldPointToLocal(pivotPoint, true)
                ));
                pivotPoint.dispose();
            });

            withCell(2, 0, "WeldJoint", function (x:Function, y:Function):void {
                var b1:Body = box(x(1*cellWidth/3),y(cellHeight/2),size);
                var b2:Body = box(x(2*cellWidth/3),y(cellHeight/2),size);

                var weldPoint:Vec2 = Vec2.get(x(cellWidth/2),y(cellHeight/2));
                format(new WeldJoint(
                    b1, b2,
                    b1.worldPointToLocal(weldPoint, true),
                    b2.worldPointToLocal(weldPoint, true),
                    /*phase*/ Math.PI/4 /*45 degrees*/
                ));
                weldPoint.dispose();
            });

            withCell(0, 1, "DistanceJoint", function (x:Function, y:Function):void {
                var b1:Body = box(x(1.25*cellWidth/3),y(cellHeight/2),size);
                var b2:Body = box(x(1.75*cellWidth/3),y(cellHeight/2),size);

                format(new DistanceJoint(
                    b1, b2,
                    Vec2.weak(0, -size),
                    Vec2.weak(0, -size),
                    /*jointMin*/ cellWidth/3*0.75,
                    /*jointMax*/ cellWidth/3*1.25
                ));
            });

            withCell(1, 1, "LineJoint", function (x:Function, y:Function):void {
                var b1:Body = box(x(1*cellWidth/3),y(cellHeight/2),size);
                var b2:Body = box(x(2*cellWidth/3),y(cellHeight/2),size);

                var anchorPoint:Vec2 = Vec2.get(x(cellWidth/2),y(cellHeight/2));
                format(new LineJoint(
                    b1, b2,
                    b1.worldPointToLocal(anchorPoint, true),
                    b2.worldPointToLocal(anchorPoint, true),
                    /*direction*/ Vec2.weak(0, 1),
                    /*jointMin*/ -size,
                    /*jointMax*/ size
                ));
                anchorPoint.dispose();
            });

            withCell(2, 1, "PulleyJoint", function (x:Function, y:Function):void {
                var b1:Body = box(x(cellWidth/2),y(size),size/2, true);
                b1.scaleShapes(4, 1);

                var b2:Body = box(x(1*cellWidth/3),y(cellHeight/2),size/2);
                var b3:Body = box(x(2*cellWidth/3),y(cellHeight/2),size);

                format(new PulleyJoint(
                    b1, b2,
                    b1, b3,
                    Vec2.weak(-size*2, 0), Vec2.weak(0, -size/2),
                    Vec2.weak( size*2, 0), Vec2.weak(0, -size),
                    /*jointMin*/ cellHeight*0.75,
                    /*jointMax*/ cellHeight*0.75,
                    /*ratio*/ 2.5
                ));
            });

            withCell(0, 2, "AngleJoint", function (x:Function, y:Function):void {
                var b1:Body = box(x(1*cellWidth/3),y(cellHeight/2),size, true);
                var b2:Body = box(x(2*cellWidth/3),y(cellHeight/2),size, true);

                format(new AngleJoint(
                    b1, b2,
                    /*jointMin*/ -Math.PI*1.5,
                    /*jointMax*/ Math.PI*1.5,
                    /*ratio*/ 2
                ));
            });

            withCell(1, 2, "MotorJoint", function (x:Function, y:Function):void {
                var b1:Body = box(x(1*cellWidth/3),y(cellHeight/2),size, true);
                var b2:Body = box(x(2*cellWidth/3),y(cellHeight/2),size, true);

                format(new MotorJoint(
                    b1, b2,
                    /*rate*/ 10,
                    /*ratio*/ 3
                ));
            });

            // Description text
            withCell(0, 0, "", function (x:Function, y:Function):void {
                var txt:TextField = new TextField();
                var tf:TextFormat = new TextFormat(null,14,0xffffff);
                tf.align = TextFormatAlign.CENTER;
                txt.defaultTextFormat = tf;
                txt.text = "Constraints softened with\nfrequency="+frequency+"\ndamping="+damping;
                var metrics:TextLineMetrics = txt.getLineMetrics(0);
                txt.x = x(0);
                txt.y = y((cellHeight - metrics.height*3)/2);
                txt.width = cellWidth;
                txt.height = cellHeight;
                txt.selectable = false;
                addChild(txt);
            });
        }

        // Environment for each cell.
        private function withCell(i:int, j:int, title:String, f:Function):void {
            var txt:TextField = new TextField();
            var tf:TextFormat = new TextFormat(null,16,0xffffff);
            tf.align = TextFormatAlign.CENTER;
            txt.defaultTextFormat = tf;
            txt.text = title;
            var metrics:TextLineMetrics = txt.getLineMetrics(0);
            txt.x = i * cellWidth;
            txt.y = j * cellHeight;
            txt.width = cellWidth;
            txt.height = cellHeight;
            txt.selectable = false;
            addChild(txt);

            f(function (x:Number):Number { return x + (i * cellWidth); },
              function (y:Number):Number { return y + (j * cellHeight); });
        }

        // Box utility.
        private function box(x:Number, y:Number, radius:Number, pinned:Boolean=false):Body {
            var body:Body = new Body();
            body.position.setxy(x, y);
            body.shapes.add(new Polygon(Polygon.box(radius*2, radius*2)));
            body.space = space;
            if (pinned) {
                var pin:PivotJoint = new PivotJoint(
                    space.world, body,
                    body.position,
                    Vec2.weak(0,0)
                );
                pin.space = space;
            }
            return body;
        }
    }
}
