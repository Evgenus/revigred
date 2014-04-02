define "revigred.controller", [
], -> 
    views = namespace "revigred.views"
    models = namespace "revigred.models"
    controller = namespace "revigred.controller"

    class controller.Controller
        constructor: (options) ->
            @_node_views = {}
            @_connector_views = {}
            @graph = options.graph

        get_node_view: (node) ->
            @_node_views[node.id] ?= new views.NodeView 
                model: node

    return