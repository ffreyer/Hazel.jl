# Application

The Application is outermost structure, resembling the program as a whole. The current state is very much temporary.

#### Application.jl

An `Application` implements

* `renderloop(app)`: The main loop which renders teh application.
* `run(app)`: Calls `init!(app)` and starts `renderloop(app)` asynchronosly.
* `destroy(app)`: Stops the renderloop. (TODO: Actually destroy the application and all of its contents)
* `handle!(app, event)`: Distributes events to the window and every layer in reverse order. (Layers should be in render-order, i.e. the last layer is always visible.) See also: [Events](@ref), [Layers](@ref)
* `push!(app, layer)`, `push_overlay!(app, layer)`, `pop!(app, layer)`, `pop_overlay!(app, layer)`: See [Layers](@ref)
* `window(app)`: Returns the active window of the application. See also [Window](@ref)

#### Inputs.jl

Currently implements some methods for retrieving input events, i.e.

* `keypressed(app, keycode)`
* `mousebutton_pressed(app, button)`
* `mouse_x(app)`
* `mouse_y(app)`
* `mouse_pos(app)`

See also: [Window](@ref)
