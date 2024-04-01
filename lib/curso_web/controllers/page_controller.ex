defmodule CursoWeb.PageController do
  alias Curso.Pages
  use CursoWeb, :controller

  def home(conn, _params) do
    conn |> dbg
    render(conn, :home, page: Pages.by_id("getting-started"), pathname: conn.request_path)
  end

  def guide(conn, %{"id" => id}) do
    render(conn, :home, page: Pages.by_id(id), pathname: conn.request_path)
  end
end
