define [
    'Backbone.Model'
,   'Backbone.Collection'
], -> 
    root = namespace "revigred.models"
    collections = namespace "revigred.collections"
    gizmos = namespace "revigred.gizmos"
    views = namespace "revigred.views"

    class root.GraphModel extends Backbone.Model
        constructor: (options) ->
            super(options)
            @nodes = new collections.NodesList()
            @gizmos = []
            @cursor_object = null

        add: (nodes...) ->
            for node in nodes
                if not isinstance(node, root.NodeModel, gizmos.Gizmo)
                    throw "Invalid type"
            for node in nodes
                if isinstance(node, root.NodeModel)
                    @nodes.push(node)
                    node.set_graph(this)
                else if isinstance(node, gizmos.Gizmo)
                    @gizmos.push(node)
            return this

        pick_start: (view) ->
            @cursor_object = view

        pick_end: (view) ->
            if isinstance(@cursor_object, views.ConnectorView)
                if @cursor_object is view
                    @drop_start(view)
                else
                    @gizmos.push(new gizmos.EdgeGizmo(view, @cursor_object))
                    @cursor_object = null

        drop_start: (view) ->
            @cursor_object = null

    class root.NodeModel extends Backbone.Model
        defaults:
            title: ""

        constructor: (options) ->
            super(options)
            @left = new collections.LeftConnectorsList()
            @right = new collections.RightConnectorsList()

        set_graph: (@graph) ->

        set_bounds: (@bounds) ->

        add: (connectors...) ->
            for connector in connectors
                if not isinstance(connector, root.ConnectorModel)
                    throw "Invalid type"
            for connector in connectors
                if isinstance(connector, root.LeftConnectorModel)
                    @left.push(connector)
                else if isinstance(connector, root.RightConnectorModel)
                    @right.push(connector)
                connector.set_node(this)
            return this

    class root.ConnectorModel extends Backbone.Model
        defaults:
            name: ""
            title: ""

        set_node: (@node)->

    class root.LeftConnectorModel extends root.ConnectorModel
    class root.RightConnectorModel extends root.ConnectorModel

define [
    'revigred.models.LeftConnectorModel'
,   'revigred.models.RightConnectorModel'
], -> 
    root = namespace "revigred.collections"
    models = namespace "revigred.models"

    class root.NodesList extends Backbone.Collection
        model: models.NodeModel
    class root.ConnectorsList extends Backbone.Collection
    class root.LeftConnectorsList extends root.ConnectorsList
        model: models.LeftConnectorModel
    class root.RightConnectorsList extends root.ConnectorsList
        model: models.RightConnectorModel
