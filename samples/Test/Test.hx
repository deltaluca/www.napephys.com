package;

import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.phys.Material;
import nape.phys.Compound;
import nape.shape.Polygon;
import nape.shape.Circle;
import nape.callbacks.CbType;
import nape.callbacks.InteractionType;
import nape.callbacks.CbEvent;
import nape.callbacks.InteractionCallback;
import nape.callbacks.InteractionListener;

// Template class is used so that this sample may
// be as concise as possible in showing Nape features without
// any of the boilerplate that makes up the sample interfaces.
import Template;

class Test extends Template {
    static function main() {
        flash.Lib.current.addChild(new Test());
    }

    var BREAKER:CbType;
    var breakApart:Array<Body>;

    function new() {
        super({
            gravity : Vec2.get(0, 600),
            variableStep : false
        });

        BREAKER = new CbType();
    }

    override function init() {
        super.createBorder();

        for (x in 0...6) {
            for (y in 0...6) {
                bigBox(400 + (x - 2.5) * 40, 600 - (y + 0.5) * 39).space = space;
            }
        }
        breakApart = [];

        space.listeners.add(new InteractionListener(
            CbEvent.ONGOING,
            InteractionType.COLLISION,
            BREAKER,
            CbType.ANY_BODY,
            breakHandler
        ));
    }

    function bigBox(x:Float, y:Float) {
        var box = new Body();
        box.shapes.add(new Polygon(Polygon.box(40, 40)));
        box.position.setxy(x, y);
        box.cbTypes.add(BREAKER);
        return box;
    }

    function breakHandler(cb:InteractionCallback) {
        var breaker = cb.int1.castBody;
        var other = cb.int2.castBody;
        breakIt(breaker, other);
    }

    function breakIt(b:Body, q:Body) {
        var impulse = b.normalImpulse(q, true);
        var impulseXY = impulse.xy();
        if (impulseXY.length > 100)
        {
            breakApart.push(b);
            if (q.cbTypes.has(BREAKER)) {
                breakApart.push(q);
            }
        }
        impulseXY.dispose();
        impulse.dispose();
    }

    override function update(deltaTime:Float) {
        // Template takes care of calling space.step() and
        // debug drawing calls for space.

        while (breakApart.length > 0) {
            var body = breakApart.pop();
            if (body.space == null) {
                continue;
            }

            body.space = null;
            if (hand.body2 == body) {
                hand.active = false;
            }

            for (y in 0...4) {
                for (x in 0...4) {
                    var b = new Body();
                    b.position = body.localPointToWorld(Vec2.weak(-15 + x*10, -15 + y*10));
                    b.rotation = body.rotation;
                    b.velocity = body.velocity;
                    b.velocity.addeq((b.position.sub(body.position)).muleq(20));
                    b.angularVel = body.angularVel;
                    b.shapes.add(new Polygon(Polygon.box(10, 10)));
                    b.space = space;
                }
            }
        }
    }
}
