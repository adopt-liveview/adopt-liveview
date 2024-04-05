defmodule CursoWeb.PageController do
  alias Curso.Pages
  use CursoWeb, :controller

  def home(conn, params) do
    render_guide(conn, "getting-started", params["language"])
  end

  def guide(conn, %{"id" => id} = params) do
    render_guide(conn, id, params["language"])
  end

  defp render_guide(conn, id, language \\ "pt_BR") do
    page = Pages.by_id(id, language) || Pages.by_id(id, "pt_BR")

    previous_page =
      Pages.by_id(page.previous_page_id, language) || Pages.by_id(page.previous_page_id, "pt_BR")

    next_page =
      Pages.by_id(page.next_page_id, language) || Pages.by_id(page.next_page_id, "pt_BR")

    render(conn, :home,
      page: page,
      page_languages: Pages.get_languages_for_post(id),
      previous_page: previous_page,
      next_page: next_page,
      pathname: conn.request_path
    )
  end
end
