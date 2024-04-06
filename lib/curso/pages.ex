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

  def content_map do
    assigns = %{}

    [
      %{
        title: gettext("Instalação"),
        links: [
          %{title: gettext("Instalando Erlang e Elixir"), href: ~p"/"},
          %{title: gettext("Criando sua primeira LiveView"), href: ~p"/guides/first-liveview"},
          %{title: gettext("Anatomia de uma LiveView"), href: ~p"/guides/explain-playground"}
        ]
      },
      %{
        title: "Fundamentos",
        links: [
          %{title: gettext("Assigns de uma LiveView"), href: ~p"/guides/mount-and-assigns"},
          %{title: gettext("Seus primeiros erros"), href: ~p"/guides/your-first-mistakes"},
          %{title: gettext("Modificando estado com eventos"), href: ~p"/guides/events"},
          %{title: gettext("Eventos problemáticos"), href: ~p"/guides/event-errors"}
        ]
      },
      %{
        title: "HEEx",
        links: [
          %{title: gettext("HEEx não é HTML"), href: ~p"/guides/heex-is-not-html"},
          # %{title: "Atributos", href: ~p"/guides/assign-attributes"},
          %{title: gettext("Básico de HEEx"), href: ~p"/guides/basics-of-heex"},
          %{title: gettext("Renderização condicional"), href: ~p"/guides/conditional-rendering"},
          %{title: gettext("Renderização de listas"), href: ~p"/guides/list-rendering"}
        ]
      },
      %{
        title: "Eventos",
        links: [
          %{title: ~H"<code>`phx-value`</code>", href: ~p"/guides/phx-value"},
          %{title: ~H"<code>`JS.push`</code>", href: ~p"/guides/js-push"},
          %{title: gettext("Mais de um evento disparado"), href: ~p"/guides/multiple-pushes"}
        ]
      },
      %{
        title: "Navegação",
        links: [
          %{title: gettext("Sua segunda LiveView"), href: ~p"/guides/your-second-liveview"},
          %{title: gettext("Parâmetros de rotas"), href: ~p"/guides/route-params"},
          %{
            title: gettext("Parâmetros genéricos com query string"),
            href: ~p"/guides/query-string"
          },
          %{
            title: gettext("Navegando para a mesma rota"),
            href: ~p"/guides/navigate-to-the-same-route"
          }
        ]
      },
      %{
        title: "Componentes",
        links: [
          %{title: gettext("Componentes funcionais"), href: ~p"/guides/function-component"},
          %{title: gettext("Validando componentes"), href: ~p"/guides/documenting-components"},
          %{
            title: gettext("Componentes de outros módulos"),
            href: ~p"/guides/components-from-other-modules"
          },
          %{
            title: gettext("Múltiplos slots"),
            href: ~p"/guides/multiple-slots"
          },
          %{
            title: gettext("Slots com atributos"),
            href: ~p"/guides/slots-with-attributes"
          },
          %{
            title: gettext("Renderizando listas com slots"),
            href: ~p"/guides/lists-with-slots"
          }
        ]
      },
      %{
        title: "Formulários",
        links: [
          %{title: gettext("Componente de formulário"), href: ~p"/guides/forms"},
          %{title: gettext("Validações"), href: ~p"/guides/form-validation"},
          %{
            title: gettext("Simplificando tudo com Ecto"),
            href: ~p"/guides/simple-forms-with-ecto"
          }
        ]
      },
      %{
        title: "CRUD",
        links: [
          %{
            title: gettext("Meu primeiro projeto LiveView"),
            href: ~p"/guides/my-first-liveview-project"
          },
          %{title: gettext("Armazenando dados"), href: ~p"/guides/saving-data"}
        ]
      }
    ]
  end
end
