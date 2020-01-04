mutable struct ImGuiLayer <: AbstractLayer
    context::Ptr{Nothing}
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
    CImGui.GLFWBackend.ImGui_ImplGlfw_InitForOpenGL(glfw_window, true)
    CImGui.OpenGLBackend.ImGui_ImplOpenGL3_Init(410)
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

function update!(l::ImGuiLayer)
    # @warn "Update ImGuiLayer"
    Begin(l)
    render(l)
    End(l)
    nothing
end

Base.string(l::ImGuiLayer) = "ImGuiLayer" # for debug
