defmodule MarkdownConverter do
  alias CursoWeb.CoreComponents
  import Phoenix.Component
  # import CursoWeb.CoreComponents, only: [callout: 1]

  def convert(filepath, body, _attrs, opts) do
    convert_body(Path.extname(filepath), body, opts)
  end

  defp convert_body(extname, body, opts) when extname in [".md", ".markdown", ".livemd"] do
    handler = fn
      {"h" <> x, _inner, [text], meta}, nil when x in ~w(1 2 3 4 5 6) ->
        {{"h#{x}", [{"id", anchor_id(text)}], [text], meta}, nil}

      {_, [], bits, meta} = item, nil ->
        case Map.get(meta, :annotation) do
          "%% ." <> component ->
            {assigns, _rest} =
              bits
              |> flatten_ast()
              |> Enum.join("")
              |> String.trim()
              |> Code.eval_string([assigns: %{}], __ENV__)

            func =
              Function.capture(CoreComponents, String.to_atom(component), 1)

            code =
              Phoenix.LiveView.TagEngine.component(
                func,
                Map.to_list(assigns),
                {__ENV__.module, __ENV__.function, __ENV__.file, __ENV__.line}
              )

            html =
              code
              |> Phoenix.HTML.Safe.to_iodata()
              |> to_string()
              |> Floki.parse_document!()
              |> Floki.traverse_and_update(fn el -> Tuple.append(el, %{}) end)
              |> Enum.find(fn
                {:comment, _, _} -> false
                _ -> true
              end)

            {html, nil}

          _ ->
            {item, nil}
        end

      {:comment, _, _}, acc ->
        {"", acc}

      item, acc ->
        {item, acc}
    end

    html =
      Earmark.as_ast!(body, annotations: "%%")
      |> case do
        list when is_list(list) ->
          list
          |> Earmark.Restructure.walk_and_modify_ast(nil, fn a, b ->
            handler.(a, b)
          end)
          |> Earmark.transform()

        _ ->
          ""
      end

    highlighters = Keyword.get(opts, :highlighters, [])
    html |> NimblePublisher.highlight(highlighters)
  end

  defp anchor_id(str) do
    str
    |> String.downcase()
    |> String.replace(~r/[^a-z]+/, "-")
    |> String.trim("-")
  end

  def flatten_ast(str) when is_binary(str), do: [str]

  def flatten_ast(items) when is_list(items) do
    Enum.flat_map(items, &flatten_ast/1)
  end

  def flatten_ast({:comment, _, _parts, _meta}) do
    []
  end

  def flatten_ast({_tag, _, parts, _meta}) when is_list(parts) do
    Enum.flat_map(parts, &flatten_ast/1)
  end

  def tip(assigns) do
    ~H"""
    <div>
      Bem vindo ao <%= @title %>
      <div>b</div>
    </div>
    """
  end

  defdelegate callout(assigns), to: CursoWeb.CoreComponents
end

defmodule Curso.Pages do
  use CursoWeb, :verified_routes
  use Phoenix.Component
  alias Curso.Pages.Post

  use NimblePublisher,
    build: Post,
    from: Application.app_dir(:curso, "priv/pages/**/*.md"),
    as: :pages,
    html_converter: MarkdownConverter,
    highlighters: [:makeup_elixir, :makeup_erlang, :makeup_diff]

  # The @posts variable is first defined by NimblePublisher.
  # Let's further modify it by sorting all posts by descending date.
  @pages Enum.sort_by(@pages, & &1.date, {:desc, Date})

  # Let's also get all tags
  @tags @pages |> Enum.flat_map(& &1.tags) |> Enum.uniq() |> Enum.sort()

  # And finally export them
  def all_pages, do: @pages
  def all_tags, do: @tags
  def by_id(id), do: Enum.find(@pages, &(&1.id == id))

  def content_map do
    assigns = %{}

    [
      %{
        title: "Instalação",
        links: [
          %{title: "Instalando Erlang e Elixir", href: ~p"/"},
          %{title: "Criando sua primeira LiveView", href: ~p"/guides/first-liveview"},
          %{title: "Anatomia de uma LiveView", href: ~p"/guides/explain-playground"}
        ]
      },
      %{
        title: "Fundamentos",
        links: [
          %{title: "Assigns de uma LiveView", href: ~p"/guides/mount-and-assigns"},
          %{title: "Seus primeiros erros", href: ~p"/guides/your-first-mistakes"},
          %{title: "Modificando estado com eventos", href: ~p"/guides/events"},
          %{title: "Eventos problemáticos", href: ~p"/guides/event-errors"}
        ]
      },
      %{
        title: "HEEx",
        links: [
          %{title: "HEEx não é HTML", href: ~p"/guides/heex-is-not-html"},
          # %{title: "Atributos", href: ~p"/guides/assign-attributes"},
          %{title: "Básico de HEEx", href: ~p"/guides/basics-of-heex"},
          %{title: "Renderização condicional", href: ~p"/guides/conditional-rendering"},
          %{title: "Renderização de listas", href: ~p"/guides/list-rendering"}
        ]
      },
      %{
        title: "Eventos",
        links: [
          %{title: ~H"<code>`phx-value`</code>", href: ~p"/guides/phx-value"},
          %{title: ~H"<code>`JS.push`</code>", href: ~p"/guides/js-push"},
          %{title: "Mais de um evento disparado", href: ~p"/guides/multiple-pushes"}
        ]
      },
      %{
        title: "Navegação",
        links: [
          %{title: "Sua segunda LiveView", href: ~p"/guides/your-second-liveview"},
          %{title: "Parâmetros de rotas", href: ~p"/guides/route-params"},
          %{title: "Parâmetros genéricos com query string", href: ~p"/guides/query-string"},
          %{title: "Navegando para a mesma rota", href: ~p"/guides/navigate-to-the-same-route"}
        ]
      },
      %{
        title: "Componentes",
        links: [
          %{title: "Componentes funcionais", href: ~p"/guides/function-component"},
          %{title: "Validando componentes", href: ~p"/guides/documenting-components"},
          %{
            title: "Componentes de outros módulos",
            href: ~p"/guides/components-from-other-modules"
          },
          %{
            title: "Múltiplos slots",
            href: ~p"/guides/multiple-slots"
          },
          %{
            title: "Slots com atributos",
            href: ~p"/guides/slots-with-attributes"
          },
          %{
            title: "Renderizando listas com slots",
            href: ~p"/guides/lists-with-slots"
          }
        ]
      },
      %{
        title: "Formulários",
        links: [
          %{title: "Componente de formulário", href: ~p"/guides/forms"},
          %{title: "Validações", href: ~p"/guides/form-validation"},
          %{title: "Simplificando tudo com Ecto", href: ~p"/guides/simple-forms-with-ecto"}
        ]
      }
    ]
  end
end
