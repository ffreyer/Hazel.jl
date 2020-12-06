mutable struct ImGuiLayer <: AbstractLayer
    context::Ptr{CImGui.ImGuiContext}
    consume_events::Bool
    glfw_window::GLFW.Window
    ImGuiLayer() = new(C_NULL, true)
end


# Interface
function attach(l::ImGuiLayer, app::AbstractApplication)
    l.context = CImGui.CreateContext()
    CImGui.StyleColorsDark()
    glfw_window = native_window(window(app))
    l.glfw_window = glfw_window
    # false because WE give ImGui inputs
    CImGui.GLFWBackend.ImGui_ImplGlfw_InitForOpenGL(glfw_window, false)
    CImGui.OpenGLBackend.ImGui_ImplOpenGL3_Init(410)
    GLFW.SetCharCallback(glfw_window, CImGui.GLFWBackend.ImGui_ImplGlfw_CharCallback)

    nothing
end

function detach(l::ImGuiLayer, app::AbstractApplication)
    CImGui.OpenGLBackend.ImGui_ImplOpenGL3_Shutdown()
    CImGui.GLFWBackend.ImGui_ImplGlfw_Shutdown()
    CImGui.DestroyContext(l.context)
    nothing
end

@HZ_profile function Begin(l::ImGuiLayer)
    @HZ_profile "OGL" begin CImGui.OpenGLBackend.ImGui_ImplOpenGL3_NewFrame() end
    @HZ_profile "GLFW" begin CImGui.GLFWBackend.ImGui_ImplGlfw_NewFrame() end
    @HZ_profile "Frame" begin CImGui.NewFrame() end
    nothing
end

@HZ_profile update!(app, l::ImGuiLayer, other, ts) = nothing
@HZ_profile function update!(app, l::ImGuiLayer, other::ImGuiLayer, ts)
    True = true
    CImGui.@c CImGui.ShowDemoWindow(&True)
    nothing
end

@HZ_profile function End(l::ImGuiLayer)
    CImGui.Render()
    CImGui.OpenGLBackend.ImGui_ImplOpenGL3_RenderDrawData(CImGui.GetDrawData())
    nothing
end


# ?CImGui.IsWindowHovered # says
# You should always pass your mouse/keyboard inputs to imgui
@HZ_profile function handle!(l::ImGuiLayer, e::KeyPressedEvent{key}) where {key}
    CImGui.GLFWBackend.ImGui_ImplGlfw_KeyCallback(
        l.glfw_window,
        GLFW.Key(Cint(key)), e.scancode,
        e.repeat_count == 0 ? GLFW.PRESS : GLFW.REPEAT, e.mods
    )
    l.consume_events && CImGui.Get_WantCaptureKeyboard(CImGui.GetIO())
end
@HZ_profile function handle!(l::ImGuiLayer, e::KeyReleasedEvent{key}) where {key}
    CImGui.GLFWBackend.ImGui_ImplGlfw_KeyCallback(
        l.glfw_window, GLFW.Key(Cint(key)), e.scancode, GLFW.RELEASE, e.mods
    )
    l.consume_events && CImGui.Get_WantCaptureKeyboard(CImGui.GetIO())
end
@HZ_profile function handle!(l::ImGuiLayer, e::MouseButtonPressedEvent{button}) where {button}
    CImGui.GLFWBackend.ImGui_ImplGlfw_MouseButtonCallback(
        l.glfw_window, GLFW.MouseButton(Cint(button)), GLFW.PRESS, e.mods
    )
    l.consume_events && CImGui.Get_WantCaptureMouse(CImGui.GetIO())
end
@HZ_profile function handle!(l::ImGuiLayer, e::MouseButtonReleasedEvent{button}) where {button}
    CImGui.GLFWBackend.ImGui_ImplGlfw_MouseButtonCallback(
        l.glfw_window, GLFW.MouseButton(Cint(button)), GLFW.RELEASE, e.mods
    )
    l.consume_events && CImGui.Get_WantCaptureMouse(CImGui.GetIO())
end
@HZ_profile function handle!(l::ImGuiLayer, e::MouseScrolledEvent)
    CImGui.GLFWBackend.ImGui_ImplGlfw_ScrollCallback(l.glfw_window, e.dx, e.dy)
    l.consume_events && CImGui.Get_WantCaptureMouse(CImGui.GetIO())
end

Base.string(l::ImGuiLayer) = "ImGuiLayer" # for debug
