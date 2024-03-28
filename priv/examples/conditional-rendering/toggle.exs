Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, show_information?: false)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <%= if @show_information? do %>
        <p>You're an amazing person!</p>
      <% else %>
        <p>You can't see this message!</p>
      <% end %>
    </div>

    <input type="button" value="Toggle" phx-click="toggle" >
    """
  end

  def handle_event("toggle", _params, socket) do
    socket = assign(socket, show_information?: !socket.assigns.show_information?)
    {:noreply, socket}
  end
end

LiveviewPlayground.start()
