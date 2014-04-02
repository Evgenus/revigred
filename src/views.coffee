define [
    "Backbone.View"
],
-> 
    views = namespace "revigred.views"
    math = namespace "Math"
    settings = namespace "revigred.settings"
    gizmos = namespace "revigred.gizmos"
    controller = namespace "revigred.controller"
    models = namespace "revigred.models"

    class views.GraphView extends Backbone.View
        _dragging: false

        constructor: (options) ->
            super(options)

            @controller = new controller.Controller
                graph: this
            @nodes = new views.NodesView
                model: @model.nodes
                controller: @controller
            @connections = new views.ConnectionsView
                model: @model.connections
                controller: @controller

            @_benchmark_time = 0
            @_benchmark_count = 0

        render: (callback) ->
            $window = $(window)
                .on 'keydown.revigred', (event) => @$el.focus()
                .on 'keyup.revigred', (event) => @_on_keyup(event)
            @$nodes = @nodes.render().$el
            @$el
                .append(@$nodes)
                .disableSelection()
            $(window).resize => @resize()
            @resize()
            @_draw_wrapper(callback)

        resize: ->

        _draw_wrapper: (callback) ->
            start = Date.now()

            @draw(callback)
            requestAnimationFrame => @_draw_wrapper(callback)

            @_benchmark_time += Date.now() - start
            # @_benchmark_count++

            if @_benchmark_count >= 200
                console.log("
 canvas draw: #{@_benchmark_time / @_benchmark_count} ms,
 nodes: #{@model.nodes.length}
 connections: #{@model.connections.length}
                    ".trim())
                @_benchmark_time = 0
                @_benchmark_count = 0

        draw: (callback) ->
            callback?()

        _on_keyup: (event) ->
            switch event.which
                when 46 then @model.nodes.selection.delete_selected()
                when 27 then @model.nodes.selection.deselect_all()

    class views.GraphCanvasView extends views.GraphView
        events:
            "mousemove"                     : "_on_mousemove"
            "mouseup"                       : "_on_mouseup"

        render: (callback) ->
            @canvas = document.createElement("canvas")
            @$el
                .append(@canvas)
            @$canvas = $(@canvas)
            @context = @canvas.getContext("2d")
            super(callback)

        resize: ->
            @canvas.width = @$el.innerWidth()
            @canvas.height = @$el.innerHeight()
            @_offset = @$canvas.offset()
            @context.translate(-@_offset.left, -@_offset.top)

        _on_mousemove: (event) ->
            @cursor = new math.Vector(
                event.pageX,
                event.pageY)

        _on_mouseup: (event) ->
            @model.drop_start()

        draw: (callback) ->
            super(callback)
            @context.clearRect(@_offset.left, @_offset.top, @$el.innerWidth(), @$el.innerHeight())
            
            @connections.render_canvas(@context)

            if @model.start_connector?
                ctx = @context

                pos = @model.start_connector.pos().v1
                dir = new Math.Vector(pos.x - @cursor.x, pos.y - @cursor.y)
                    .normalize()

                ctx.beginPath()
                gizmos.EdgeGizmo.drawDir(ctx, @model.start_connector, @cursor)
                ctx.stroke()
                ctx.closePath()

                ctx.strokeStyle = "rgb(0,0,0)"
                ctx.beginPath()
                ctx.moveTo(@cursor.x, @cursor.y)
                ctx.lineTo(@cursor.x + dir.x * 10 - dir.y * 6, @cursor.y + dir.y * 10 + dir.x * 6)
                ctx.lineTo(@cursor.x + dir.x * 10 + dir.y * 6, @cursor.y + dir.y * 10 - dir.x * 6)
                ctx.lineTo(@cursor.x, @cursor.y)
                ctx.fill()
                ctx.closePath()

            # here I will skip some view to simplify code 
            @model.nodes.forEach (node) =>
                view = @controller.get_node_view(node)
                view.draw(this)
                null

    class views.NodesView extends Backbone.View
        tagName: 'div'
        className: 'nodes'

        constructor: (options) ->
            super(options)
            @controller = options.controller

            if @model.selection?
                @selection = new views.SelectionView
                    model: @model.selection
                    controller: @controller

            @model.on('add', @_add, this)
            @model.on('reset', @_reset, this)
            @model.on('restore', @_restore, this)

        _reset: ->
            @model.forEach(@_add, this)

        _add: (node) ->
            view = @controller.get_node_view(node)
            @$el.append(view.render().el)
            null

        _restore: (node) ->
            view = @controller.get_node_view(node)
            @$el.append(view.el)
            view.restore()

        _highlight: ->
            @_diff.unset.forEach (node) -> node.highlight(null)
            @_diff.remain.forEach (node) -> node.highlight("selected")
            @_diff.common.forEach (node) -> node.highlight("intersect")
            @_diff.added.forEach (node) -> node.highlight("added")
            @_diff.removed.forEach (node) -> node.highlight("removed")

        _cancel_highlight: ->
            @_diff.result.added.forEach (node) -> node.highlight(null)
            @_diff.result.unchanged.forEach (node) -> node.highlight("selected")
            @_diff.result.removed.forEach (node) -> node.highlight("selected")

        render: ->
            if @selection?
                @$el
                    .append(@selection.render().el)
                    .selector
                        distance: 3
                        start: (event, widget) =>
                            new_rule = settings.get_selection_rule(
                                widget.ctrlKey,
                                widget.shiftKey,
                                widget.altKey)
                            @_diff = new new_rule(@model.selection.models)
                            widget.say(@_diff.name)
                        update: (event, widget) =>
                            # Searching for nodes that intersects selection rect
                            # This could be optimized
                            _selected = @model.filter (node) -> 
                                widget.rect.intersect(node.bounds())
                            @_diff.update(_selected)
                            @_highlight()
                        switch: (event, widget) =>
                            new_rule = settings.get_selection_rule(
                                widget.ctrlKey,
                                widget.shiftKey, 
                                widget.altKey)
                            if new_rule?
                                current = @_diff.current
                                @_cancel_highlight() 
                                @_diff = new new_rule(@model.selection.models)
                                @_diff.update()
                                @_highlight()
                                @_diff.update(current)
                                @_highlight()
                                widget.say(@_diff.name)
                        stop: (event, widget) =>
                            @_diff.result.added.forEach (node) -> node.select()
                            @_diff.result.unchanged.forEach (node) -> node.highlight("selected")
                            @_diff.result.removed.forEach (node) -> node.deselect()
                            delete @_diff

            @$el
                .draggable
                    scroll: false
                    distance: 3
                    which: 3
                    stop: (event, ui) =>
                        @model.drag(@el.offsetLeft, @el.offsetTop)
                        @$el.css
                            left: 0
                            top:  0
                .css
                    position: "absolute"

            @_reset()
            return this

    class views.SelectionView extends Backbone.View
        tagName: 'div'
        className: 'selection'

        events:
            "click"                         : "_on_click"
            "mousedown"                     : "_on_mousedown"

        constructor: (options) ->
            super(options)
            @controller = options.controller
            @model.on('add', @_add, this)
            @model.on('remove', @_remove, this)
            @counter = 0
            @dragged = false

        _add: (node) ->
            view = @controller.get_node_view(node)
            @counter++
            @$el
                .show()
                .append view.$el.css("z-index", @counter)

        _remove: (node) ->
            @$el.hide() if @model.length == 0                

        render: ->
            @$el
                .draggable
                    handle: ".node"
                    scroll: false
                    distance: 3
                    stop: (event, ui) =>
                        @dragged = true
                        @model.drag(@el.offsetLeft, @el.offsetTop)
                        @$el.css
                            left: 0
                            top:  0
                .css
                    position: "absolute"
                .hide()
            return this

        _on_mousedown: (event) ->
            @dragged = false
            return true

        _on_click: (event) ->
            if @dragged
                @dragged = false
                event.stopPropagation()
            else
                if settings.is_select(event)
                    @model.deselect_all()
            return false


    class views.NodeView extends Backbone.View
        tagName: 'div'
        className: 'node ui-widget ui-widget-content ui-corner-all'

        constructor: (options) ->
            super(options)

            @left = new views.LeftConnectorsView
                model: @model.connectors
            @right = new views.RightConnectorsView
                model: @model.connectors

            @model.set_bounds => @bounds()
            @model.on('highlight', @_apply_highlight, this)
            @model.on('change:x', @_x_changed, this)
            @model.on('change:y', @_y_changed, this)
            @model.on('change:title', @_title_changed, this)
            @model.on('change:selected', @_selected_changed, this)
            @model.on('change:local', @_local_changed, this)
            @model.on("remove", @remove, this)
            @dragged = false

        events:
            "click"                         : "_on_click"
            "mousedown"                     : "_on_mousedown"
            "mouseenter"                    : "_on_mouse_enter"
            "mouseleave"                    : "_on_mouse_leave"

        _on_click: (event) ->
            if @dragged
                @dragged = false
                event.stopPropagation()
            else
                if settings.is_select(event)
                    @model.graph.deselect_all()
                    @model.select()
                if settings.is_join_select(event)
                    if @model.get("selected")
                        @model.deselect()
                    else
                        @model.select()
            return false

        _on_mouse_enter: (event) ->
            @$el.addClass("ui-state-hover")

        _on_mouse_leave: (event) ->
            @$el.removeClass("ui-state-hover")

        _on_dragged: ->
            @dragged = true

        _on_mousedown: (event) ->
            @dragged = false
            @model.graph.nodes.set_dragging_callback => @_on_dragged()

        _local_changed: (node, value) -> 
            if value
                @$el.addClass("local-node")
            else
                @$el.removeClass("local-node")

        _x_changed: (node, value) -> @$el.css(left: value)
        _y_changed: (node, value) -> @$el.css(top: value)
        _title_changed: (node, value) -> @$header.text(value)

        _apply_highlight: (highlight) ->
            if @highlight != highlight
                @$el.removeClass("node-highlight-" + @highlight) if @highlight?
                @highlight = highlight
                @$el.addClass("node-highlight-" + @highlight) if @highlight?

        _selected_changed: (node, value) ->
            if value 
                @_apply_highlight("selected")
            else
                @_apply_highlight(null)

        restore: ->
            @delegateEvents()
            @left.restore()
            @right.restore()

        draw: (graph) ->
            @left.draw(graph)
            @right.draw(graph)

        render: ->
            @$header = $("<div>")
                .addClass("ui-widget-header ui-corner-top")
                .text(@model.get("title"))

            @$el
                .css
                    left: @model.get("x")
                    top : @model.get("y")
                .attr("id", @model.id)
                .append(@$header)
                .append(@left.render().el)
                .append(@right.render().el)
                .disableSelection()

            
            @_local_changed(@model, @model.get("local"))

            return this

        bounds: ->
            pos = @$el.offset()
            left = pos.left
            top = pos.top
            width = @$el.outerWidth()
            height = @$el.outerHeight()
            return new math.Rect(left, top, left + width, top + height)

# ____________________________________________________________________________ #

    class views.ConnectorsView extends Backbone.View
        tagName: 'ui'

        constructor: (options) ->
            super(options)
            @connectors = []
            @model.on('add', @addOne, this)
            @model.on('reset', @addAll, this)

        addAll: ->
            @model.forEach(@addOne, this)

        addOne: (connector) ->
            view = @make_connector
                model: connector
            @connectors.push(view)
            @$el.append(view.render().el)

            removeOne = (item, collection) -> 
                return if collection != @model
                index = @connectors.indexOf(view)
                @connectors.splice(index, 1) if index >= 0
                item.off("remove", null, this)

            connector.on("remove", removeOne, this)
            return null

        restore: ->
            @delegateEvents()
            @connectors.forEach (conn) -> conn.restore()

        render: ->
            @addAll()
            return this

        draw: (graph) ->
            @connectors.forEach (conn) -> 
                conn.draw?(graph)
                return null

    class views.LeftConnectorsView extends views.ConnectorsView
        className: 'left-connectors'

        make_connector: (options) -> 
            new views.LeftConnectorView(options)

        addOne: (connector) ->
            return if !isinstance(connector, models.InputConnectorModel)
            super(connector)

    class views.RightConnectorsView extends views.ConnectorsView
        className: 'right-connectors'
        render: ->
            super()
            @$el.attr("dir", "rtl")
            return this

        make_connector: (options) -> 
            new views.RightConnectorView(options)

        addOne: (connector) ->
            return if !isinstance(connector, models.OutputConnectorModel)
            super(connector)

# ____________________________________________________________________________ #

    class views.ConnectorView extends Backbone.View
        tagName: 'li'
        className: 'connector ui-state-default'

        constructor: (options) ->
            super(options)
            @model.set_position => @_pos()
            @model.on("remove", @remove, this)

        events:
            "mousedown"         : "_on_mousedown"
            "mouseup"           : "_on_mouseup"

        _on_mousedown: (event) ->
            @model.node.graph?.pick_start(@model)
            return false

        _on_mouseup: (event) ->
            @model.node.graph?.pick_end(@model)
            return false

        restore: ->
            @delegateEvents()

        render: ->
            @$el.text(@model.get("title"))
            return this

    class views.LeftConnectorView extends views.ConnectorView
        className: 'connector ui-state-default ui-corner-left'

        _pos: ->
            pos = @$el.offset()
            x0 = pos.left
            x0 -= 5 if @connections > 0 
            y0 = pos.top + @$el.outerHeight() / 2
            x1 = x0 - 50
            y1 = y0
            return new math.Segment(
                new math.Vector(x0, y0), 
                new math.Vector(x1, y1))

        draw: (graph) ->
            if @connections > 0
                pos = @$el.offset()
                x = pos.left
                y = pos.top + @$el.outerHeight() / 2

                ctx = graph.context
                ctx.strokeStyle = "rgb(0,0,0)"
                ctx.beginPath()

                ctx.moveTo(x, y)
                ctx.lineTo(x - 10, y - 6)
                ctx.lineTo(x - 10, y + 6)
                ctx.lineTo(x, y)

                ctx.fill()

    class views.RightConnectorView extends views.ConnectorView
        className: 'connector ui-state-default ui-corner-right'

        _pos: ->
            pos = @$el.offset()
            x0 = pos.left + @$el.outerWidth()
            y0 = pos.top + @$el.outerHeight() / 2
            x1 = x0 + 50
            y1 = y0
            return new math.Segment(
                new math.Vector(x0, y0), 
                new math.Vector(x1, y1))

    class views.ConnectionsView extends Backbone.View
        constructor: (options) ->
            super(options)
            @model.on('add', @_add, this)
            @model.on('reset', @_reset, this)
            @connections = []

        _reset: ->
            @model.forEach(@_add, this)

        _add: (item) ->
            gizmo = new gizmos.EdgeGizmo(item.get("start"), item.get("end"))
            removeOne = (item, collection) -> 
                return if collection != @model
                index = @connections.indexOf(gizmo)
                @connections.splice(index, 1) if index >= 0
                item.off("remove", null, this)
            item.on("remove", removeOne, this)
            @connections.push(gizmo)

        render_canvas: (ctx) ->
            ctx.strokeStyle = "rgb(0,0,0)"
            ctx.lineWidth = 2
            ctx.beginPath()

            for conn in @connections
                conn.draw(ctx)

            ctx.stroke()
