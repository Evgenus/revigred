define [
    'Backbone.Model'
,   'Backbone.Collection'
], -> 
    models = namespace "revigred.models"
    collections = namespace "revigred.collections"
    gizmos = namespace "revigred.gizmos"
    views = namespace "revigred.views"

    class models.GraphModel extends Backbone.Model
        constructor: (options) ->
            super(options)
            @nodes = new collections.NodesList()
            @edges = []
            @cursor_object = null
            @selection = []

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

        pick_start: (view) ->
            @cursor_object = view

        pick_end: (view) ->
            if @cursor_object?
                if isinstance(@cursor_object, models.ConnectorModel)
                    if @cursor_object is view
                        @drop_start(view)
                    else
                        gizmo = new gizmos.EdgeGizmo(view, @cursor_object)
                        @edges.push()
                        @cursor_object = null

        drop_start: (view) ->
            @cursor_object = null

        get_selected: () -> _.clone(@selection)

        _add_selected: (node) ->
            index = @selection.indexOf(node)
            @selection.push(node) if index < 0

        _remove_selected: (node) ->
            index = @selection.indexOf(node)
            @selection.splice(index, 1) if index >= 0

    class models.NodeModel extends Backbone.Model
        defaults:
            id: null
            x: 0
            y: 0
            selected: false

        validation:
            id: (value, attr, computedState) ->
                return 'Name is invalid' if not value?

        title: ""

        constructor: (options) ->
            super(options)
            @set("id", uuid.v4()) if not options.id?
            @left = new collections.LeftConnectorsList()
            @right = new collections.RightConnectorsList()
            @on "change:selected", @_apply_selection

        set_graph: (@graph) ->

        set_bounds: (@bounds) ->

        set_positioner: (@positioner) ->

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

        # Selection dispatcher. Don't use iе directly
        _apply_selection: (obj, value, changes) ->
            if value
                obj.graph._add_selected(obj)
                obj.trigger("selected")
            else
                obj.graph._remove_selected(obj)
                obj.trigger("deselected")

        # Invoke that to make node selected
        select: () ->
            @set("selected", true)

        # Invoke that to make node not selected
        deselect: () ->
            @set("selected", false)

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

define [
    'revigred.models.NodeModel'
,   'revigred.models.LeftConnectorModel'
,   'revigred.models.RightConnectorModel'
], -> 
    coll = namespace "revigred.collections"
    models = namespace "revigred.models"

    class coll.NodesList extends Backbone.Collection
        model: models.NodeModel
    class coll.ConnectorsList extends Backbone.Collection
    class coll.LeftConnectorsList extends coll.ConnectorsList
        model: models.LeftConnectorModel
    class coll.RightConnectorsList extends coll.ConnectorsList
        model: models.RightConnectorModel
