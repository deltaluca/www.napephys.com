"strict"

function applyDocLinks()
{
    var links = {};
    links["Body"] = links["Bodies"] = "types/nape/phys/Body.html";
    links["Shape"] = links["Shapes"] = "types/nape/shape/Shape.html";
    links["Constraint"] = links["Constraints"] = "types/nape/constraint/Constraint.html";
    links["Compound"] = links["Compounds"] = "types/nape/phys/Compound.html";
    links["CbType"] = links["CbTypes"] = "types/nape/callbacks/CbType.html";
    links["CbEvent"] = links["CbEvents"] = "types/nape/callbacks/CbEvent.html";
    links["OptionType"] = links["OptionTypes"] = "types/nape/callbacks/OptionType.html";
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
    links["BodyListener"] = links["BodyListeners"] = "types/nape/callbacks/BodyListener.html";
    links["InteractionListener"] = links["InteractionListeners"] = "types/nape/callbacks/InteractionListener.html";
    links["ConstraintListener"] = links["ConstraintListeners"] = "types/nape/callbacks/ConstraintListener.html";
    links["PreListener"] = links["PreListeners"] = "types/nape/callbacks/PreListener.html";
    links["Geom"] = "types/nape/geom/Geom.html";
    links["BitmapDebug"] = "types/nape/util/BitmapDebug.html";
    links["ShapeDebug"] = "types/nape/util/ShapeDebug.html";
    links["Vec2"] = links["Vec2s"] = "types/nape/geom/Vec2.html";
    links["Vec3"] = links["Vec3s"] = "types/nape/geom/Vec3.html";
    links["Space"] = "types/nape/space/Space.html";
    links["Debug"] = "types/nape/util/Debug.html";
    links["Edge"] = links["Edges"] = "types/nape/shape/Edge.html";
    links["Mat23"] = "types/nape/geom/Mat23.html";
    links["Callback"] = "types/nape/callbacks/Callback.html";
    links["Arbiter"] = links["Arbiters"] = "types/nape/dynamics/Arbiter.html";
    links["FluidArbiter"] = links["FluidArbiters"] = "types/nape/dynamics/Arbiter.html";
    links["CollisionArbiter"] = links["CollisionArbiters"] = "types/nape/dynamics/Arbiter.html";
    links["Contact"] = links["Contacts"] = "types/nape/dynamics/Contact.html";
    links["FluidProperties"] = "types/nape/phys/FluidProperties.html";
    links["InteractionFilter"] = links["InteractionFilters"] = "types/nape/dynamics/InteractionFilter.html";
    links["InteractionGroup"] = links["InteractionGroups"] = "types/nape/dynamics/InteractionGroup.html";
    links["Vec2List"] = links["Vec2Lists"] = "types/nape/geom/Vec2List.html";
    links["CbTypeList"] = links["CbTypeLists"] = "types/nape/callbacks/CbTypeList.html";
    links["BodyCallback"] = "types/nape/callbacks/BodyCallback.html";
    links["InteractionCallback"] = links["InteractionCallbacks"] = "types/nape/callbacks/InteractionCallback.html";
    links["InteractionType"] = "types/nape/callbacks/InteractionType.html";
    links["ConstraintCallback"] = "types/nape/callbacks/ConstraintCallback.html";
    links["PreCallback"] = links["PreCallbacks"] = "types/nape/callbacks/PreCallback.html";
    links["PreFlag"] = "types/nape/callbacks/PreFlag.html";
    links["Interactor"] = links["Interactors"] = "types/nape/phys/Interactor.html";

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
