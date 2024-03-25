Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket.assigns |> dbg
    socket = assign(socket, name: "Lubien")
    socket.assigns |> dbg
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    Hello <%= assigns.name %>
    """
  end
end

LiveviewPlayground.start()
