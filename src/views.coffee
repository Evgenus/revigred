define [
    "Backbone.View"
],
-> 
    views = namespace "revigred.views"
    math = namespace "revigred.math"

    class views.GraphView extends Backbone.View
        render: (@callback) ->
            nodes = new views.NodesView
                model: @model.nodes
                el: @el
            nodes.render()
            self = this
            @$el.mouseup (ev) ->  self.model.drop_start()
            @canvas = @$("canvas")[0]
            @context = @canvas.getContext("2d")
            @draw()
            $(window).resize(_.bind(@resize, this))
            @resize()

        resize: ->
            @canvas.width = @$el.innerWidth()
            @canvas.height = @$el.innerHeight()

        draw: ->
            requestAnimationFrame(_.bind(@draw, this))
            @callback?()
            @context.clearRect(0, 0, @$el.innerWidth(), @$el.innerHeight())
            for gizmo in @model.gizmos
                gizmo.render(@context)

    class views.NodesView extends Backbone.View
        constructor: (options) ->
            super(options)
            @model.on('add', @addOne, this)
            @model.on('reset', @addAll, this)

        addAll: () ->
            @model.forEach(@addOne, this)

        addOne: (connector) ->
            view = new views.NodeView
                model: connector
            @$el.append(view.render().el)

        render: () ->
            @addAll()
            return this

    class views.NodeView extends Backbone.View
        tagName: 'div'
        className: 'node ui-widget ui-widget-content ui-corner-all'

        constructor: (options) ->
            super(options)
            @model.set_bounds(_.bind(@bounds, this))

        render: () ->
            left = new views.LeftConnectorsView
                model: @model.left
            right = new views.RightConnectorsView
                model: @model.right
            self = this
            @$el
                .draggable
                    handle: ".ui-widget-header"
                    scroll: false
                    stack: ".node"
                .css("left", @model.get("x"))
                .css("top", @model.get("y"))
                .css("position", "absolute")
                .append(@make("div", {class: "ui-widget-header ui-corner-top"}, @model.get("title")))
                .append(left.render().el)
                .append(right.render().el)
            return this

        bounds: () ->
            x0 = @el.offsetLeft
            y0 = @el.offsetTop
            x1 = x0 + @el.offsetWidth
            y1 = y0 + @el.offsetHeight
            return new math.Segment(
                new math.Vector(x0, y0), 
                new math.Vector(x1, y1))

    class views.ConnectorsView extends Backbone.View
        tagName: 'ui'

        constructor: (options) ->
            super(options)
            @model.on('add', @addOne, this)
            @model.on('reset', @addAll, this)

        addAll: () ->
            @model.forEach(@addOne, this)

        render: () ->
            @addAll()
            return this

    class views.LeftConnectorsView extends views.ConnectorsView
        className: 'left-connectors'

        addOne: (connector) ->
            view = new views.LeftConnectorView
                model: connector
            @$el.append(view.render().el)

    class views.RightConnectorsView extends views.ConnectorsView
        className: 'right-connectors'
        render: () ->
            super()
            @$el.attr("dir", "rtl")
            return this

        addOne: (connector) ->
            view = new views.RightConnectorView
                model: connector
            @$el.append(view.render().el)

    class views.ConnectorView extends Backbone.View
        tagName: 'li'

        className: 'connector ui-state-default'

        constructor: (options) ->
            super(options)

        render: () ->
            self = this
            @$el.text(@model.get("title"))
                .mousedown (ev) -> 
                    self.model.node.graph?.pick_start(self)
                    ev.stopPropagation()
                    false
                .mouseup (ev) -> 
                    self.model.node.graph?.pick_end(self)
                    ev.stopPropagation()
                    false
                .hover () -> $(this).toggleClass("ui-state-highlight")
            return this

    class views.LeftConnectorView extends views.ConnectorView
        className: 'connector ui-state-default ui-corner-left'

        pos: ->
            pos = @$el.offset()
            x0 = pos.left
            y0 = pos.top + @$el.outerHeight() / 2
            x1 = x0 - 50
            y1 = y0
            return new math.Segment(
                new math.Vector(x0, y0), 
                new math.Vector(x1, y1))

    class views.RightConnectorView extends views.ConnectorView
        className: 'connector ui-state-default ui-corner-right'

        pos: ->
            pos = @$el.offset()
            x0 = pos.left + @$el.outerWidth()
            y0 = pos.top + @$el.outerHeight() / 2
            x1 = x0 + 50
            y1 = y0
            return new math.Segment(
                new math.Vector(x0, y0), 
                new math.Vector(x1, y1))
