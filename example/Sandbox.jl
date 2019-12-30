using Revise, Hazel
using GLFW

app = DummyApplication()
@async run(app)


GLFW.DestroyWindow(app.window.window)
