defmodule CursoWeb.RestoreLocale do
  def on_mount(:default, params, _session, socket) do
    locale = Map.get(params, "locale", "br") |> dbg
    Gettext.put_locale(CursoWeb.Gettext, locale)
    {:cont, socket}
  end

  # catch-all case
  def on_mount(:default, _params, _session, socket), do: {:cont, socket}
end
