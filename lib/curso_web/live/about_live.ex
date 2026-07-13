defmodule CursoWeb.AboutLive do
  use CursoWeb, :live_view

  on_mount CursoWeb.RestoreLocale

  # def mount(_params, _session, socket) do
  #   {:ok, assign(socket, page_title: gettext("About"))}
  # end

  def handle_params(params, _uri, socket) do
    locale = Map.get(params, "locale", socket.assigns[:locale] || "en")

    base_url = CursoWeb.Endpoint.url()
    metadata_url = if Map.has_key?(params, "locale"), do: base_url <> "/#{locale}", else: base_url

    {:noreply, assign(socket,
      page_title: gettext("About"),
      locale: locale
    )}
  end

  def render(assigns) do
    ~H"""
    <div class="min-w-0 max-w-2xl flex-auto px-4 py-16 lg:max-w-none lg:pl-8 lg:pr-0 xl:px-16">
      <.header>
        <%= gettext("Sobre o Projeto") %>
        <:subtitle><%= gettext("Conheça a nossa história e missão.") %></:subtitle>
      </.header>

      <div class="">
        <div class="mt-4">
          <CursoWeb.Layouts.donate locale={assigns[:locale]} />
        </div>
      </div>
      <%!-- <div class="mt-8 space-y-6 text-gray-600">
        <p>
          <%= gettext("Adopt LiveView é um curso online que ensina como usar Phoenix LiveView, mesmo sem conhecimento prévio de Elixir ou Phoenix.") %>
        </p>
      </div> --%>
    </div>
    """
  end
end
