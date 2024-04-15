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
        <.stripe_button />
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
      <.stripe_button image_class="mx-auto" />
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
        <pre><code id="mobile-donate-with-pix-copy-data">00020101021126700014br.gov.bcb.pix0136a3af0bcb-cac6-4585-8119-58220305adc20208Liveview5204000053039865802BR5917JOAO DE D F FILHO6005BELEM62070503***63046715</code></pre>
      </span>
    </div>
    """
  end

  def stripe_button(assigns) do
    ~H"""
    <.link
      href="https://donate.stripe.com/28o2aicj8fnr3HaaEE"
      target="_blank"
      phx-click={JS.dispatch("plausible", detail: %{name: "donate_stripe", props: %{}})}
      aria-label={gettext("Donate via Stripe")}
    >
      <.button class="w-full">
        <%= gettext("Donate with Stripe") %>
      </.button>
    </.link>
    """
  end

  def language_for_locale(nil), do: "en"
  def language_for_locale(locale), do: locale
end
