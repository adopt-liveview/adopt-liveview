Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule User do
  defstruct id: nil, name: nil
end

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    <h2>Hello <%= %User{id: 1, name: "Lubien"} %></h2>
    """
  end
end

LiveviewPlayground.start()
