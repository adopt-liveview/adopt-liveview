Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, tab: "home")
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <%= case @tab do %>
        <% "home" -> %>
          <p>You're on my personal page!</p>
        <% "about" -> %>
          <p>Hi, I'm a LiveView developer!</p>
        <% "contact" -> %>
          <p>Mail me to bot [at] company [dot] com</p>
      <% end %>
    </div>

    <input disabled={@tab == "home"} type="button" value="Open Home" phx-click="show_home" />
    <input disabled={@tab == "about"} type="button" value="Open About" phx-click="show_about" />
    <input disabled={@tab == "contact"} type="button" value="Open Contact" phx-click="show_contact" />
    """
  end

  def handle_event("show_" <> tab, _params, socket) do
    socket = assign(socket, tab: tab)
    {:noreply, socket}
  end
end

LiveviewPlayground.start()
