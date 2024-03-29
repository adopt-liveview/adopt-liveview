
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, temperature_celsius: 30)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      Current temperature: <%= @temperature_celsius %>C
    </div>
    <div>
      <%= cond do %>
        <% @temperature_celsius > 40 -> %>
          <p>🔥 Impossible to live 🔥</p>
        <% @temperature_celsius > 30 -> %>
          <p>Its hot</p>
        <% @temperature_celsius > 20 -> %>
          <p>Kinda cool</p>
        <% @temperature_celsius > 10 -> %>
          <p>Chill</p>
        <% @temperature_celsius > 0 -> %>
          <p>Chill</p>
        <% true -> %>
          <p>❄️⛄️</p>
      <% end %>
    </div>

    <input type="button" value="+5" phx-click={JS.push("add", value: %{amount: +5})} />
    <input type="button" value="+10" phx-click={JS.push("add", value: %{amount: +10})} />
    <input type="button" value="-5" phx-click={JS.push("add", value: %{amount: -5})} />
    <input type="button" value="-10" phx-click={JS.push("add", value: %{amount: -10})} />
    """
  end

  def handle_event("add", %{"amount" => amount}, socket) do
    socket = assign(socket, temperature_celsius: socket.assigns.temperature_celsius + amount)
    {:noreply, socket}
  end
end

LiveviewPlayground.start()
