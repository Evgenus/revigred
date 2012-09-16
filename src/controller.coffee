define "revigred.controller", [
], -> 
	views = namespace "revigred.views"

	class Controller
		constructor: ->
			@_node_views = {}

		get_node_view: (node) ->
			@_node_views[node.id] ?= new views.NodeView 
				model: node

	@instance = new Controller