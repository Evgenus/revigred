class revigred.Vector
    constructor: (@x, @y) ->

    distance: (v) ->
        a = @x - v.x
        b = @y - v.y
        return Math.sqrt(a * a + b * b)

class revigred.Line
    constructor: (a, b, c) ->
        m = (if c > 0 then -1 else 1) / Math.sqrt(a * a + b * b)
        @A = a * m
        @B = b * m
        @C = c * m

    @from_vectors: (v1, v2) ->
        return new Line(v1.y - v2.y, v2.x - v1.x, v1.x * v2.y - v2.x * v1.y)

    distance: (v) ->
        return @A * v.x + @B * v.y + @C

class revigred.Segment
    constructor: (@v1, @v2) ->
        @line = Line.from_vectors(@v1, @v2)

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
