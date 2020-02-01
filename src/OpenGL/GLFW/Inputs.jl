function keypressed(window::Window, keycode)
    GLFW.GetKey(native_window(window), keycode) in (GLFW.PRESS, GLFW.REPEAT)
end

function mousebutton_pressed(window::Window, button)
    glfw_window = native_window(window)
    GLFW.GetMouseButton(glfw_window, button) == GLFW.PRESS
end

mouse_x(window::Window) = mouse_pos(window)[1]
mouse_y(window::Window) = mouse_pos(window)[2]
mouse_pos(window::Window) = GLFW.GetCursorPos(native_window(window))
