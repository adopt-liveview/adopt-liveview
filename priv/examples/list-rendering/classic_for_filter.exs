Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, foods: ["apple", "banana", "carrot"])
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <ul>
      <%= for food <- @foods, food != "banana" do %>
        <li><%= food %></li>
      <% end %>
    </ul>
    """
  end
end

LiveviewPlayground.start()
