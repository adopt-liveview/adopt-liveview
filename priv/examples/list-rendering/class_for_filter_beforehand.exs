Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    foods = Enum.filter(["apple", "banana", "carrot"], fn food -> food != "banana" end)
    socket = assign(socket, foods: foods)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <ul>
      <%= for food <- @foods do %>
        <li><%= food %></li>
      <% end %>
    </ul>
    """
  end
end

LiveviewPlayground.start()
