defmodule CursoWeb.LocalePlug do
  import Plug.Conn
  @session_name "preferred_locale"

  def init(_) do
    []
  end

  def call(conn, _opts) do
    conn = fetch_session(conn, @session_name)

    if get_session(conn)[@session_name] == nil do
      with [accept_language] <- get_req_header(conn, "accept-language") |> dbg,
           {:ok, matched} = Curso.Cldr.AcceptLanguage.best_match(accept_language) do
        put_session(conn, "preferred_locale", map_language_tag_to_locale(matched))
      else
        _other ->
          conn
      end
    else
      conn
    end
  end

  def map_language_tag_to_locale(%{language: "pt"}) do
    # we do some trolling
    "br"
  end

  def map_language_tag_to_locale(_matched) do
    "en"
  end
end
