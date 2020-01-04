function keypressed(window::GLFWWindow, keycode)
    GLFW.GetKey(native_window(window), keycode) in (GLFW.PRESS, GLFW.REPEAT)
end

function mousebutton_pressed(window::GLFWWindow, button)
    glfw_window = native_window(window)
    GLFW.GetMouseButton(glfw_window, button) == GLFW.PRESS
end

mouse_x(window::GLFWWindow) = mouse_pos(window)[1]
mouse_y(window::GLFWWindow) = mouse_pos(window)[2]
mouse_pos(window::GLFWWindow) = GLFW.GetCursorPos(native_window(window))
