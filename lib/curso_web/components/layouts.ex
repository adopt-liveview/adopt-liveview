defmodule CursoWeb.Layouts do
  use CursoWeb, :html

  embed_templates "layouts/*"

  attr :id, :string, default: "donate"
  attr :locale, :string, default: "en"
  attr :mobile?, :boolean, default: false

  def donate(%{locale: "br"} = assigns) do
    ~H"""
    <.prose class="mt-2">
      <h2><%= gettext("Donate") %></h2>
    </.prose>

    <div class={"xl:block flex items-start justify-around #{@mobile? && "gap-x-2"}"}>
      <.prose class="mt-2">
        <.brazilian_pix :if={!@mobile?} />
        <.mobile_brazilian_pix :if={@mobile?} />
      </.prose>

      <.prose class="mt-2">
        <h4><%= gettext("...or buy me a coffee") %></h4>
        <.buy_me_a_coffee />
      </.prose>
    </div>
    """
  end

  def donate(assigns) do
    ~H"""
    <.prose class="mt-2">
      <h2><%= gettext("Donate") %></h2>
    </.prose>

    <.prose class="mt-2 text-center">
      <.buy_me_a_coffee image_class="mx-auto" />
    </.prose>

    <.prose class="mt-4">
      <div id={"#{@id}-with-pix-block"} class={["hidden", @mobile? && "text-center"]}>
        <.brazilian_pix :if={!@mobile?} />
        <.mobile_brazilian_pix :if={@mobile?} class="" />
      </div>

      <.button
        id={"#{@id}-with-pix-button"}
        type="button"
        phx-click={
          show("##{@id}-with-pix-block")
          |> JS.hide(to: "##{@id}-with-pix-button")
          |> JS.dispatch("plausible", detail: %{name: "show_pix", props: %{}})
        }
      >
        <%= gettext("Show brazilian Pix R$") %>
      </.button>
    </.prose>
    """
  end

  attr :id, :string, default: "donate-with-pix"
  attr :class, :string, default: nil
  attr :image_class, :string, default: nil

  def brazilian_pix(assigns) do
    ~H"""
    <.prose id={@id} class={@class}>
      <h4><%= gettext("For brazilians: Pix") %></h4>
      <img
        src="/images/qrcode-pix.png"
        alt={gettext("Brazilian Pix payment QR Code")}
        class={[
          "fill-zinc-700 stroke-zinc-500 transition dark:fill-teal-400/10 dark:stroke-teal-500 mt-2 h-52 w-52",
          @image_class
        ]}
      />
    </.prose>
    """
  end

  attr :class, :string, default: ""

  def mobile_brazilian_pix(assigns) do
    ~H"""
    <div class={@class}>
      <.brazilian_pix
        id="donate-with-pix-mobile"
        class="relative"
        image_class="mx-auto mt-4 !w-52 !h-auto"
      />
      <.copy_button
        id="mobile-donate-with-pix-copy"
        selector={~s([id="mobile-donate-with-pix-copy-data"])}
        class="!relative !top-2 !right-0"
      />
      <span class="hidden">
        <pre><code id="mobile-donate-with-pix-copy-data">00020126580014BR.GOV.BCB.PIX0136a3af0bcb-cac6-4585-8119-58220305adc25204000053039865802BR5906Lubien6005Belem62120508LIveView63047238</code></pre>
      </span>
    </div>
    """
  end

  attr :image_class, :string, default: nil

  def buy_me_a_coffee(assigns) do
    ~H"""
    <.link
      href="https://www.buymeacoffee.com/lubien"
      target="_blank"
      phx-click={JS.dispatch("plausible", detail: %{name: "buy_coffee", props: %{}})}
      aria-label={gettext("Buy me a coffee at buymeacoffee.com/lubien")}
    >
      <img
        src="/images/bmc-button.png"
        alt={gettext("Buy me a coffee at buymeacoffee.com/lubien")}
        class={[
          "fill-zinc-700 stroke-zinc-500 transition dark:fill-teal-400/10 dark:stroke-teal-500 mt-4 max-w-52",
          @image_class
        ]}
      />
    </.link>
    """
  end
end
