defmodule Curso.Pages do
  use CursoWeb, :verified_routes
  use Phoenix.Component
  alias Curso.Pages.Post
  import CursoWeb.Gettext

  use NimblePublisher,
    build: Post,
    from: Application.app_dir(:curso, "priv/pages/**/*.md"),
    as: :pages,
    html_converter: Pages.MarkdownConverter,
    highlighters: [:makeup_elixir, :makeup_erlang, :makeup_diff]

  # The @posts variable is first defined by NimblePublisher.
  # Let's further modify it by sorting all posts by descending date.
  @pages Enum.sort_by(@pages, & &1.date, {:desc, Date})

  # Let's also get all tags
  @tags @pages |> Enum.flat_map(& &1.tags) |> Enum.uniq() |> Enum.sort()

  # And finally export them
  def all_pages, do: @pages
  def all_tags, do: @tags

  def by_id(id, language \\ "br") do
    Enum.find(@pages, &(&1.id == id && &1.language == language))
  end

  def get_languages_for_post(id) do
    Enum.filter(@pages, &String.starts_with?(&1.id, id))
  end

  def content_map(locale \\ "br") do
    assigns = %{}

    [
      %{
        title: gettext("Installation"),
        links: [
          %{
            title: gettext("Installing Erlang and Elixir"),
            href: ~p"/guides/v2-getting-started/#{locale}"
          },
          %{
            title: gettext("Your first Live View"),
            href: ~p"/guides/v2-first-liveview/#{locale}"
          },
          %{
            title: gettext("Anatomy of a LiveView"),
            href: ~p"/guides/v2-anatomy-of-a-liveview/#{locale}"
          }
        ]
      },
      %{
        title: "Fundamentals",
        links: [
          %{
            title: gettext("LiveView Assignments"),
            href: ~p"/guides/v2-mounts-and-assigns/#{locale}"
          },
          %{
            title: gettext("Your first mistakes"),
            href: ~p"/guides/v2-your-first-mistakes/#{locale}"
          },
          %{title: gettext("Modifying state with events"), href: ~p"/guides/v2-events/#{locale}"},
          %{title: gettext("Problematic events"), href: ~p"/guides/v2-event-errors/#{locale}"}
        ]
      },
      %{
        title: "HEEx",
        links: [
          %{title: gettext("HEEx is not HTML"), href: ~p"/guides/v2-heex-is-not-html/#{locale}"},
          %{title: gettext("HEEx Basics"), href: ~p"/guides/v2-basics-of-heex/#{locale}"},
          %{
            title: gettext("Conditional rendering"),
            href: ~p"/guides/v2-conditional-rendering/#{locale}"
          },
          %{title: gettext("List rendering"), href: ~p"/guides/v2-list-rendering/#{locale}"}
        ]
      },
      %{
        title: gettext("Events"),
        links: [
          %{title: ~H"<code>`phx-value`</code>", href: ~p"/guides/v2-phx-value/#{locale}"},
          %{title: ~H"<code>`JS.push`</code>", href: ~p"/guides/v2-js-push/#{locale}"},
          %{
            title: gettext("More than one event triggered"),
            href: ~p"/guides/v2-multiple-pushes/#{locale}"
          }
        ]
      },
      %{
        title: gettext("Navigation"),
        links: [
          %{
            title: gettext("Your second LiveView"),
            href: ~p"/guides/v2-your-second-liveview/#{locale}"
          },
          %{title: gettext("Route parameters"), href: ~p"/guides/v2-route-params/#{locale}"},
          %{
            title: gettext("Generic parameters with query string"),
            href: ~p"/guides/v2-query-string/#{locale}"
          },
          %{
            title: gettext("Navigating to the same route"),
            href: ~p"/guides/v2-navigate-to-the-same-route/#{locale}"
          }
        ]
      },
      %{
        title: "Components",
        links: [
          %{
            title: gettext("Functional components"),
            href: ~p"/guides/v2-function-component/#{locale}"
          },
          %{
            title: gettext("Validating components"),
            href: ~p"/guides/v2-documenting-components/#{locale}"
          },
          %{
            title: gettext("Components from other modules"),
            href: ~p"/guides/v2-components-from-other-modules/#{locale}"
          },
          %{
            title: gettext("Multiple slots"),
            href: ~p"/guides/v2-multiple-slots/#{locale}"
          },
          %{
            title: gettext("Slots with attributes"),
            href: ~p"/guides/v2-slots-with-attributes/#{locale}"
          },
          %{
            title: gettext("Rendering lists with slots"),
            href: ~p"/guides/v2-lists-with-slots/#{locale}"
          }
        ]
      },
      %{
        title: "Forms",
        links: [
          %{title: gettext("Form component"), href: ~p"/guides/v2-forms/#{locale}"},
          %{title: gettext("Validations"), href: ~p"/guides/v2-form-validation/#{locale}"},
          %{
            title: gettext("Simplifying everything with Ecto"),
            href: ~p"/guides/v2-simple-forms-with-ecto/#{locale}"
          }
        ]
      },
      %{
        title: "CRUD",
        links: [
          %{
            title: gettext("My first LiveView project"),
            href: ~p"/guides/v2-my-first-liveview-project/#{locale}"
          },
          %{title: gettext("Storing data"), href: ~p"/guides/v2-saving-data/#{locale}"},
          %{title: gettext("Listing products"), href: ~p"/guides/v2-listing-data/#{locale}"},
          %{title: gettext("Showing a product"), href: ~p"/guides/v2-show-data/#{locale}"},
          %{title: gettext("Deleting a product"), href: ~p"/guides/v2-deleting-data/#{locale}"},
          %{title: gettext("Editing a product"), href: ~p"/guides/v2-editing-data/#{locale}"}
        ]
      },
      %{
        title: "Form Component",
        links: [
          %{title: gettext("DRY Form"), href: ~p"/guides/v2-form-component/#{locale}"},
          %{title: gettext("Live Component"), href: ~p"/guides/v2-live-component/#{locale}"},
          %{title: gettext("Modal Form"), href: ~p"/guides/v2-modal-form/#{locale}"}
        ]
      }
    ]
  end
end
