defmodule CursoWeb.PageController do
  alias Curso.Pages
  use CursoWeb, :controller

  def home(conn, _params) do
    page = Pages.by_id("getting-started")
    previous_page = Pages.by_id(page.previous_page_id)
    next_page = Pages.by_id(page.next_page_id)
    render(conn, :home, page: page, previous_page: previous_page, next_page: next_page, pathname: conn.request_path)
  end

  def guide(conn, %{"id" => id}) do
    page = Pages.by_id(id)
    previous_page = Pages.by_id(page.previous_page_id)
    next_page = Pages.by_id(page.next_page_id)
    render(conn, :home, page: page, previous_page: previous_page, next_page: next_page, pathname: conn.request_path)
  end
end
