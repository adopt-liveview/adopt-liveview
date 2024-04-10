defmodule CursoWeb.Layouts do
  use CursoWeb, :html

  embed_templates "layouts/*"

  def donate(%{locale: "br"} = assigns) do
    ~H"""
    <.prose class="mt-2">
      <h2><%= gettext("Donate") %></h2>
    </.prose>

    <.prose class="mt-2"><.brazilian_pix /></.prose>

    <.prose class="mt-2">
      <h4><%= gettext("...or buy me a coffee") %></h4>
      <.buy_me_a_coffee />
    </.prose>
    """
  end

  def donate(assigns) do
    ~H"""
    <.prose class="mt-2">
      <h2><%= gettext("Donate") %></h2>
    </.prose>

    <.prose class="mt-2">
      <.buy_me_a_coffee />
    </.prose>

    <.prose class="mt-4">
      <.brazilian_pix class="hidden" />

      <.button
        id="donate-with-pix-button"
        type="button"
        phx-click={show("#donate-with-pix") |> JS.hide(to: "#donate-with-pix-button")}
      >
        Show brazilian Pix R$
      </.button>
    </.prose>
    """
  end

  attr :class, :string, default: ""

  def brazilian_pix(assigns) do
    ~H"""
    <div id="donate-with-pix" class={@class}>
      <h4><%= gettext("For brazilians: Pix") %></h4>
      <img
        src="/images/qrcode-pix.png"
        class="fill-zinc-700 stroke-zinc-500 transition dark:fill-teal-400/10 dark:stroke-teal-500 mt-2"
      />
    </div>
    """
  end

  def buy_me_a_coffee(assigns) do
    ~H"""
    <.link href="https://www.buymeacoffee.com/lubien" target="_blank">
      <img
        src="/images/bmc-button.png"
        class="fill-zinc-700 stroke-zinc-500 transition dark:fill-teal-400/10 dark:stroke-teal-500 mt-2"
      />
    </.link>
    """
  end
end
