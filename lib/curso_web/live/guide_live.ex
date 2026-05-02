defmodule CursoWeb.GuideLive do
  use CursoWeb, :live_view
  alias Curso.Pages
  alias CursoWeb.Endpoint

  on_mount CursoWeb.RestoreLocale

  def handle_params(params, uri, socket) do
    id = Map.get(params, "id", "getting-started")
    locale = Map.get(params, "locale", socket.assigns[:locale] || "en")

    page = Pages.by_id(id, locale) || Pages.by_id(id, "br")

    previous_page =
      Pages.by_id(page.previous_page_id, locale) || Pages.by_id(page.previous_page_id, "br")

    next_page =
      Pages.by_id(page.next_page_id, locale) || Pages.by_id(page.next_page_id, "br")

    metadata_url = Endpoint.url() <> "/guides/#{page.id}/#{locale}"

    page_languages = Pages.get_languages_for_post(id)

    in_language = if locale == "br", do: "pt-BR", else: "en"

    published_at_iso = Date.to_iso8601(page.date) <> "T00:00:00Z"

    og_image_url =
      "https://dynamic-og-image-generator.vercel.app/api/generate?" <>
        URI.encode_query(%{
          title: page.title,
          author: page.author,
          avatar: "https://avatars.githubusercontent.com/u/9121359",
          websiteUrl: metadata_url,
          theme: "shadesOfPurple"
        })

    hreflang_links =
      Enum.map(page_languages, fn p ->
        hreflang = if p.language == "br", do: "pt-BR", else: "en"
        og_locale = if p.language == "br", do: "pt_BR", else: "en_US"
        href = Endpoint.url() <> "/guides/#{p.id}/#{p.language}"
        %{hreflang: hreflang, og_locale: og_locale, href: href}
      end)

    x_default_href =
      case Enum.find(hreflang_links, fn l -> l.hreflang == "en" end) do
        %{href: href} -> href
        nil -> hreflang_links |> List.first(%{}) |> Map.get(:href, Endpoint.url())
      end

    hreflang_links = [
      %{hreflang: "x-default", og_locale: nil, href: x_default_href} | hreflang_links
    ]

    breadcrumb_schema =
      Jason.encode!(%{
        "@context" => "https://schema.org",
        "@type" => "BreadcrumbList",
        "itemListElement" => [
          %{
            "@type" => "ListItem",
            "position" => 1,
            "name" => page.section,
            "item" => Endpoint.url() <> "/#{locale}"
          },
          %{
            "@type" => "ListItem",
            "name" => page.title,
            "position" => 2,
            "item" => metadata_url
          }
        ]
      })

    tech_article_schema =
      Jason.encode!(%{
        "@context" => "https://schema.org",
        "@type" => "TechArticle",
        "headline" => page.title,
        "description" => page.description,
        "author" => %{
          "@type" => "Person",
          "name" => page.author,
          "url" => "https://lubien.dev"
        },
        "datePublished" => published_at_iso,
        "dateModified" => DateTime.to_iso8601(page.modified_at),
        "articleSection" => page.section,
        "keywords" => Enum.join(page.tags, ", "),
        "url" => metadata_url,
        "inLanguage" => in_language,
        "timeRequired" => "PT#{page.read_minutes}M",
        "image" => og_image_url,
        "publisher" => %{
          "@type" => "Organization",
          "name" => "Adopt LiveView",
          "url" => Endpoint.url()
        }
      })

    socket =
      socket
      |> assign(
        page: page,
        locale: locale,
        base_url_for_locale: "/guides/#{page.id}/",
        page_languages: page_languages,
        previous_page: previous_page,
        next_page: next_page,
        page_progress: 0,
        page_title: page_title(page),
        page_description: page.description,
        og_type: "article",
        hreflang_links: hreflang_links,
        article_published_time: published_at_iso,
        article_modified_time: DateTime.to_iso8601(page.modified_at),
        article_section: page.section,
        article_tags: page.tags,
        article_author: page.author,
        page_jsonld_schemas: [breadcrumb_schema, tech_article_schema],
        pathname: URI.parse(uri).path,
        metadata_url: metadata_url
      )

    {:noreply, socket}
  end

  def page_title(page) do
    "#{page.title} · #{page.section}"
  end

  def handle_event("reading_progress", page_progress, socket) do
    socket = assign(socket, page_progress: page_progress)
    {:reply, %{}, socket}
  end

  def render(assigns) do
    ~H"""
    <.docs_layout class="">
      <.docs_header id="docs-header" title={@page.title} section={@page.section}>
        <p class="text-gray-500">
          <%= gettext("Read time:") %> <%= @page.read_minutes %> <%= ngettext(
            "minute",
            "minutes",
            @page.read_minutes
          ) %>
        </p>
      </.docs_header>

      <div
        id={@page.id}
        phx-mounted={
          JS.dispatch("scroll_to_top")
          |> JS.dispatch("plausible", detail: %{name: "guide_view", props: %{page_id: @page.id}})
        }
      >
        <.prose
          id={"#{@page.id}-prose"}
          class="opacity-0 transition-all duration-500"
          phx-mounted={JS.remove_class("opacity-0")}
        >
          <%= {:safe, @page.body} %>
        </.prose>

        <.prose class="mt-8">
          <h2><%= gettext("Feedback") %></h2>
          <p><%= gettext("Got any feedback about this page? Let us know!") %></p>
        </.prose>

        <.live_component
          module={CursoWeb.Feedback}
          id={"#{@page.id}-feedback"}
          page={@page}
          class="mt-2"
        />
      </div>
      <.prev_next_links previous_page={@previous_page} next_page={@next_page} locale={@locale} />
    </.docs_layout>
    """
  end
end
