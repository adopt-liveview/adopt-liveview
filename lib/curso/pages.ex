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
        title: gettext("Instalação"),
        links: [
          %{
            title: gettext("Instalando Erlang e Elixir"),
            href: ~p"/guides/getting-started/#{locale}"
          },
          %{
            title: gettext("Criando sua primeira LiveView"),
            href: ~p"/guides/first-liveview/#{locale}"
          },
          %{
            title: gettext("Anatomia de uma LiveView"),
            href: ~p"/guides/explain-playground/#{locale}"
          }
        ]
      },
      %{
        title: "Fundamentos",
        links: [
          %{
            title: gettext("Assigns de uma LiveView"),
            href: ~p"/guides/mount-and-assigns/#{locale}"
          },
          %{
            title: gettext("Seus primeiros erros"),
            href: ~p"/guides/your-first-mistakes/#{locale}"
          },
          %{title: gettext("Modificando estado com eventos"), href: ~p"/guides/events/#{locale}"},
          %{title: gettext("Eventos problemáticos"), href: ~p"/guides/event-errors/#{locale}"}
        ]
      },
      %{
        title: "HEEx",
        links: [
          %{title: gettext("HEEx não é HTML"), href: ~p"/guides/heex-is-not-html/#{locale}"},
          %{title: gettext("Básico de HEEx"), href: ~p"/guides/basics-of-heex/#{locale}"},
          %{
            title: gettext("Renderização condicional"),
            href: ~p"/guides/conditional-rendering/#{locale}"
          },
          %{title: gettext("Renderização de listas"), href: ~p"/guides/list-rendering/#{locale}"}
        ]
      },
      %{
        title: "Eventos",
        links: [
          %{title: ~H"<code>`phx-value`</code>", href: ~p"/guides/phx-value/#{locale}"},
          %{title: ~H"<code>`JS.push`</code>", href: ~p"/guides/js-push/#{locale}"},
          %{
            title: gettext("Mais de um evento disparado"),
            href: ~p"/guides/multiple-pushes/#{locale}"
          }
        ]
      },
      %{
        title: "Navegação",
        links: [
          %{
            title: gettext("Sua segunda LiveView"),
            href: ~p"/guides/your-second-liveview/#{locale}"
          },
          %{title: gettext("Parâmetros de rotas"), href: ~p"/guides/route-params/#{locale}"},
          %{
            title: gettext("Parâmetros genéricos com query string"),
            href: ~p"/guides/query-string/#{locale}"
          },
          %{
            title: gettext("Navegando para a mesma rota"),
            href: ~p"/guides/navigate-to-the-same-route/#{locale}"
          }
        ]
      },
      %{
        title: "Componentes",
        links: [
          %{
            title: gettext("Componentes funcionais"),
            href: ~p"/guides/function-component/#{locale}"
          },
          %{
            title: gettext("Validando componentes"),
            href: ~p"/guides/documenting-components/#{locale}"
          },
          %{
            title: gettext("Componentes de outros módulos"),
            href: ~p"/guides/components-from-other-modules/#{locale}"
          },
          %{
            title: gettext("Múltiplos slots"),
            href: ~p"/guides/multiple-slots/#{locale}"
          },
          %{
            title: gettext("Slots com atributos"),
            href: ~p"/guides/slots-with-attributes/#{locale}"
          },
          %{
            title: gettext("Renderizando listas com slots"),
            href: ~p"/guides/lists-with-slots/#{locale}"
          }
        ]
      },
      %{
        title: "Formulários",
        links: [
          %{title: gettext("Componente de formulário"), href: ~p"/guides/forms/#{locale}"},
          %{title: gettext("Validações"), href: ~p"/guides/form-validation/#{locale}"},
          %{
            title: gettext("Simplificando tudo com Ecto"),
            href: ~p"/guides/simple-forms-with-ecto/#{locale}"
          }
        ]
      },
      %{
        title: "CRUD",
        links: [
          %{
            title: gettext("Meu primeiro projeto LiveView"),
            href: ~p"/guides/my-first-liveview-project/#{locale}"
          },
          %{title: gettext("Armazenando dados"), href: ~p"/guides/saving-data/#{locale}"}
        ]
      }
    ]
  end
end
