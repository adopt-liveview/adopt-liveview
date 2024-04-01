defmodule Curso.Pages.Post do
  @enforce_keys [
    :id,
    :author,
    :title,
    :body,
    :description,
    :tags,
    :date,
    :section,
    :table_of_contents
  ]
  defstruct [
    :id,
    :author,
    :title,
    :body,
    :description,
    :tags,
    :date,
    :section,
    :table_of_contents,
    :previous_page_id,
    :next_page_id
  ]

  def build(filename, attrs, body) do
    {:ok, document} = Floki.parse_document(body)

    table_of_contents =
      Floki.find(document, "h1[id],h2[id],h3[id],h4[id],h5[id],h6[id]")
      |> Enum.map(fn {"h" <> number, _, _} = node ->
        [id] = Floki.attribute(node, "id")
        {String.to_integer(number), "##{id}", Floki.text(node) |> String.trim()}
      end)

    table_of_contents = [{1, "#", attrs[:title]} | table_of_contents]

    [year, month_day_id] = filename |> Path.rootname() |> Path.split() |> Enum.take(-2)
    [month, day, id] = String.split(month_day_id, "-", parts: 3)
    date = Date.from_iso8601!("#{year}-#{month}-#{day}")

    struct!(
      __MODULE__,
      [id: id, date: date, body: body, table_of_contents: table_of_contents] ++ Map.to_list(attrs)
    )
  end
end
