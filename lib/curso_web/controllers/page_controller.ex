defmodule CursoWeb.PageController do
  alias Curso.Pages
  use CursoWeb, :controller

  def home(conn, _params) do
    render(conn, :home, page: Pages.by_id("getting-started"))
  end

  def first_liveview(conn, _params) do
    render(conn, :home, page: Pages.by_id("first-liveview"))
  end

  def explain_playground(conn, _params) do
    render(conn, :home, page: Pages.by_id("explain-playground"))
  end
end
