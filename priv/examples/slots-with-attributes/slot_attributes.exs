Mix.install([
  {:liveview_playground, "~> 0.1.5"}
])

defmodule CustomRouter do
  use LiveviewPlaygroundWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
  end

  scope "/" do
    pipe_through :browser

    live "/", IndexLive, :index
    live "/other", OtherPageLive, :index
  end
end

defmodule CoreComponents do
  use LiveviewPlaygroundWeb, :html

  slot :title do
    attr :class, :string
  end

  slot :subtitle
  slot :inner_block

  def hero(assigns) do
    ~H"""
    <div class="bg-gray-800 text-white py-20">
      <div class="container mx-auto text-center">
        <h1 :for={title_slot <- @title} class={["text-4xl font-bold", Map.get(title_slot, :class)]}>
          <%= render_slot(title_slot) %>
        </h1>
        <p class="mt-4 text-lg"><%= render_slot(@subtitle) %></p>
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end
end

defmodule IndexLive do
  use LiveviewPlaygroundWeb, :live_view
  import CoreComponents

  def render(assigns) do
    ~H"""
    <.hero>
      <:title class="text-red-500">IndexLive</:title>
      <:subtitle>Welcometo my personal website!</:subtitle>
      <.link
        class="mt-8 bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-4 rounded"
        navigate={~p"/other"}
      >
        Get Started
      </.link>
    </.hero>
    <.link navigate={~p"/other"}>Go to other</.link>
    """
  end
end

defmodule OtherPageLive do
  use LiveviewPlaygroundWeb, :live_view
  import CoreComponents

  def render(assigns) do
    ~H"""
    <.hero>
      <:title>OtherPageLive</:title>
      <:subtitle>You're on the first step!</:subtitle>
    </.hero>
    <.link navigate={~p"/"}>Go to home</.link>
    """
  end
end

LiveviewPlayground.start(router: CustomRouter, scripts: ["https://cdn.tailwindcss.com"])
