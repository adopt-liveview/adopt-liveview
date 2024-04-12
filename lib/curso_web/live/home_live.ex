defmodule CursoWeb.HomeLive do
  use CursoWeb, :live_view

  on_mount CursoWeb.RestoreLocale

  def handle_params(params, _uri, socket) do
    locale = Map.get(params, "locale", socket.assigns[:locale] || "en")

    metadata_url = CursoWeb.Endpoint.url() <> "/#{locale}"

    socket =
      socket
      |> assign(
        locale: locale,
        base_url_for_locale: ~p"/",
        page_title: gettext("Learn LiveView now!"),
        page_description:
          gettext("Learn how to use Phoenix LiveView with no prior Elixir or Phoenix knowledge"),
        metadata_url: metadata_url,
        show_hero: true
      )

    {:noreply, socket}
  end
end
