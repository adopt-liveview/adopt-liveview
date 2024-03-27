Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, name: "Lubien")
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      Hello <%= @name %>

      <input type="button" value="Reverse" phx-click="reverse" >
    </div>
    """
  end
end

LiveviewPlayground.start()
