Curso.Pages.content_map("")
|> Enum.map(& &1.links)
|> List.flatten()
|> Enum.map(&String.replace(&1.href, "/guides/", ""))
|> Enum.map(&String.trim(&1, "/"))
|> Enum.map(&"- [ ] #{&1}")
|> Enum.join("\n")
|> IO.puts()

# |> dbg
