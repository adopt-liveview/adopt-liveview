defmodule CursoWeb.PageController do
  alias Curso.Pages
  use CursoWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, page: Pages.by_id("getting-started"))
  end
end
