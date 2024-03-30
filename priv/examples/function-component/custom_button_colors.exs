Mix.install([
  {:liveview_playground, "~> 0.1.5"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    <.button color="blue">Default</.button>
    <.button color="green">Green</.button>
    <.button color="red">Red</.button>
    <.button color="yellow">Yellow</.button>
    """
  end

  def button(assigns) do
    ~H"""
    <button
      type="button"
      class={"text-white bg-#{@color}-700 hover:bg-#{@color}-800 focus:ring-4 focus:ring-#{@color}-300 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 dark:bg-#{@color}-600 dark:hover:bg-#{@color}-700 focus:outline-none dark:focus:ring-#{@color}-800"}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end
end

LiveviewPlayground.start(scripts: ["https://cdn.tailwindcss.com"])
