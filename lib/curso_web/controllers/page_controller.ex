defmodule CursoWeb.PageController do
  alias Curso.Pages
  use CursoWeb, :controller

  def home(conn, _params) do
    render(conn, :home, page: Pages.by_id("getting-started"))
  end

  def guide(conn, %{"id" => id}) do
    render(conn, :home, page: Pages.by_id(id))
  end
end
