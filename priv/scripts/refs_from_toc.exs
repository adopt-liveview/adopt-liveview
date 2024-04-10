Curso.Pages.content_map("")
|> Enum.map(& &1.links)
|> List.flatten()
|> Enum.map(&String.replace(&1.href, "/guides/", ""))
|> Enum.map(&String.trim(&1, "/"))
|> Enum.reduce({[], nil, nil}, fn
  id, {xs, nil, nil} ->
    {xs, id, nil}

  id, {xs, prev, nil} ->
    {xs, id, prev}

  next, {xs, id, prev} ->
    item = %{id: id, prev: prev, next: next}
    {xs ++ [item], next, id}
end)
|> elem(0)
|> Enum.map(fn %{id: id, prev: prev, next: next} ->
  """
  #{id}

  ,
  previous_page_id: #{prev && "\"#{prev}\""},
  next_page_id: #{next && "\"#{next}\""}

  """
end)
|> Enum.join("\n\n")
|> IO.puts()

# |> dbg
