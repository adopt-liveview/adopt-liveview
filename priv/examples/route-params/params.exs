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

    live "/", IndexLive, :index
    live "/blog/:slug", BlogLive, :index
  end
end

defmodule IndexLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    <h1>Welcome to my Website!</h1>
    <ul>
      <li><.link navigate={~p"/blog/dolphins"}>Read about dolphins</.link></li>
      <li><.link navigate={~p"/blog/elephants"}>Read about elephants</.link></li>
    </ul>
    """
  end
end

defmodule BlogLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(%{"slug" => slug}, _session, socket) do
    socket = assign(socket, :slug, slug)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <h1>Reading about <%= @slug %></h1>
    """
  end
end

LiveviewPlayground.start(router: CustomRouter)
