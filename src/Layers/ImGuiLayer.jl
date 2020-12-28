mutable struct ImGuiLayer <: AbstractLayer
    context::Ptr{CImGui.ImGuiContext}
    consume_events::Bool
    glfw_window::GLFW.Window
    ImGuiLayer() = new(C_NULL, true)
end


function set_dark_theme()
    colors = CImGui.GetStyle().Colors
    colors[CImGui.ImGuiCol_WindowBg] = CImGui.ImVec4(0.1f, 0.105f, 0.11f, 1.0f)

    # Headers
    colors[CImGui.ImGuiCol_Header] = CImGui.ImVec4(0.2f, 0.205f, 0.21f, 1.0f)
    colors[CImGui.ImGuiCol_HeaderHovered] = CImGui.ImVec4(0.3f, 0.305f, 0.31f, 1.0f)
    colors[CImGui.ImGuiCol_HeaderActive] = CImGui.ImVec4(0.15f, 0.1505f, 0.151f, 1.0f)
    
    # Buttons
    colors[CImGui.ImGuiCol_Button] = CImGui.ImVec4(0.2f, 0.205f, 0.21f, 1.0f)
    colors[CImGui.ImGuiCol_ButtonHovered] = CImGui.ImVec4(0.3f, 0.305f, 0.31f, 1.0f)
    colors[CImGui.ImGuiCol_ButtonActive] = CImGui.ImVec4(0.15f, 0.1505f, 0.151f, 1.0f)

    # Frame BG
    colors[CImGui.ImGuiCol_FrameBg] = CImGui.ImVec4(0.2f, 0.205f, 0.21f, 1.0f)
    colors[CImGui.ImGuiCol_FrameBgHovered] = CImGui.ImVec4(0.3f, 0.305f, 0.31f, 1.0f)
    colors[CImGui.ImGuiCol_FrameBgActive] = CImGui.ImVec4(0.15f, 0.1505f, 0.151f, 1.0f)

    # Tabs
    colors[CImGui.ImGuiCol_Tab] = CImGui.ImVec4(0.15f, 0.1505f, 0.151f, 1.0f)
    colors[CImGui.ImGuiCol_TabHovered] = CImGui.ImVec4(0.38f, 0.3805f, 0.381f, 1.0f)
    colors[CImGui.ImGuiCol_TabActive] = CImGui.ImVec4(0.28f, 0.2805f, 0.281f, 1.0f)
    colors[CImGui.ImGuiCol_TabUnfocused] = CImGui.ImVec4(0.15f, 0.1505f, 0.151f, 1.0f)
    colors[CImGui.ImGuiCol_TabUnfocusedActive] = CImGui.ImVec4(0.2f, 0.205f, 0.21f, 1.0f)

    # Title
    colors[CImGui.ImGuiCol_TitleBg] = CImGui.ImVec4(0.15f, 0.1505f, 0.151f, 1.0f)
    colors[CImGui.ImGuiCol_TitleBgActive] = CImGui.ImVec4(0.15f, 0.1505f, 0.151f, 1.0f)
    colors[CImGui.ImGuiCol_TitleBgCollapsed] = CImGui.ImVec4(0.15f, 0.1505f, 0.151f, 1.0f)
end


# Interface
function attach(l::ImGuiLayer, app::AbstractApplication)
    l.context = CImGui.CreateContext()
    # IDK
    # io = CImGui.GetIO()
    # fonts = io.Fonts
    # CImGui.AddFontDefault(fonts)
    # CImGui.AddFontFromFileTTF(fonts, "assets/fonts/Open Sans/OpenSans-Regular.ttf", 18)
    # CImGui.AddFontFromFileTTF(fonts, "assets/fonts/Open Sans/OpenSans-Bold.ttf", 18)#

    CImGui.StyleColorsDark()
    glfw_window = native_window(window(app))
    l.glfw_window = glfw_window
    # false because WE give ImGui inputs
    CImGui.GLFWBackend.ImGui_ImplGlfw_InitForOpenGL(glfw_window, false)
    CImGui.OpenGLBackend.ImGui_ImplOpenGL3_Init(410)
    GLFW.SetCharCallback(glfw_window, CImGui.GLFWBackend.ImGui_ImplGlfw_CharCallback)

    # set_dark_theme()

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
# @HZ_profile function update!(app, l::ImGuiLayer, other::ImGuiLayer, ts)
#     nothing
# end

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
