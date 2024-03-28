Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    <h2>Hello <%= "Lubien" %></h2>
    <h2>Hello <%= nil %></h2>
    """
  end
end

LiveviewPlayground.start()
