Mix.install([
  {:liveview_playground, "~> 0.1.3"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(params, _session, socket) do
    admin? = params["admin_mode"] == "secret123"
    socket = assign(socket, :admin?, admin?)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <h1>Welcome to my Website!</h1>
    <.link :if={@admin?} navigate={~p"/admin"}>Go to admin panel</.link>
    """
  end
end

LiveviewPlayground.start()
