define [
    'Backbone.Model'
], -> 
    models = namespace "revigred.models"
    collections = namespace "revigred.collections"
    gizmos = namespace "revigred.gizmos"

    delay = (time, callback) ->
        window.setTimeout(callback, time)

    class models.EchoChannel
        constructor: (@model) ->
            @id = "channel-" + uuid.v4()
            @model.on "createNode", (node) =>
                @createNode(node.id)

        onNodeCreated: (channelId, nodeId) ->
            console.log("onNodeCreated", channelId, nodeId)
            if channelId == @id
                node = @model.get_node(nodeId)
            else
                node = new models.NodeModel
                    id: nodeId
                @model.add(node)
            if node?
                node.set("local", false)
                node.on "change", (node) =>
                    @changeState(node.id, node.changedAttributes())
            return

        # onNodeRemoved: (channelId, nodeId) ->
        #     @model.get_node(nodeId).destroy()
        #     return

        onNodeStateChanged: (channelId, nodeId, nodeState) ->
            console.log("onNodeStateChanged", channelId, nodeId, nodeState)
            if channelId == @id
                # aprove changeset
            else
                node = @model.get_node(nodeId)
            node?.set(nodeState)

        onLinkAdded: (nodeId1, portId1, nodeId2, portId2) ->
            node1 = @model.get_node(nodeId1)
            port1 = node1?.get_connector(portId1)
            node2 = @model.get_node(nodeId2)
            port2 = node2?.get_connector(portId2)
            if port1? and port2?
                @model.connect(port1, port2)
            return

        # onLinkRemoved: (nodeId1, portId1, nodeId2, portId2) ->
        #     node1 = @model.get_node(nodeId1)
        #     port1 = node1?.get_connector(portId1)
        #     node2 = @model.get_node(nodeId2)
        #     port2 = node2?.get_connector(portId2)
        #     if port1? and port2?
        #         @model.disconnect(port1, port2)

        onPortsChanged: (channelId, nodeId, inputs, outputs) ->
            console.log("onPortsChanged", channelId, nodeId, inputs, outputs)

            node = @model.get_node(nodeId)

            if node?
                joined = []
                for input in inputs
                    connector = new models.InputConnectorModel(input)
                    joined.push(connector)
                    connector.set_node(node)

                for output in outputs
                    connector = new models.OutputConnectorModel(output)
                    joined.push(connector)
                    connector.set_node(node)

                node.connectors.set(joined)
                console.log(node.connectors.toArray())

            return

        createNode: (modelNodeId) ->
            delay 1000, => 
                @onNodeCreated(@id, modelNodeId)
            return

        # removeNode: (modelNodeId) ->
        #     delay 0, => 
        #         @onNodeRemoved(modelNodeId)
        #     return

        changeState: (modelNodeId, nodeState) ->
            delay 1000, => 
                @onNodeStateChanged(@id, modelNodeId, nodeState)
            return

        # addLink: (nodeId1, portId1, nodeId2, portId2) ->
        #     delay 0, => 
        #         @onLinkAdded(nodeId1, portId1, nodeId2, portId2)
        #     return

        # removeLink: (nodeId1, portId1, nodeId2, portId2) ->
        #     delay 0, => 
        #         @onLinkRemoved(nodeId1, portId1, nodeId2, portId2)
        #     return

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
                    node.on("select", @select, this)
                    node.on("deselect", @deselect, this)
                    node.set_graph(this)
            return this

        get_node: (id) ->
            return @nodes.get(id)

        pick_start: (@start_connector) ->
            return

        pick_end: (end_connector) ->
            if @start_connector?
                if @start_connector isnt end_connector
                    @connect(@start_connector, end_connector)
                @drop_start()
            return

        drop_start: () ->
            @start_connector = null

        connect: (connector1, connector2) ->
            connector = @connections.findWhere
                start: connector1
                end: connector2
            return if connector?
            connection = new models.ConnectionModel
                start: connector1
                end: connector2
            @connections.push(connection)
            return

        disconnect: (connector1, connector2) ->
            connector = @connections.findWhere
                start: connection.connector1
                end: connection.connector2
            connector?.destroy()
            return

        select: (node) -> @nodes?.selection?.add(node)
        deselect: (node) -> @nodes?.selection?.remove(node)
        deselect_all: () -> @nodes?.selection?.deselect_all()

        create_node: () ->
            node = new models.NodeModel()
            @add(node)
            @trigger("createNode", node)
            return node

    class models.NodeModel extends Backbone.Model
        defaults:
            id: null
            x: 100
            y: 100
            title: "NodeModel"
            local: true
            selected: false

        validation:
            id: (value, attr, computedState) ->
                return 'Name is invalid' if not value?

        constructor: (options) ->
            super(options)
            @set("id", uuid.v4()) if not options?.id?

            @connectors = new collections.ConnectorsList()

        get_connector: (name) ->
            return @connectors.find (connector) => connector.name == name

        set_graph: (@graph) ->
        set_bounds: (@bounds) ->

        add: (connectors...) ->
            for connector in connectors
                if isinstance(connector, models.ConnectorModel)
                    connector.set_node(this)
                    @connectors.push(connector)
                else
                    throw "Invalid type"
            return this

        highlight: (type) -> @trigger("highlight", type)
        select: -> @trigger("select", this)
        deselect: -> @trigger("deselect", this)

        moveBy: (dx, dy) ->
            @set
                x: @attributes.x + dx
                y: @attributes.y + dy

        destroy: ->
            @trigger('destroy', this, @collection)
            @connectors.destroy()
            delete @graph
            delete @bounds

    class models.ConnectorModel extends Backbone.Model
        defaults:
            name: ""
            title: ""

        @property "key",
            get: -> @node.id + "|" + @get("name")

        set_node: (@node)->
            @node.on("selected", @_on_select, this)
            @node.on("deselected", @_on_deselect, this)

        _on_select: -> @trigger("select")
        _on_deselect: -> @trigger("deselect")

        set_position: (@pos) ->

        destroy: ->
            @trigger('destroy', this, @collection)
            delete @node
            delete @pos

    class models.InputConnectorModel extends models.ConnectorModel
    class models.OutputConnectorModel extends models.ConnectorModel

    class models.ConnectionModel extends Backbone.Model
        default:
            start: null
            end: null

        constructor: (options) ->
            super(options)
            start = @get("start")
            end = @get("end")
            start.on("destroy", @destroy, this)
            end.on("destroy", @destroy, this)

