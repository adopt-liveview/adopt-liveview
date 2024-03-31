Mix.install([
  {:liveview_playground, "~> 0.1.5"}
])

defmodule CoreComponents do
  use LiveviewPlaygroundWeb, :html

  attr :terms, :list, required: true
  slot :dt, required: true
  slot :dd, required: true

  def dl(assigns) do
    ~H"""
    <dl class="max-w-xs mx-auto">
      <div class="grid grid-cols-1 gap-y-2">
        <div :for={item <- @terms} class="border-b border-gray-300">
          <dt class="text-lg font-semibold"><%= render_slot(@dt, item) %></dt>
          <dd class="text-gray-600"><%= render_slot(@dd, item) %></dd>
        </div>
      </div>
    </dl>
    """
  end
end

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view
  import CoreComponents

  def mount(_params, _session, socket) do
    boxing_terms = [
      %{term: "Jab", definition: "A quick, straight punch thrown with the lead hand."},
      %{
        term: "Hook",
        definition:
          "A punch thrown in a circular motion targeting the side of the opponent's head or body."
      },
      %{
        term: "Cross",
        definition:
          "A powerful punch thrown with the rear hand across the body, traveling straight toward the opponent."
      }
    ]

    socket = assign(socket, boxing_terms: boxing_terms)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <.dl terms={@boxing_terms}>
      <:dt :let={item}><%= item.term %></:dt>
      <:dd :let={item}><%= item.definition %></:dd>
    </.dl>
    """
  end
end

LiveviewPlayground.start(scripts: ["https://cdn.tailwindcss.com"])
