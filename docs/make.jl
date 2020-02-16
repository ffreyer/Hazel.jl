using Documenter
using Hazel

makedocs(
    sitename = "Hazel",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == true
    ),
    modules = [Hazel],
    pages = [
        "Hazel" => "index.md",
        "Devdocs" => Any[
            "Hazel" => "devdocs/index.md",
            "devdocs/Application.md",
            "devdocs/Window.md",
            "devdocs/Layers.md",
            "devdocs/Events.md",
            "devdocs/Renderer.md",
            "devdocs/OpenGL.md",
            "devdocs/GLFW.md"
        ]
    ]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
