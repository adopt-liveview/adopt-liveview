defmodule CursoWeb.GuideLive do
  use CursoWeb, :live_view
  alias Curso.Pages

  on_mount CursoWeb.RestoreLocale

  def handle_params(params, uri, socket) do
    id = Map.get(params, "id", "getting-started")
    locale = Map.get(params, "locale", socket.assigns[:locale] || "en")

    page = Pages.by_id(id, locale) || Pages.by_id(id, "br")

    previous_page =
      Pages.by_id(page.previous_page_id, locale) || Pages.by_id(page.previous_page_id, "br")

    next_page =
      Pages.by_id(page.next_page_id, locale) || Pages.by_id(page.next_page_id, "br")

    socket =
      socket
      |> assign(
        page: page,
        locale: locale,
        page_languages: Pages.get_languages_for_post(id),
        previous_page: previous_page,
        next_page: next_page,
        pathname: URI.parse(uri).path
      )

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <.docs_layout title={@page.title} section={@page.section} class="">
      <div id={@page.id} phx-mounted={JS.dispatch("scroll_to_top")}>
        <.prose
          id={"#{@page.id}-prose"}
          class="opacity-0 transition-all duration-500"
          phx-mounted={JS.remove_class("opacity-0")}
        >
          <%= {:safe, @page.body} %>
        </.prose>
      </div>
      <.prev_next_links previous_page={@previous_page} next_page={@next_page} locale={@locale} />
    </.docs_layout>
    """
  end
end
