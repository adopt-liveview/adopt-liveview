domain = "https://adopt-liveview.lubien.dev"

config = [
  store: Sitemapper.FileStore,
  store_config: [
    path: "priv/static/sitemaps"
  ],
  sitemap_url: "#{domain}/sitemaps"
]

Curso.Pages.all_pages()
|> Stream.map(fn page ->
  %Sitemapper.URL{
    loc: "#{domain}/guides/#{page.id}/#{page.language}",
    lastmod: page.modified_at |> DateTime.to_date()
  }
end)
|> Sitemapper.generate(config)
|> Sitemapper.persist(config)
|> Stream.run()
