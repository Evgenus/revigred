define [
    "Backbone.View"
],
-> 
    views = namespace "revigred.views"
    math = namespace "revigred.math"

    class RectangularSelector extends Backbone.View
        setup: (@x, @y) ->
            @$el.show()
            @position = @$el.offset()
            @update(@x, @y)

        render: ->
            @el = @make("div", class: "selector")
            @rect = @make("div", class: "rectangle ui-state-highlight")
            @$rect = $(@rect)
            @$el = $(@el)
                .hide()
                .append(@$rect)
                .mouseup (event) =>
                    @$el.hide()
                    @on_done?()
                    return false
                .mousemove (event) =>
                    @update(event.pageX, event.pageY)
                    return false
            return this

        update: (x, y) ->
            rect = new math.Rect(
                @x - @position.left, @y - @position.top, 
                x - @position.left, y - @position.top)
            @$rect
                .css("left", rect.min_x)
                .css("top", rect.min_y)
                .css("width", rect.width)
                .css("height", rect.height)
            @on_changed?(rect)

        changed: (@on_changed) -> this

    class views.GraphView extends Backbone.View
        dragging: false

        constructor: (options) ->
            super(options)
            @selector = new RectangularSelector()
                .changed(_.bind(@_on_selection_rect_changed, this))

        events:
            "mouseup"                   : "_on_mouseup"
            "mousedown"                 : "_on_mousedown"
            "mousemove"                 : "_on_mousemove"
            "click"                     : "_on_click"

        _on_selection_rect_changed: (rect) ->
            selected = @model.nodes.filter (node) -> 
                rect.intersect(node.bounds())
            for added in _.difference(selected, @_rect_selected)
                added.select()
            for removed in _.difference(@_rect_selected, selected)
                removed.deselect()
            @_rect_selected = selected

        _on_mousedown: (event) ->
            if event.shiftKey
                @_rect_selected = []
                @selector.setup(event.pageX, event.pageY)
            else
                @dragging = 
                    x: event.pageX
                    y: event.pageY
                @$el.addClass("global-drag")
            return false            

        _on_mousemove: (event) ->
            if @dragging
                new_pos = 
                    x: event.pageX
                    y: event.pageY
                x_offset = new_pos.x - @dragging.x
                y_offset = new_pos.y - @dragging.y
                @model.nodes.forEach (node) ->
                    node.positioner(
                        node.get("x") + x_offset,
                        node.get("y") + y_offset)
                    return false
                @dragging = new_pos

        _on_mouseup: (event) ->
            @model.drop_start()
            @dragging = null
            @$el.removeClass("global-drag")

        _on_click: (event) ->
            if not event.ctrlKey
                for node in @model.get_selected()
                    node.deselect()
                return false

        render: (@callback) ->
            @$el
                .append(@selector.render().el)
                .disableSelection()
            nodes = new views.NodesView
                model: @model.nodes
                el: @el
            nodes.render()
            @$canvas = @$("canvas")
            @canvas = @$canvas[0]
            @context = @canvas.getContext("2d")
            $(window).resize(_.bind(@resize, this))
            @resize()
            @draw()

        resize: ->
            @canvas.width = @$el.innerWidth()
            @canvas.height = @$el.innerHeight()

        draw: ->
            requestAnimationFrame(_.bind(@draw, this))
            @callback?()
            @context.clearRect(0, 0, @$el.innerWidth(), @$el.innerHeight())
            #for gizmo in @model.gizmos
            #    gizmo.render(@context)

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

        old_pos: null
        dragged: null

        constructor: (options) ->
            super(options)
            @model.set_bounds(_.bind(@bounds, this))
            @model.set_positioner(_.bind(@positioner, this))
            @model.on('selected', @select, this)
            @model.on('deselected', @deselect, this)                
            @model.on('change:x', @_x_changed, this)
            @model.on('change:y', @_y_changed, this)

        events:
            "click"                         : "_on_click"
            "hover"                         : "_on_hover"
            "mousedown"                     : "_on_mousedown"
            "click .ui-widget-header"       : "_on_header_click"

        _on_click: (event) ->
            if event.ctrlKey
                if @model.get("selected")
                    @model.deselect()
                else
                    @model.select()
            else
                for node in @model.graph.get_selected()
                    node.deselect()
                @model.select()
            return false

        # Preventing click just before drag finished
        _on_header_click: (event) ->
            if @dragged
                @dragged = null
                event.stopPropagation()

        _on_hover: (event) ->
            @$el.toggleClass("ui-state-hover")

        # Preventing mousedown to be propagated to nodes holder
        _on_mousedown: (event) ->
            return true if event.shiftKey 
            event.stopPropagation()

        positioner: (x, y) ->
             @$el.css("left", x)
             @$el.css("top", y)
             @model.set("x", x, silent: true)
             @model.set("y", y, silent: true)

        _x_changed: (node, value) -> @$el.css("left", value)
        _y_changed: (node, value) -> @$el.css("top", value)

        select: () ->
            @$el.addClass("node-selected")

        deselect: () ->
            @$el.removeClass("node-selected")

        render: () ->
            left = new views.LeftConnectorsView(model: @model.left)
            right = new views.RightConnectorsView(model: @model.right)
            @header = @make("div", { class: "ui-widget-header ui-corner-top" }, @model.title)
            @$el
                .draggable
                    handle: ".ui-widget-header"
                    scroll: false
                    stack: ".node"
                    start: (event, ui) =>
                        return false if event.shiftKey 
                        return false if not @model.get("selected")
                        $(@header).addClass("ui-state-active")
                        @old_pos = 
                            x: @el.offsetLeft
                            y: @el.offsetTop
                        @dragged = true
                    drag: (event, ui) =>
                        new_pos = 
                            x: @el.offsetLeft
                            y: @el.offsetTop
                        x_offset = new_pos.x - @old_pos.x
                        y_offset = new_pos.y - @old_pos.y
                        for node in @model.graph.selection when node isnt @model
                            node.positioner(
                                node.get("x") + x_offset,
                                node.get("y") + y_offset)
                        @old_pos = new_pos
                        @model.set("x", @old_pos.x, silent: true)
                        @model.set("y", @old_pos.y, silent: true)
                    stop: (event, ui) =>
                        @old_pos = null
                        $(@header).removeClass("ui-state-active")

                .css("left", @model.get("x"))
                .css("top", @model.get("y"))
                .css("position", "absolute")
                .append(@header)
                .append(left.render().el)
                .append(right.render().el)
                .disableSelection()
            return this

        create_constrols: () ->
            container = @make "div", 
                class: "controls-container"
            return container

        bounds: () ->
            x0 = @el.offsetLeft
            y0 = @el.offsetTop
            x1 = x0 + @el.offsetWidth
            y1 = y0 + @el.offsetHeight
            return new math.Rect(x0, y0, x1, y1)

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
            @model.set_position(_.bind(@pos, this))

        events:
            "mousedown"         : "_on_mousedown"
            "mouseup"           : "_on_mouseup"
            "hover"             : "_on_hover"

        _on_mousedown: (event) ->
            return true if event.shiftKey 
            @model.node.graph?.pick_start(@model)
            return false

        _on_mouseup: (event) ->
            @model.node.graph?.pick_end(@model)
            return false

        _on_hover: (event) ->
            @$el
                .toggleClass("ui-state-highlight")
                .toggleClass("ui-state-default")

        render: () ->
            @$el.text(@model.get("title"))
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
