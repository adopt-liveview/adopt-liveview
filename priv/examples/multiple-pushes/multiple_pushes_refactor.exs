Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, red: 0, blue: 0)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <dl>
      <dt>Red Points</dt>
      <dd><%= @red %></dd>

      <dt>Blue Points</dt>
      <dd><%= @blue %></dd>
    </dl>

    <input
      type="button"
      value="Red Wins"
      phx-click={add_points(:red, 3)}
    />
    <input
      type="button"
      value="Blue Wins"
      phx-click={add_points(:blue, 3)}
    />
    <input
      type="button"
      value="Draw"
      phx-click={add_points(:red, 1) |> add_points(:blue, 1)}
    />
    """
  end

  defp add_points(js \\ %JS{}, team, amount) do
    JS.push(js, "add_points", value: %{team: team, amount: amount})
  end

  def handle_event("add_points", %{"team" => team, "amount" => amount}, socket) do
    team_atom = String.to_existing_atom(team)
    current_points = socket.assigns[team_atom]
    socket = assign(socket, team_atom, current_points + amount)
    {:noreply, socket}
  end
end

LiveviewPlayground.start()
