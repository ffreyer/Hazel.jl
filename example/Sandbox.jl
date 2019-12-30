using Revise, Hazel
using GLFW

app = DummyApplication()
run(app)


GLFW.DestroyWindow(app.window.window)
