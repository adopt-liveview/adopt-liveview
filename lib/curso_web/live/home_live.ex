defmodule CursoWeb.HomeLive do
  use CursoWeb, :live_view

  on_mount CursoWeb.RestoreLocale

  def handle_params(params, _uri, socket) do
    locale = Map.get(params, "locale", socket.assigns[:locale] || "en")

    socket =
      socket
      |> assign(
        locale: locale,
        base_url_for_locale: ~p"/",
        show_hero: true
      )

    {:noreply, socket}
  end
end
