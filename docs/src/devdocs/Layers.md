# Layers

Layers fulfill a similar purpose as in image editing software such as photoshop. They act as seperate rendering targets, where the first layer is rendered first, then the second, etc. An example use would be rendering GUI elements. They should always be rendered on top of the world and thus in a different layer.

## Layers.jl

### Layer Interface

A concrete Layer should inherit from `AbstractLayer`.  There are a couple of interface functions that can be implemented.

```@meta
CurrentModule = Hazel
```

```@docs
attach
detach
update!(layer::AbstractLayer)
handle!(layer::AbstractLayer, event::AbstractEvent)
```

None of these function must be implemented. For example, one could define an event layer that simply catched and handles events. There'd be no need to implement `update!` in this case, as events are passed by `handle!`.


### Layerstacks


```@docs
AbstractLayerStack
```

Both Layerstacks also implement two iteration interfaces - one for normal iteration (`for layer in layerstack`) and one for reverse iteration (`for layer in reverse(layerstack)`).


## ImGuiLayer.jl

The `ImGuiLayer` is an `AbstractLayer` that implements [CImGui](https://github.com/Gnimuc/CImGui.jl) functionality.


See also: [Events](@ref)
