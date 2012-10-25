"strict"

function applyDocLinks()
{
    var links = {};
    links["Body"] = links["Bodies"] = "types/nape/phys/Body.html";
    links["Shape"] = links["Shapes"] = "types/nape/shape/Shape.html";
    links["Constraint"] = links["Constraints"] = "types/nape/constraint/Constraint.html";
    links["Compound"] = links["Compounds"] = "types/nape/phys/Compound.html";
    links["CbType"] = links["CbTypes"] = "types/nape/callbacks/CbType.html";
    links["Material"] = links["Materials"] = "types/nape/phys/Material.html";
    links["Circle"] = links["Circles"] = "types/nape/shape/Circle.html";
    links["Polygon"] = links["Polygons"] = "types/nape/shape/Polygon.html";
    links["GeomPoly"] = links["GeomPolys"] = "types/nape/geom/GeomPoly.html";
    links["MarchingSquares"] = "types/nape/geom/MarchingSquares.html";
    links["ForcedSleep"] = "types/nape/hacks/ForcedSleep.html";
    links["nape-hacks"] = "index.html#mod-nape-hacks";
    links["PivotJoint"] = "types/nape/constraint/PivotJoint.html";
    links["DistanceJoint"] = "types/nape/constraint/DistanceJoint.html";
    links["AngleJoint"] = "types/nape/constraint/AngleJoint.html";
    links["MotorJoint"] = "types/nape/constraint/MotorJoint.html";
    links["LineJoint"] = "types/nape/constraint/LineJoint.html";
    links["WeldJoint"] = "types/nape/constraint/WeldJoint.html";
    links["UserConstraint"] = links["UserConstraints"] = "types/nape/constraint/UserConstraint.html";
    links["nape-symbolic"] = "index.html#mod-nape-symbolic";
    links["SymbolicConstraint"] = "types/nape/symbolic/SymbolicConstraint.html";
    links["Listener"] = links["Listeners"] = "types/nape/callbacks/Listener.html";
    links["PreListener"] = links["PreListeners"] = "types/nape/callbacks/PreListener.html";
    links["Geom"] = "types/nape/geom/Geom.html";
    links["BitmapDebug"] = "types/nape/util/BitmapDebug.html";
    links["ShapeDebug"] = "types/nape/util/ShapeDebug.html";
    links["Vec2"] = "types/nape/geom/Vec2.html";
    links["Space"] = "types/nape/space/Space.html";
    links["Debug"] = "types/nape/util/Debug.html";
    links["Mat23"] = "types/nape/geom/Mat23.html";
    links["Callback"] = "types/nape/callbacks/Callback.html";
    links["InteractionListener"] = "types/nape/callbacks/InteractionListener.html";
    links["Arbiter"] = links["Arbiters"] = "types/nape/dynamics/Arbiter.html";
    links["Contact"] = links["Contacts"] = "types/nape/dynamics/Contact.html";

    function docLink(b)
    {
        var name = b.childNodes[0].nodeValue;
        var link = links[name];
        if (link)
        {
            b.innerHTML = "<a class='doclink' href='"+root+"docs/"+link+"'>"+name+"</a>";
        }
    }

    var bs = document.getElementsByTagName('b');
    for (var i = 0; i < bs.length; i ++)
    {
        var b = bs[i];
        if ($(b).attr("id") != "disabled-doc") {
            docLink(b);
        }
    }

}