define "revigred.collections", [
    'Backbone.Collection'
,   'revigred.models.NodeModel'
], -> 
    models = namespace "revigred.models"
    collections = namespace "revigred.collections"

    class @NodesList extends Backbone.Collection
        model: models.NodeModel

        constructor: (options) ->
            super(options)
            @selection = new collections.Selection()
            @selection?.on("remove", @_on_restore, this)

        _on_restore: (node, collection) -> @trigger("restore", node)

        set_dragging_callback: (callback) ->
            @selection?.set_dragging_callback(callback)

        drag: (dx, dy) ->
            @toArray().forEach (node) -> 
                node.moveBy(dx, dy)
                false
            @selection?.notify_dragging()

    class @ConnectorsList extends Backbone.Collection
        destroy: ->
            @toArray().forEach (conn) ->
                conn.destroy()
            @trigger('destroy', this, @collection)

    class @Selection extends Backbone.Collection
        model: models.NodeModel

        constructor: (options) ->
            super(options)

        add: (node) ->
            super(node)
            node.set("selected", true)
        
        remove: (node) -> 
            super(node)
            node.set("selected", false)

        deselect_all: -> 
            _.forEach @toArray(), (node) => @remove(node)

        set_dragging_callback: (callback) ->
            @dragging_callback = callback

        notify_dragging: ->
            if @dragging_callback?
                @dragging_callback()
                delete @dragging_callback

        drag: (dx, dy) ->
            @toArray().forEach (node) -> 
                node.moveBy(dx, dy)
                false
            @notify_dragging()

        delete_selected: ->
            @toArray().forEach (node) -> 
                node.deselect()
                node.destroy()

    class @ConnectionsList extends Backbone.Collection
        models.ConnectionModel
