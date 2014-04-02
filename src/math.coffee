define [
],
-> 
    math = namespace 'Math'

    Function::property ?= (prop, desc) ->
        Object.defineProperty @prototype, prop, desc

    class math.Vector
        constructor: (@x, @y) ->

        equals: (v) -> @x == v.x and @y == v.y

        distance: (v) ->
            a = @x - v.x
            b = @y - v.y
            return Math.sqrt(a * a + b * b)

        shift: (dx, dy) ->
            return new math.Segment(this, new math.Vector(@x + dx, @y + dy))

        size: ->
            return Math.sqrt(@x * @x + @y * @y)

        normalize: ->
            size = @size()
            return new math.Vector(@x / size, @y / size)

    class math.Line
        constructor: (a, b, c) ->
            m = (if c > 0 then -1 else 1) / Math.sqrt(a * a + b * b)
            @A = a * m
            @B = b * m
            @C = c * m

        @from_vectors: (v1, v2) ->
            return new this(v1.y - v2.y, v2.x - v1.x, v1.x * v2.y - v2.x * v1.y)

        distance: (v) ->
            return @A * v.x + @B * v.y + @C

    class math.Segment
        constructor: (@v1, @v2) ->
            @line = math.Line.from_vectors(@v1, @v2)

        equals: (s) -> @v1.equals(s.v1) and @v2.equals(s.v2)

        intersect: (s) ->
            q1 = @line.distance(s.v1)
            q2 = @line.distance(s.v2)
            p1 = s.line.distance(@v1)
            p2 = s.line.distance(@v2)
      
            return q1 * q2 <= 0 and p1 * p2 <= 0

        draw: (ctx) ->
            ctx.moveTo(@v1.x, @v1.y)
            ctx.lineTo(@v2.x, @v2.y)

        @property 'length',
            get: -> @_length ?= @v1.distance(@v2)

        @property 'bounds',
            get: -> @_bounds ?= new math.Rect(@v1, @v2)

    class math.Rect
        constructor: (x1, y1, x2, y2) ->
            @min_x = Math.min(x1, x2)
            @min_y = Math.min(y1, y2)
            @max_x = Math.max(x1, x2)
            @max_y = Math.max(y1, y2)

            @width = @max_x - @min_x
            @height = @max_y - @min_y

        equals: (r) -> @min_x == r.min_x and @min_y == r.min_y and @max_x == r.max_x and @max_y == r.max_y

        @property 'tl',
            get: -> @_tl ?= new math.Vector(@min_x, @min_y)
        @property 'tr',
            get: -> @_tr ?= new math.Vector(@max_x, @min_y)
        @property 'br',
            get: -> @_br ?= new math.Vector(@max_x, @max_y)
        @property 'bl',
            get: -> @_bl ?= new math.Vector(@min_x, @max_y)
        @property 'center',
            get: ->@_center ?=  new math.Vector((@max_x + @min_x) / 2, (@max_y + @min_y) / 2)

        contains: (point) -> @min_x <= point.x <= @max_x and @min_y <= point.y <= @max_y
        
        @from_vectors: (v1, v2) ->
            return new this(v1.x, v1.y, v2.x, v2.y)

        intersect: (rect) ->
            return false if @min_x > rect.max_x
            return false if @max_x < rect.min_x
            return false if @min_y > rect.max_y
            return false if @max_y < rect.min_y
            return true

        union: (rect) ->
            return new math.Rect(
                Math.min(@min_x, rect.min_x),
                Math.min(@min_y, rect.min_y),
                Math.max(@max_x, rect.max_x),
                Math.max(@max_y, rect.max_y))

        draw: (ctx) ->
            ctx.moveTo(@min_x, @min_y)
            ctx.lineTo(@max_x, @min_y)
            ctx.lineTo(@max_x, @max_y)
            ctx.lineTo(@min_x, @max_y)
            ctx.lineTo(@min_x, @min_y)

    math.bezierPolinom = (a, b, c, d, t) ->
        k = 1 - t
        return k * k * (k * a + 3 * t * b) + t * t * (3 * k * c + t * d)

    math.bezierPoint = (a, b, c, d, t) ->
        return new math.Vector(
            math.bezierPolinom(a.x, b.x, c.x, d.x, t), 
            math.bezierPolinom(a.y, b.y, c.y, d.y, t))

    math.lerp = (a, b, t) ->
        return (1 - t) * a + t * b;

    math.bezierCasteljau = (a, b, c, d, t) ->
        p = math.lerp(a, b, t)
        q = math.lerp(b, c, t)
        r = math.lerp(c, d, t)

        s = math.lerp(p, q, t)
        u = math.lerp(q, r, t)

        return math.lerp(s, u, t)

    math.bezierCurveBounds = (a, b, c, d) ->
        minx = miny = Number.POSITIVE_INFINITY
        maxx = maxy = Number.NEGATIVE_INFINITY

        tobx = b.x - a.x
        toby = b.y - a.y

        tocx = c.x - b.x
        tocy = c.y - b.y

        todx = d.x - c.x
        tody = d.y - c.y

        step = 1/40

        for i in [0..40]
            d = i * step

            px = a.x + d*tobx
            py = a.y + d*toby
            qx = b.x + d*tocx
            qy = b.y + d*tocy
            rx = c.x + d*todx
            ry = c.y + d*tody
            
            toqx = qx - px
            toqy = qy - py
            torx = rx - qx
            tory = ry - qy

            sx = px + d*toqx
            sy = py + d*toqy
            tx = qx + d*torx
            ty = qy + d*tory
            
            totx = tx - sx
            toty = ty - sy

            x = sx + d*totx
            y = sy + d*toty
            
            minx = Math.min(minx, x)
            miny = Math.min(miny, y)
            maxx = Math.max(maxx, x)
            maxy = Math.max(maxy, y)
        
        return new math.Rect(minx, miny, maxx, maxy)
