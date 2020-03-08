abstract type AbstractLayer end

# Interface
"""
    attach(layer, app)

Attached the `layer` to the given `app`. This may include setup with the
native window or the Graphics backend.
"""
attach(l::AbstractLayer, app::AbstractApplication) = @debug "$l does not implement `on_attach`"
# NOTE Note every layer will need this

"""
    detach(layer, app)

Detaches the layer from the app.
"""
detach(l::AbstractLayer, app::AbstractApplication) = @debug "$l does not implement `on_detach`"
# NOTE Note every layer will need this


"""
    update!(layer, dt)

Update the `layer`. Typically this means rendering the layer, as this function
is called once per frame.

`dt` is the time difference since the last call to update in seconds. (I.e the
time to render one frame.)
"""
update!(l::AbstractLayer, dt) = @debug "$l does not implement `update!`"
# NOTE Note every layer will need this

"""
    handle!(layer, event)

Handles an event in the given layer. Should return `true` if the event has been
"consumed", i.e. if the event should not propagate to any more layers. Otherwise
it should return `false`.
"""
function handle!(l::AbstractLayer, event::AbstractEvent)
    @debug "$(name(l)) does not implement `handle!`"
    false
end
# NOTE Note every layer will need this

"""
    destroy(layer)

Destroy all rendering components a given `layer`.
"""
function destroy(l::AbstractLayer)
    @debug "destroy($(typeof(l))) not implemented"
    nothing
end
# NOTE Note every layer will need this



# TODO: Should we really have this?
Base.string(l::AbstractLayer) = "Unnamed Layer $(typeof(l).name)" # for debug



"""
A Layerstack is a collection of Layers. The collection is assumed to be
heterogeneous. Layers are split into two groups, normal layers or overlay
layers. An overlay layer always sits on top of the normal layers.

Two concrete LayerStacks are implementen:

#### MutableLayerStack

As the name suggests, this LayerStack is mutable. As such it implements `push!`,
`push_overlay!`, `pop!` and `pop_overlay`.

#### StaticLayerStack

This LayerStack is static, i.e. no Layers can be `push!`'ed or `pop!`'ed during
its lifetime. This may be beneficial for performance. You can still mutate your
layers if you so desire.

You can directly cast a `StaticLayerStack` into a `MutableLayerStack` and
vice-versa. Both LayerStacks implement iteration as well as `reverse!()`.
"""
abstract type AbstractLayerStack end


struct MutableLayerStack <: AbstractLayerStack
    # The type of a layer may vary, especially if it's implemented by the user
    # so this needs to be a Vector, to be mutable, and of AbstractLayer, so that
    # each layer can be a different type
    layers::Vector{AbstractLayer}
    overlayers::Vector{AbstractLayer}
end

# This is probably faster
# Even just using Floats, `reduce(+, tuple)` outperforms `reduce(+, vector)`
struct StaticLayerStack{T1 <: Tuple, T2 <: Tuple} <: AbstractLayerStack
    layers::T1
    overlayers::T2
end


function MutableLayerStack(;
        layers = AbstractLayer[],
        overlays = AbstractLayer[]
    )
    MutableLayerStack(layers, overlays)
end
function MutableLayerStack(ls::StaticLayerStack)
    MutableLayerStack([ls.layers...], [ls.overlays...])
end

Base.push!(ls::MutableLayerStack, l::AbstractLayer) = push!(ls.layers, l)
push_overlay!(ls::MutableLayerStack, l::AbstractLayer) = push!(ls.overlayers, l)
Base.pop!(ls::MutableLayerStack) = pop!(ls.layers)
pop_overlay!(ls::MutableLayerStack) = pop!(ls.overlayers)
function Base.empty!(ls::MutableLayerStack, app::AbstractApplication)
    for layer in ls
        detach(layer, app)
    end
    empty!(ls.layers)
    empty!(ls.overlayers)
    ls
end

function StaticLayerStack(;
        layers = AbstractLayer[],
        overlays = AbstractLayer[]
    )
    MutableLayerStack(Tuple(layers), Tuple(overlays))
end
function StaticLayerStack(ls::MutableLayerStack)
    StaticLayerStack(Tuple(ls.layers), Tuple(ls.overlays))
end


# Iterator stuffs - this is generic :)
Base.length(ls::AbstractLayerStack) = length(ls.layers) + length(ls.overlayers)
Base.size(ls::AbstractLayerStack) = (length(ls), )
Base.eltype(::Type{AbstractLayerStack}) = AbstractLayer
Base.first(ls::AbstractLayerStack) = first(ls.layers)
Base.last(ls::AbstractLayerStack) = last(ls.overlayers)

function Base.iterate(ls::AbstractLayerStack)
    if length(ls) == 0
        return nothing
    elseif length(ls.layers) != 0
        return (ls.layers[1], 1)
    else
        return (ls.overlayers[1], 1)
    end
end
function Base.iterate(ls::AbstractLayerStack, index)
    L = length(ls.layers)
    if index < L
        return (ls.layers[index+1], index+1)
    elseif index < length(ls)
        return (ls.overlayers[index - L + 1], index+1)
    else
        nothing
    end
end

function Base.iterate(rls::Iterators.Reverse{T}) where {T <: AbstractLayerStack}
    L = length(rls.itr)
    if L == 0
        return nothing
    elseif length(rls.itr.overlayers) == 0
        return (rls.itr.layers[end], L)
    else
        return (rls.itr.overlayers[end], L)
    end
end
function Base.iterate(rls::Iterators.Reverse{T}, index) where {T <: AbstractLayerStack}
    L = length(rls.itr.layers)
    if index > L+1
        return (rls.itr.overlayers[index - L - 1], index-1)
    elseif index > 1
        return (rls.itr.layers[index-1], index-1)
    else
        nothing
    end
end
