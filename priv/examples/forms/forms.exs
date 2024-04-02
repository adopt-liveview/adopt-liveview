Mix.install([
  {:liveview_playground, path: "../../"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def handle_event("create_product", %{"product" => product_params}, socket) do
    IO.inspect(product_params)
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="bg-grey-100">
      <form phx-submit="create_product" class="flex flex-col max-w-96 mx-auto bg-gray-100 p-24">
        <h1>Creating a product</h1>
        <input type="text" name="product[name]" placeholder="Name" />
        <input type="text" name="product[description]" placeholder="Description" />
        <button type="submit">Send</button>
      </form>
    </div>
    """
  end
end

LiveviewPlayground.start(scripts: ["https://cdn.tailwindcss.com?plugins=forms"])
