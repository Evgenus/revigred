class Gizmo

class EdgeGizmo extends Gizmo
    constructor: (@connector1, @connector2) ->

    getControlPoints: (v0, v1, v2, t) ->
        d01 = Math.sqrt((v1.x - v0.x) * (v1.x - v0.x) + (v1.y - v0.y) * (v1.y - v0.y))
        d12 = Math.sqrt((v2.x - v1.x) * (v2.x - v1.x) + (v2.y - v1.y) * (v2.y - v1.y))

        fa = t * d01 / (d01 + d12)
        fb = t * d12 / (d01 + d12)

        return [
            new Segment(v1, new Vector(v1.x - fa * (v2.x - v0.x), v1.y - fa * (v2.y - v0.y))),
            new Segment(v1, new Vector(v1.x + fb * (v2.x - v0.x), v1.y + fb * (v2.y - v0.y)))
            ]

    render: (ctx)->
        pos1 = @connector1.pos()
        pos2 = @connector2.pos()

        start = pos1.v1
        end = pos2.v1
        edge = new Segment(start, end)

        bounds1 = @connector1.model.node.bounds()
        width1 = bounds1.v2.x - bounds1.v1.x
        height1 = bounds1.v2.y - bounds1.v1.y
        center1 = new Vector((bounds1.v1.x + bounds1.v2.x) / 2, (bounds1.v1.y + bounds1.v2.y) / 2)

        bounds2 = @connector2.model.node.bounds()
        width2 = bounds2.v2.x - bounds2.v1.x
        height2 = bounds2.v2.y - bounds2.v1.y
        center2 = new Vector((bounds2.v1.x + bounds2.v2.x) / 2, (bounds2.v1.y + bounds2.v2.y) / 2)

        #d = Math.sqrt(width1 * width1 + height1 * height1) + Math.sqrt(width2 * width2 + height2 * height2)
        #c = Math.min(d, center1.distance(center2)) / d
        c = 1

        v_ur1 = new Vector(center1.x + width1 * c, center1.y - height1 * c)
        v_dr1 = new Vector(center1.x + width1 * c, center1.y + height1 * c)
        v_ul1 = new Vector(center1.x - width1 * c, center1.y - height1 * c)
        v_dl1 = new Vector(center1.x - width1 * c, center1.y + height1 * c)
        s_ur1 = new Segment(center1, v_ur1)
        s_dr1 = new Segment(center1, v_dr1)
        s_ul1 = new Segment(center1, v_ul1)
        s_dl1 = new Segment(center1, v_dl1)

        v_ur2 = new Vector(center2.x + width2 * c, center2.y - height2 * c)
        v_dr2 = new Vector(center2.x + width2 * c, center2.y + height2 * c)
        v_ul2 = new Vector(center2.x - width2 * c, center2.y - height2 * c)
        v_dl2 = new Vector(center2.x - width2 * c, center2.y + height2 * c)
        s_ur2 = new Segment(center2, v_ur2)
        s_dr2 = new Segment(center2, v_dr2)
        s_ul2 = new Segment(center2, v_ul2)
        s_dl2 = new Segment(center2, v_dl2)

        ctx.strokeStyle = "rgb(0,0,0)"
        ctx.lineWidth = 2
        ctx.beginPath()

        points = []

        if edge.intersect(s_ur1)
            points.push(v_ur1) 
        if edge.intersect(s_dr1)
            points.push(v_dr1) 
        if edge.intersect(s_ul1)
            points.push(v_ul1) 
        if edge.intersect(s_dl1)
            points.push(v_dl1) 
        if edge.intersect(s_ur2)
            points.push(v_ur2) 
        if edge.intersect(s_dr2)
            points.push(v_dr2) 
        if edge.intersect(s_ul2)
            points.push(v_ul2) 
        if edge.intersect(s_dl2)
            points.push(v_dl2) 

        # s_ur1.draw(ctx)
        # s_dr1.draw(ctx)
        # s_ul1.draw(ctx)
        # s_dl1.draw(ctx)
        # s_ur2.draw(ctx)
        # s_dr2.draw(ctx)
        # s_ul2.draw(ctx)
        # s_dl2.draw(ctx)

        points = points.sort((a, b) -> start.distance(a) - start.distance(b))

        points.unshift(start)
        points.push(end)

        path = [pos1]
        if points.length > 2
            for i in [2..points.length - 1]
                cp = @getControlPoints(points[i-2], points[i-1], points[i], 0.5)
                path.push(cp...)
        path.push(pos2)

        ctx.moveTo(pos1.v1.x, pos1.v1.y)
        for i in [0..path.length-1] by 2
            cur = path[i]
            next = path[i+1]
            ctx.bezierCurveTo(
                cur.v2.x,cur.v2.y,
                next.v2.x, next.v2.y,
                next.v1.x, next.v1.y
                )

        ctx.stroke()