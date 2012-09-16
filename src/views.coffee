define [
    "Backbone.View"
],
-> 
    views = namespace "revigred.views"
    math = namespace "Math"
    settings = namespace "revigred.settings"
    Controller = revigred.controller.instance

    class views.GraphView extends Backbone.View
        _dragging: false

        constructor: (options) ->
            super(options)

            @nodes = new views.NodesView
                model: @model.nodes

        render: (@callback) ->
            @$nodes = @nodes.render().$el
            @$el
                # .append(@selector.render().el)
                .append(@$nodes)
                .disableSelection()
            @$canvas = @$("canvas")
            @canvas = @$canvas[0]
            @context = @canvas.getContext("experimental-webgl")
            $(window).resize(_.bind(@resize, this))
            @resize()
            @draw()

        resize: ->
            @canvas.width = @$el.innerWidth()
            @canvas.height = @$el.innerHeight()

        draw: ->
            requestAnimationFrame(_.bind(@draw, this))
            @callback?()
            #@context.clearRect(0, 0, @$el.innerWidth(), @$el.innerHeight())
            #for gizmo in @model.gizmos
            #    gizmo.render(@context)

    class views.NodesView extends Backbone.View
        tagName: 'div'
        className: 'nodes'

        constructor: (options) ->
            super(options)
            @selection = new views.SelectionView
                model: @model.selection

            @model.on('add', @_add, this)
            @model.on('reset', @_reset, this)
            @model.on('restore', @_restore, this)

        _reset: ->
            @model.forEach(@_add, this)

        _add: (node) ->
            view = Controller.get_node_view(node)
            @$el.append(view.render().el)

        _restore: (node) ->
            view = Controller.get_node_view(node)
            @$el.append(view.el)

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

                # .draggable
                #     scroll: false
                #     distance: 3
                #     stop: (event, ui) =>
                #         @model.drag(@el.offsetLeft, @el.offsetTop)
                #         @$el.css
                #             left: 0
                #             top:  0
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
            @model.on('add', @_add, this)
            @model.on('remove', @_remove, this)
            @counter = 0
            @dragged = false

        _add: (node) ->
            view = Controller.get_node_view(node)
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
        attributes:
            tabindex: 1

        constructor: (options) ->
            super(options)

            @left = new views.LeftConnectorsView(model: @model.left)
            @right = new views.RightConnectorsView(model: @model.right)

            @model.set_bounds(_.bind(@bounds, this)) #FIX THAT: Yohoho, shit
            @model.on('selected', @_on_select, this)
            @model.on('deselected', @_on_deselect, this)
            @model.on('destroy', @_on_destroy, this)
            @model.on('highlight', @_apply_highlight, this)
            @model.on('change:x', @_x_changed, this)
            @model.on('change:y', @_y_changed, this)
            @dragged = false

        events:
            "click"                         : "_on_click"
            #"hover"                         : "_on_hover"
            "mousedown"                     : "_on_mousedown"
            "keyup"                         : "_on_keyup"

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

        _on_hover: (event) ->
            @$el.toggleClass("ui-state-hover")

        _on_dragged: ->
            @dragged = true

        _on_mousedown: (event) ->
            @dragged = false
            @model.graph.nodes.set_dragging_callback(_.bind(@_on_dragged, this))

        _on_keyup: (event) ->
            @model.destroy() if event.which == 46

        _x_changed: (node, value) -> @$el.css(left: value)
        _y_changed: (node, value) -> @$el.css(top: value)

        _apply_highlight: (highlight) ->
            if @highlight != highlight
                @$el.removeClass("node-highlight-" + @highlight) if @highlight?
                @highlight = highlight
                @$el.addClass("node-highlight-" + @highlight) if @highlight?

        _on_select: ->
            @$el.focus()
            @_apply_highlight("selected")

        _on_deselect: ->
            @_apply_highlight(null)
            @$el.blur()

        _on_destroy: ->
            @$el.remove()

        render: ->
            @header = @make("div", { class: "ui-widget-header ui-corner-top" }, @model.title)
            @$el
                .css
                    left: @model.get("x")
                    top : @model.get("y")
                .append(@header)
                .append(@left.render().el)
                .append(@right.render().el)
                .disableSelection()
            return this

        bounds: ->
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

        addAll: ->
            @model.forEach(@addOne, this)

        render: ->
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
        render: ->
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

        # events:
        #     "mousedown"         : "_on_mousedown"
        #     "mouseup"           : "_on_mouseup"
        #     #"hover"             : "_on_hover"

        # _on_mousedown: (event) ->
        #     @model.node.graph?.pick_start(@model)
        #     return false

        # _on_mouseup: (event) ->
        #     @model.node.graph?.pick_end(@model)
        #     return false

        # _on_hover: (event) ->
        #     @$el
        #         .toggleClass("ui-state-highlight")
        #         .toggleClass("ui-state-default")

        render: ->
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
