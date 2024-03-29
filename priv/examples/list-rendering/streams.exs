Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket =
      stream(socket, :foods, [
        %{id: 1, name: "apple"},
        %{id: 2, name: "banana"},
        %{id: 3, name: "carrot"}
      ])

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <ul id="food-stream" phx-update="stream">
      <li :for={{dom_id, food} <- @streams.foods} id={dom_id}>
        <%= food.name %>
      </li>
    </ul>
    """
  end
end

LiveviewPlayground.start()
