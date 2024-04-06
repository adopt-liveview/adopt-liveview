defmodule CursoWeb.GuideLive do
  use CursoWeb, :live_view
  alias Curso.Pages

  def handle_params(params, uri, socket) do
    id = Map.get(params, "id", "getting-started")
    language = Map.get(params, "language", "pt_BR")

    page = Pages.by_id(id, language) || Pages.by_id(id, "pt_BR")

    previous_page =
      Pages.by_id(page.previous_page_id, language) || Pages.by_id(page.previous_page_id, "pt_BR")

    next_page =
      Pages.by_id(page.next_page_id, language) || Pages.by_id(page.next_page_id, "pt_BR")

    socket =
      socket
      |> assign(
        page: page,
        page_languages: Pages.get_languages_for_post(id),
        previous_page: previous_page,
        next_page: next_page,
        pathname: URI.parse(uri).path
      )

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <.docs_layout title={@page.title} section={@page.section}>
      <%= {:safe, @page.body} %>
      <.prev_next_links previous_page={@previous_page} next_page={@next_page} />
    </.docs_layout>
    """
  end
end
