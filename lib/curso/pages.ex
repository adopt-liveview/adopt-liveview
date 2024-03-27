defmodule MarkdownConverter do
  alias CursoWeb.CoreComponents
  import Phoenix.Component
  # import CursoWeb.CoreComponents, only: [callout: 1]

  def convert(filepath, body, _attrs, opts) do
    convert_body(Path.extname(filepath), body, opts)
  end

  defp convert_body(extname, body, opts) when extname in [".md", ".markdown", ".livemd"] do
    html =
      Earmark.as_ast!(body, annotations: "%%")
      |> Earmark.Restructure.walk_and_modify_ast(nil, fn
        {_, [], bits, meta} = item, nil ->
          case Map.get(meta, :annotation) do
            "%% ." <> component ->
              {assigns, _rest} =
                bits
                |> flatten_ast()
                |> Enum.join("")
                |> String.trim()
                |> Code.eval_string([assigns: %{}], __ENV__)

              func = Function.capture(CoreComponents, String.to_atom(component), 1)

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
                |> dbg
                |> Enum.at(1)

              {html, nil}

            _ ->
              {item, nil}
          end

        {:comment, _, _}, acc ->
          {"", acc}

        item, acc ->
          {item, acc}
      end)
      |> Earmark.transform()

    highlighters = Keyword.get(opts, :highlighters, [])
    html |> NimblePublisher.highlight(highlighters)
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
end
