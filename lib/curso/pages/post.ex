defmodule Curso.Pages.Post do
  @words_per_minute 200

  @enforce_keys [
    :id,
    :author,
    :title,
    :body,
    :description,
    :tags,
    :date,
    :section,
    :table_of_contents,
    :language,
    :read_minutes,
    :modified_at
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
    :next_page_id,
    :language,
    :read_minutes,
    :modified_at
  ]

  def build(filename, attrs, body) do
    {:ok, document} = Floki.parse_document(body)

    word_count = Floki.text(document) |> String.split(" ") |> Enum.count()
    read_minutes = ceil(word_count / @words_per_minute)

    table_of_contents =
      Floki.find(document, "h1[id],h2[id],h3[id],h4[id],h5[id],h6[id]")
      |> Enum.map(fn {"h" <> number, _, _} = node ->
        [id] = Floki.attribute(node, "id")

        {String.to_integer(number), "##{id}",
         Floki.text(node) |> String.trim() |> String.trim_leading("#")}
      end)

    table_of_contents = [{1, "#", attrs[:title]} | table_of_contents]

    [year, month_day_id] = filename |> Path.rootname() |> Path.split() |> Enum.take(-2)
    [month, day, id] = String.split(month_day_id, "-", parts: 3)
    date = Date.from_iso8601!("#{year}-#{month}-#{day}")

    {id, language} =
      cond do
        String.ends_with?(id, "-en_US") ->
          id = String.replace(id, "-en_US", "")
          {id, "en"}

        true ->
          {id, "br"}
      end

    modified_at =
      File.stat!(filename).mtime
      |> :calendar.datetime_to_gregorian_seconds()
      |> DateTime.from_gregorian_seconds()

    struct!(
      __MODULE__,
      [
        id: id,
        date: date,
        body: body,
        table_of_contents: table_of_contents,
        language: language,
        read_minutes: read_minutes,
        modified_at: modified_at
      ] ++
        Map.to_list(attrs)
    )
  end
end
