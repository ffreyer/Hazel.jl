mutable struct ImGuiLayer <: AbstractLayer
    context::Ptr{CImGui.ImGuiContext}
    glfw_window::GLFW.Window
    ImGuiLayer() = new(C_NULL)
end


# Interface
function attach(l::ImGuiLayer, app::AbstractApplication)
    # CImGui.CHECK_VERSION
    l.context = CImGui.CreateContext()
    # TODO can we do this?
    # io = CImGui.GetIO()
    # io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;       // Enable Keyboard Controls
    # //io.ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad;      // Enable Gamepad Controls
    # io.ConfigFlags |= ImGuiConfigFlags_DockingEnable;           // Enable Docking
    # io.ConfigFlags |= ImGuiConfigFlags_ViewportsEnable;         // Enable Multi-Viewport / Platform Windows
    # //io.ConfigFlags |= ImGuiConfigFlags_ViewportsNoTaskBarIcons;
    # //io.ConfigFlags |= ImGuiConfigFlags_ViewportsNoMerge;
    CImGui.StyleColorsDark()
    # style = CImGui.GetStyle()
    glfw_window = native_window(window(app))
    l.glfw_window = glfw_window
    # false because WE give ImGui inputs
    CImGui.GLFWBackend.ImGui_ImplGlfw_InitForOpenGL(glfw_window, false)
    CImGui.OpenGLBackend.ImGui_ImplOpenGL3_Init(410)

    # :<
    GLFW.SetCharCallback(glfw_window, CImGui.GLFWBackend.ImGui_ImplGlfw_CharCallback)

    nothing
end

function detach(l::ImGuiLayer, app::AbstractApplication)
    CImGui.OpenGLBackend.ImGui_ImplOpenGL3_Shutdown()
    CImGui.GLFWBackend.ImGui_ImplGlfw_Shutdown()
    CImGui.DestroyContext(l.context)
    nothing
end

function Begin(l::ImGuiLayer)
    CImGui.OpenGLBackend.ImGui_ImplOpenGL3_NewFrame()
    CImGui.GLFWBackend.ImGui_ImplGlfw_NewFrame()
    CImGui.NewFrame()
    nothing
end

function render(l::ImGuiLayer)
    # CImGui.ShowDemoWindow(true)
    True = true
    CImGui.@c CImGui.ShowDemoWindow(&True)
    nothing
end

# function End(l::ImGuiLayer, app::AbstractApplication)
function End(l::ImGuiLayer)
    # io = CImGui.GetIO()
    # window = native_window(window(app))
    # io.DisplaySize = CImGui.ImVec2(window.properties.height)
    CImGui.Render()
    CImGui.OpenGLBackend.ImGui_ImplOpenGL3_RenderDrawData(CImGui.GetDrawData())
    nothing
end

@HZ_profile function update!(l::ImGuiLayer, dt)
    # @warn "Update ImGuiLayer"
    Begin(l)
    render(l)
    End(l)
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
    CImGui.Get_WantCaptureKeyboard(CImGui.GetIO())
end
@HZ_profile function handle!(l::ImGuiLayer, e::KeyReleasedEvent{key}) where {key}
    CImGui.GLFWBackend.ImGui_ImplGlfw_KeyCallback(
        l.glfw_window, GLFW.Key(Cint(key)), e.scancode, GLFW.RELEASE, e.mods
    )
    CImGui.Get_WantCaptureKeyboard(CImGui.GetIO())
end
@HZ_profile function handle!(l::ImGuiLayer, e::MouseButtonPressedEvent{button}) where {button}
    CImGui.GLFWBackend.ImGui_ImplGlfw_MouseButtonCallback(
        l.glfw_window, GLFW.MouseButton(Cint(button)), GLFW.PRESS, e.mods
    )
    CImGui.Get_WantCaptureMouse(CImGui.GetIO())
end
@HZ_profile function handle!(l::ImGuiLayer, e::MouseButtonReleasedEvent{button}) where {button}
    CImGui.GLFWBackend.ImGui_ImplGlfw_MouseButtonCallback(
        l.glfw_window, GLFW.MouseButton(Cint(button)), GLFW.RELEASE, e.mods
    )
    CImGui.Get_WantCaptureMouse(CImGui.GetIO())
end
@HZ_profile function handle!(l::ImGuiLayer, e::MouseScrolledEvent)
    CImGui.GLFWBackend.ImGui_ImplGlfw_ScrollCallback(l.glfw_window, e.dx, e.dy)
    CImGui.Get_WantCaptureMouse(CImGui.GetIO())
end

Base.string(l::ImGuiLayer) = "ImGuiLayer" # for debug
