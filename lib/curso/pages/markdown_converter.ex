defmodule Pages.MarkdownConverter do
  alias CursoWeb.CoreComponents
  import Phoenix.Component, warn: false

  def convert(filepath, body, _attrs, opts) do
    convert_body(Path.extname(filepath), body, opts)
  end

  defp convert_body(extname, body, opts) when extname in [".md", ".markdown", ".livemd"] do
    handler = fn
      {"pre", [], _texts, %{done?: true}} = pre, nil ->
        {pre, nil}

      {"pre", [], texts, meta}, nil ->
        code_block_id = Ecto.UUID.generate() |> String.replace("-", "")

        attrs =
          [
            {"id", code_block_id},
            {"class", "relative"},
            {"style", "overflow: visible"},
            {"phx-update", "ignore"}
          ]

        copy_button =
          component_to_ast(&CoreComponents.copy_button/1, %{
            id: "#{code_block_id}button",
            selector: "[id=\"#{code_block_id}\"] code"
          })

        children = [
          {"pre", [], texts, Map.put(meta, :done?, true)},
          copy_button
        ]

        wrapper = {"div", attrs, children, %{}}
        {wrapper, nil}

      {"h1", _inner, texts, meta}, nil ->
        {{"h1", [{"id", anchor_id(texts)}], texts, meta}, nil}

      {"h" <> x, _inner, texts, meta}, nil when x in ~w(2 3 4 5 6) ->
        anchor_link =
          {"a", [{"href", "#" <> anchor_id(texts)}, {"class", "mdx-header-anchor"}], ["#"], %{}}

        {{"h#{x}", [{"id", anchor_id(texts)}], [anchor_link | texts], meta}, nil}

      {_, [], bits, meta} = item, nil ->
        case Map.get(meta, :annotation) do
          "%% ." <> component ->
            {assigns, _rest} =
              bits
              |> flatten_ast()
              |> Enum.join("")
              |> String.trim()
              |> Code.eval_string([assigns: %{}], __ENV__)

            html =
              component_to_ast(
                Function.capture(CoreComponents, String.to_atom(component), 1),
                assigns
              )

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

    highlighters =
      Keyword.get(opts, :highlighters, [])

    html
    |> NimblePublisher.highlight(highlighters)
  end

  defp component_to_ast(component, assigns) do
    code =
      Phoenix.LiveView.TagEngine.component(
        component,
        Map.to_list(assigns),
        {__ENV__.module, __ENV__.function, __ENV__.file, __ENV__.line}
      )

    code
    |> Phoenix.HTML.Safe.to_iodata()
    |> to_string()
    |> Floki.parse_document!()
    |> Floki.traverse_and_update(fn
      {el, attrs, texts} when is_list(attrs) ->
        attrs =
          for {key, val} <- attrs do
            val =
              Phoenix.HTML.attributes_escape(x: val)
              |> Phoenix.HTML.safe_to_string()
              |> then(fn str ->
                String.slice(str, String.length(" x=")..String.length(str))
                |> String.trim()
                |> String.trim("\"")
              end)

            {key, val}
          end

        {el, attrs, texts, %{}}

      el ->
        Tuple.append(el, %{})
    end)
    |> Enum.find(fn
      {:comment, _, _} -> false
      _ -> true
    end)
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

  defdelegate callout(assigns), to: CursoWeb.CoreComponents
end
