define [
],
-> 
    math = namespace 'revigred.math'


    class math.Vector
        constructor: (@x, @y) ->

        distance: (v) ->
            a = @x - v.x
            b = @y - v.y
            return Math.sqrt(a * a + b * b)

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

        intersect: (segment) ->
            q1 = @line.distance(segment.v1)
            q2 = @line.distance(segment.v2)
            p1 = segment.line.distance(@v1)
            p2 = segment.line.distance(@v2)
      
            return q1 * q2 <= 0 and p1 * p2 <= 0

        draw: (ctx) ->
            ctx.moveTo(@v1.x, @v1.y)
            ctx.lineTo(@v2.x, @v2.y)

        length: -> @v1.distance(@v2)

        bounds: -> new math.Rect(@v1, @v2)

    class math.Rect
        constructor: (x1, y1, x2, y2) ->
            @min_x = Math.min(x1, x2)
            @min_y = Math.min(y1, y2)
            @max_x = Math.max(x1, x2)
            @max_y = Math.max(y1, y2)

            @width = @max_x - @min_x
            @height = @max_y - @min_y

        tl: -> new math.Vector(@min_x, @min_y)
        tr: -> new math.Vector(@max_x, @min_y)
        br: -> new math.Vector(@max_x, @max_y)
        bl: -> new math.Vector(@min_x, @max_y)
        center: -> new math.Vector((@max_x - @min_x) / 2, (@max_y - @min_y) / 2)

        contains: (point) -> @min_x <= point.x <= @max_x and @min_y <= point.y <= @max_y
        
        @from_vectors: (v1, v2) ->
            return new this(v1.x, v1.y, v2.x, v2.y)

        intersect: (rect) ->
            return false if @min_x > rect.max_x
            return false if @max_x < rect.min_x
            return false if @min_y > rect.max_y
            return false if @max_y < rect.min_y
            return true