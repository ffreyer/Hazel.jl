keypressed(app::AbstractApplication, keycode) = keypressed(window(app), keycode)
function mousebutton_pressed(app::AbstractApplication, button)
    mousebutton_pressed(window(app), button)
end

mouse_x(app::AbstractApplication) = mouse_pos(window(app))[1]
mouse_y(app::AbstractApplication) = mouse_pos(window(app))[2]
function mouse_pos(app::AbstractApplication)
    x, y = mouse_pos(window(app))
    Vec2f0(x, y)
end