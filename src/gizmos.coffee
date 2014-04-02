define 'revigred.gizmos', [
],
-> 
    Math = namespace 'Math'

    class @Gizmo

    class @EdgeGizmo extends @Gizmo
        _debug = true
 
        constructor: (@connector1, @connector2) ->

        @getControlPoints: (v0, v1, v2, t) ->

            d01 = v1.distance(v0)
            d12 = v2.distance(v1)

            fa = t * d01 / (d01 + d12)
            fb = t * d12 / (d01 + d12)

            return [
                v1.shift(- fa * (v2.x - v0.x), - fa * (v2.y - v0.y)),
                v1.shift(+ fb * (v2.x - v0.x), + fb * (v2.y - v0.y))
                ]

        @drawDir: (ctx, connector, v) ->
            pos = connector.pos()

            start = pos.v1
            edge = new math.Segment(start, v)

            bounds = connector.node.bounds()
            width = bounds.width
            height = bounds.height
            center = bounds.center

            c = 0.7
            points = []

            s_ur = center.shift(+width*c, -height*c)
            s_dr = center.shift(+width*c, +height*c)
            s_ul = center.shift(-width*c, -height*c)
            s_dl = center.shift(-width*c, +height*c)

            points.push(s_ur.v2) if edge.intersect(s_ur)
            points.push(s_dr.v2) if edge.intersect(s_dr)
            points.push(s_ul.v2) if edge.intersect(s_ul)
            points.push(s_dl.v2) if edge.intersect(s_dl)

            points.forEach (p) -> p.metric = start.distance(p)

            points = points.sort((a, b) -> a.metric - b.metric)

            if points.length > 2
                points = [points[0], points[points.length-1]]

            points.unshift(start)
            points.push(v)

            ctx.moveTo(pos.v1.x, pos.v1.y)

            path = [pos]
            if points.length > 2
                for i in [2..points.length - 1]
                    cp = @getControlPoints(points[i-2], points[i-1], points[i], 0.5)
                    path.push(cp...)

            dir = new math.Vector(start.x - v.x, start.y - v.y)
                .normalize()
            path.push(v.shift(dir.x * 50, dir.y * 50))

            for i in [0..path.length-1] by 2
                cur = path[i]
                next = path[i+1]
                ctx.bezierCurveTo(
                    cur.v2.x,cur.v2.y,
                    next.v2.x, next.v2.y,
                    next.v1.x, next.v1.y
                    )

        makepath: (pos1, pos2) ->
            pos1.draw(ctx) if @_debug
            pos2.draw(ctx) if @_debug

            start = pos1.v1
            end = pos2.v1
            edge = new math.Segment(start, end)
            edge.draw(ctx) if @_debug

            bounds1 = @connector1.node.bounds()
            width1 = bounds1.width
            height1 = bounds1.height
            center1 = bounds1.center
            bounds1.draw(ctx) if @_debug

            bounds2 = @connector2.node.bounds()
            width2 = bounds2.width
            height2 = bounds2.height
            center2 = bounds2.center
            bounds2.draw(ctx) if @_debug

            same_node = @connector1.node is @connector2.node
            if same_node
                c = 0.7
            else
                d = Math.sqrt(width1 * width1 + height1 * height1) + Math.sqrt(width2 * width2 + height2 * height2)
                c = Math.min(1+d, edge.length) / d

            points = []

            s_ur1 = center1.shift(+width1*c, -height1*c)
            s_dr1 = center1.shift(+width1*c, +height1*c)
            s_ul1 = center1.shift(-width1*c, -height1*c)
            s_dl1 = center1.shift(-width1*c, +height1*c)

            points.push(s_ur1.v2) if edge.intersect(s_ur1)
            points.push(s_dr1.v2) if edge.intersect(s_dr1)
            points.push(s_ul1.v2) if edge.intersect(s_ul1)
            points.push(s_dl1.v2) if edge.intersect(s_dl1)

            s_ur1.draw(ctx) if @_debug
            s_dr1.draw(ctx) if @_debug
            s_ul1.draw(ctx) if @_debug
            s_dl1.draw(ctx) if @_debug

            if not same_node
                s_ur2 = center2.shift(+width2*c, -height2*c)
                s_dr2 = center2.shift(+width2*c, +height2*c)
                s_ul2 = center2.shift(-width2*c, -height2*c)
                s_dl2 = center2.shift(-width2*c, +height2*c)

                points.push(s_ur2.v2) if edge.intersect(s_ur2)
                points.push(s_dr2.v2) if edge.intersect(s_dr2)
                points.push(s_ul2.v2) if edge.intersect(s_ul2)
                points.push(s_dl2.v2) if edge.intersect(s_dl2)

                s_ur2.draw(ctx) if @_debug
                s_dr2.draw(ctx) if @_debug
                s_ul2.draw(ctx) if @_debug
                s_dl2.draw(ctx) if @_debug

            points.forEach (p) -> p.metric = start.distance(p)

            points = points.sort((a, b) -> a.metric - b.metric)

            if points.length > 2
                points = [points[0], points[points.length-1]]

            points.unshift(start)
            points.push(end)

            path = [pos1]
            if points.length > 2
                for i in [2..points.length - 1]
                    cp = EdgeGizmo.getControlPoints(points[i-2], points[i-1], points[i], 0.5)
                    path.push(cp...)
            path.push(pos2)
            return path

        draw: (ctx)->
            pos1 = @connector1.pos()
            pos2 = @connector2.pos()

            if not (@_p1? and @_p2? and @_p1.equals(pos1) and @_p2.equals(pos2))
                @path = @makepath(pos1, pos2)

            @_p1 = pos1
            @_p2 = pos2

            bounds = null

            ctx.moveTo(pos1.v1.x, pos1.v1.y)
            for i in [0..@path.length-1] by 2
                cur = @path[i]
                next = @path[i+1]
                ctx.bezierCurveTo(
                    cur.v2.x,cur.v2.y,
                    next.v2.x, next.v2.y,
                    next.v1.x, next.v1.y
                    )

                rect = Math.bezierCurveBounds(cur.v1, cur.v2, next.v2, next.v1)
                if bounds == null
                    bounds = rect
                else
                    bounds = bounds.union(rect)

            bounds.draw(ctx) if @_debug
