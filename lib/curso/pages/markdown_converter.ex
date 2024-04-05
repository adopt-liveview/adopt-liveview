defmodule Pages.MarkdownConverter do
  alias CursoWeb.CoreComponents
  import Phoenix.Component
  # import CursoWeb.CoreComponents, only: [callout: 1]

  def convert(filepath, body, _attrs, opts) do
    convert_body(Path.extname(filepath), body, opts)
  end

  defp convert_body(extname, body, opts) when extname in [".md", ".markdown", ".livemd"] do
    handler = fn
      {"h" <> x, _inner, texts, meta}, nil when x in ~w(1 2 3 4 5 6) ->
        {{"h#{x}", [{"id", anchor_id(texts)}], texts, meta}, nil}

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

  defp anchor_id(items) when is_list(items) do
    Enum.map(items, fn
      {"code", _attrs, texts, _meta} ->
        [texts]

      str when is_binary(str) ->
        [str]
    end)
    |> List.flatten()
    |> Floki.text()
    |> anchor_id()
  end

  defp anchor_id(str) when is_binary(str) do
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
