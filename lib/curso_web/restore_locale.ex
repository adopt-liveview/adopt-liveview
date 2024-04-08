defmodule CursoWeb.RestoreLocale do
  def on_mount(:default, params, session, socket) do
    locale = Map.get(params, "locale", session["preferred_locale"] || "en")
    Gettext.put_locale(CursoWeb.Gettext, locale)
    {:cont, Phoenix.Component.assign(socket, locale: locale)}
  end
end
