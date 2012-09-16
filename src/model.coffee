define [
    'Backbone.Model'
,   "revigred.controller"
], -> 
    models = namespace "revigred.models"
    collections = namespace "revigred.collections"
    gizmos = namespace "revigred.gizmos"

    class models.GraphModel extends Backbone.Model
        constructor: (options) ->
            super(options)
            @nodes = new collections.NodesList()
            @connections = new collections.ConnectionsList()

        add: (nodes...) ->
            for node in nodes
                if not isinstance(node, models.NodeModel, gizmos.Gizmo)
                    throw "Invalid type"
            for node in nodes
                if isinstance(node, models.NodeModel)
                    @nodes.push(node)
                    node.set_graph(this)
                else if isinstance(node, gizmos.Gizmo)
                    @gizmos.push(node)
            return this

        pick_start: (@start_connector) ->

        pick_end: (end_connector) ->
            if @start_connector?
                if @start_connector isnt end_connector
                    connection = @make_connection(@start_connector, end_connector)
                    @connections.push(connection)
                @drop_start()

        drop_start: () ->
            @start_connector = null

        make_connection: (connector1, connector2) ->
            new models.ConnectionModel
                start: connector1
                end: connector2

        select: (node) -> node.set("selected", true)
        deselect: (node) -> node.set("selected", false)
        deselect_all: () -> @nodes?.selection?.deselect_all()

        _on_select_node: (node) ->
            @nodes?.selection?.add(node)

        _on_deselect_node: (node) ->
            @nodes?.selection?.remove(node)

    class models.NodeModel extends Backbone.Model
        title: ""

        defaults:
            id: null
            x: 0
            y: 0
            selected: false

        validation:
            id: (value, attr, computedState) ->
                return 'Name is invalid' if not value?

        constructor: (options) ->
            super(options)
            @set("id", uuid.v4()) if not options.id?
            @left = new collections.LeftConnectorsList()
            @right = new collections.RightConnectorsList()
            @on("change:selected", @_on_selection, this)

        set_graph: (@graph) ->
        set_bounds: (@bounds) ->

        add: (connectors...) ->
            for connector in connectors
                if not isinstance(connector, models.ConnectorModel)
                    throw "Invalid type"
            for connector in connectors
                if isinstance(connector, models.LeftConnectorModel)
                    @left.push(connector)
                else if isinstance(connector, models.RightConnectorModel)
                    @right.push(connector)
                connector.set_node(this)
            return this

        highlight: (type) -> @trigger("highlight", type)
        select: -> @set("selected", true)
        deselect: -> @set("selected", false)

        moveBy: (dx, dy) ->
            @set("x", @attributes.x + dx)
            @set("y", @attributes.y + dy)

        _on_selection: (model, value, options) ->
            if value
                @trigger("selected")
                @graph._on_select_node(this)
            else
                @trigger("deselected")
                @graph._on_deselect_node(this)

        destroy: ->
            delete @graph
            delete @bounds
            @trigger('destroy', this, @collection)


    class models.ConnectorModel extends Backbone.Model
        defaults:
            name: ""
            title: ""

        set_node: (@node)->
        set_position: (@position) ->

    class models.LeftConnectorModel extends models.ConnectorModel
    class models.RightConnectorModel extends models.ConnectorModel

    class models.ConnectionModel extends Backbone.Model
        default:
            start: null
            end: null

define "revigred.collections", [
    'Backbone.Collection'
,   'revigred.models.NodeModel'
,   'revigred.models.LeftConnectorModel'
,   'revigred.models.RightConnectorModel'
], -> 
    models = namespace "revigred.models"
    collections = namespace "revigred.collections"

    class @NodesList extends Backbone.Collection
        model: models.NodeModel

        constructor: (options) ->
            super(options)
            @selection = new collections.Selection()
            @selection.on("remove", @_on_restore, this)

        _on_restore: (node, collection) -> @trigger("restore", node)

        set_dragging_callback: (callback) ->
            @selection.set_dragging_callback(callback)

        drag: (dx, dy) ->
            @forEach (node) -> 
                node.moveBy(dx, dy)
                false
            @selection.notify_dragging()

    class @ConnectorsList extends Backbone.Collection
    class @LeftConnectorsList extends @ConnectorsList
        model: models.LeftConnectorModel
    class @RightConnectorsList extends @ConnectorsList
        model: models.RightConnectorModel

    class @Selection extends Backbone.Collection
        model: models.NodeModel
        
        constructor: () ->
            super()

        deselect_all: -> 
            _.forEach(@toArray(), (node) -> node.deselect())

        set_dragging_callback: (callback) ->
            @dragging_callback = callback

        notify_dragging: ->
            if @dragging_callback?
                @dragging_callback()
                delete @dragging_callback

        drag: (dx, dy) ->
            @forEach (node) -> 
                node.moveBy(dx, dy)
                false
            @notify_dragging()

define "revigred.collections", [
    'revigred.models.ConnectionModel'
], -> 
    models = namespace "revigred.models"
    class @ConnectionsList extends Backbone.Collection
        models.ConnectionModel
