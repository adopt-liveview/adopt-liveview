defmodule MarkdownConverter do
  import Phoenix.Component

  def convert(filepath, body, _attrs, opts) do
    convert_body(Path.extname(filepath), body, opts)
  end

  defp convert_body(extname, body, opts) when extname in [".md", ".markdown", ".livemd"] do
    html =
      Earmark.as_ast!(body, annotations: "%%")
      |> Earmark.Restructure.walk_and_modify_ast(nil, fn
        {"p", [], [raw_elixir], meta} = item, nil ->
          case Map.get(meta, :annotation) do
            "%% ." <> component ->
              {assigns, []} =
                raw_elixir
                |> String.trim()
                |> Code.eval_string()

              code =
                apply(__MODULE__, String.to_atom(component), [assigns])

              html =
                code
                |> Phoenix.HTML.Safe.to_iodata()
                |> to_string()
                |> Floki.parse_document!()
                |> Floki.traverse_and_update(fn el -> Tuple.append(el, %{}) end)
                |> Enum.at(1)

              {html, nil}

            _ ->
              {item, nil}
          end

        item, acc ->
          {item, acc}
      end)
      |> Earmark.transform()

    highlighters = Keyword.get(opts, :highlighters, [])
    html |> NimblePublisher.highlight(highlighters)
  end

  def tip(assigns) do
    ~H"""
    <div>
      Bem vindo ao <%= @title %>
      <div>b</div>
    </div>
    """
  end
end

defmodule Curso.Pages do
  alias Curso.Pages.Post

  use NimblePublisher,
    build: Post,
    from: Application.app_dir(:curso, "priv/pages/**/*.md"),
    as: :pages,
    html_converter: MarkdownConverter,
    highlighters: [:makeup_elixir, :makeup_erlang]

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
