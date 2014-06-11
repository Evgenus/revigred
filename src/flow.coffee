define [
    "revigred.models.NodeModel"
,   "revigred.models.GraphModel"
],
-> 
    models = namespace 'revigred.models'
    flow = namespace 'revigred.flow'

    class flow.FlowNode extends models.NodeModel
        constructor: (options) ->
            super(options)
            @set("title", @title) if @title?
            for name of @inputs
                data = 
                    name: name
                    title: name
                _.extend(data, @inputs[name])
                @add(new models.InputConnectorModel(data))

            for name of @outputs
                data = 
                    name: name
                    title: name
                _.extend(data, @outputs[name])
                @add(new models.OutputConnectorModel(data))

    class flow.Tlke extends flow.FlowNode
        title: "TLKE"

        inputs:
            generate: {}
            enterOffer: {}
            enterAuth: {}
            processPacket: {}

        outputs:
            offer: {}
            auth: {}
            addr: {}
            packet: {}
            keyReady: {}

    class flow.Route extends flow.FlowNode
        title: "Route"

        inputs:
            setAddr: {}
            processPacket: {}
            processNetworkPacket: {}

        outputs:
            packet: {}
            networkPacket: {}

    class flow.Transport extends flow.FlowNode
        title: "Transport"
        inputs:
            openAddr: {}
            sendNetworkPacket: {}

        outputs:
            networkPacket: {}
