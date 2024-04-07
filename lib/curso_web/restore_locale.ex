defmodule CursoWeb.RestoreLocale do
  def on_mount(:default, params, session, socket) do
    locale = Map.get(params, "locale", session["preferred_locale"] || "en")
    Gettext.put_locale(CursoWeb.Gettext, locale)
    {:cont, Phoenix.Component.assign(socket, locale: locale)}
  end

  # catch-all case
  def on_mount(:default, _params, _session, socket), do: {:cont, socket}
end
