Mix.install([
  {:liveview_playground, "~> 0.1.3"}
])

defmodule CustomRouter do
  use LiveviewPlaygroundWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
  end

  scope "/" do
    pipe_through :browser

    live "/", TabLive, :show
    live "/tab/:tab", TabLive, :show
  end
end

defmodule TabLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(params, _session, socket) do
    tab = params["tab"] || "home"
    socket = assign(socket, tab: tab)
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

    <.link :if={@tab != "home"} navigate={~p"/"}>Go to home</.link>
    <.link :if={@tab != "about"} navigate={~p"/tab/about"}>Go to about</.link>
    <.link :if={@tab != "contact"} navigate={~p"/tab/contact"}>Go to contact</.link>
    """
  end
end

LiveviewPlayground.start(router: CustomRouter)
