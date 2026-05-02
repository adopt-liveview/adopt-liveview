defmodule CursoWeb.HomeLive do
  use CursoWeb, :live_view

  on_mount CursoWeb.RestoreLocale

  def handle_params(params, _uri, socket) do
    locale = Map.get(params, "locale", socket.assigns[:locale] || "en")

    base_url = CursoWeb.Endpoint.url()
    metadata_url = base_url <> "/#{locale}"

    hreflang_links = [
      %{hreflang: "x-default", og_locale: nil, href: base_url <> "/en"},
      %{hreflang: "en", og_locale: "en_US", href: base_url <> "/en"},
      %{hreflang: "pt-BR", og_locale: "pt_BR", href: base_url <> "/br"}
    ]

    website_schema =
      Jason.encode!(%{
        "@context" => "https://schema.org",
        "@type" => "WebSite",
        "name" => "Adopt LiveView",
        "url" => base_url,
        "description" =>
          "Learn how to use Phoenix LiveView with no prior Elixir or Phoenix knowledge"
      })

    course_schema =
      Jason.encode!(%{
        "@context" => "https://schema.org",
        "@type" => "Course",
        "name" => "Adopt LiveView",
        "description" =>
          "Learn how to use Phoenix LiveView with no prior Elixir or Phoenix knowledge",
        "url" => base_url,
        "provider" => %{
          "@type" => "Person",
          "name" => "Lubien",
          "url" => "https://lubien.dev"
        },
        "educationalLevel" => "Beginner",
        "teaches" => "Phoenix LiveView",
        "inLanguage" => ["en", "pt-BR"],
        "isAccessibleForFree" => true,
        "coursePrerequisites" => "No prior Elixir or Phoenix knowledge required",
        "hasCourseInstance" => %{
          "@type" => "CourseInstance",
          "courseMode" => "online",
          "inLanguage" => ["en", "pt-BR"]
        }
      })

    socket =
      socket
      |> assign(
        locale: locale,
        base_url_for_locale: ~p"/",
        page_title: gettext("Learn LiveView now!"),
        page_description:
          gettext("Learn how to use Phoenix LiveView with no prior Elixir or Phoenix knowledge"),
        metadata_url: metadata_url,
        hreflang_links: hreflang_links,
        page_jsonld_schemas: [website_schema, course_schema],
        show_hero: true
      )

    {:noreply, socket}
  end
end
