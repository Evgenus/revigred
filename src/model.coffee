define [
  'use!Underscore', 
  'use!Backbone',
], (_, Backbone) ->

    class revirged.GraphModel extends Backbone.Model
        constructor: (options) ->
            super(options)
            @nodes = new NodesList()
            @gizmos = []
            @cursor_object = null

        add: (nodes...) ->
            for node in nodes
                if not isinstance(node, NodeModel, Gizmo)
                    throw new Error("Invalid type")
            for node in nodes
                if isinstance(node, NodeModel)
                    @nodes.push(node)
                    node.set_graph(this)
                else if isinstance(node, Gizmo)
                    @gizmos.push(node)
            return this

        pick_start: (view) ->
            @cursor_object = view

        pick_end: (view) ->
            if isinstance(@cursor_object, ConnectorView)
                if @cursor_object is view
                    @drop_start(view)
                else
                    @gizmos.push(new EdgeGizmo(view, @cursor_object))
                    @cursor_object = null

        drop_start: (view) ->
            @cursor_object = null

    class revirged.NodeModel extends Backbone.Model
        defaults:
            title: ""

        constructor: (options) ->
            super(options)
            @left = new LeftConnectorsList()
            @right = new RightConnectorsList()

        set_graph: (@graph) ->

        set_bounds: (@bounds) ->

        add: (connectors...) ->
            for connector in connectors
                if not isinstance(connector, ConnectorModel)
                    throw new Error("Invalid type")
            for connector in connectors
                if isinstance(connector, LeftConnectorModel)
                    @left.push(connector)
                else if isinstance(connector, RightConnectorModel)
                    @right.push(connector)
                connector.set_node(this)
            return this

    class revirged.NodesList extends Backbone.Collection

    class revirged.ConnectorModel extends Backbone.Model
        defaults:
            name: ""
            title: ""

        set_node: (@node)->

    class revirged.LeftConnectorModel extends revirged.ConnectorModel

    class revirged.RightConnectorModel extends revirged.ConnectorModel

    class revirged.ConnectorsList extends Backbone.Collection

    class revirged.LeftConnectorsList extends revirged.ConnectorsList
        model: revirged.LeftConnectorModel

    class revirged.RightConnectorsList extends revirged.ConnectorsList
        model: revirged.RightConnectorModel