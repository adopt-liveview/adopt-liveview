domain = "https://adopt-liveview.lubien.dev"

config = [
  store: Sitemapper.FileStore,
  store_config: [
    path: "priv/static/sitemaps"
  ],
  sitemap_url: "#{domain}/sitemaps"
]

home_urls =
  Stream.map(["/", "/en", "/br"], fn path ->
    %Sitemapper.URL{
      loc: "#{domain}#{path}",
      lastmod: Date.utc_today()
    }
  end)

guide_urls =
  Curso.Pages.all_pages()
  |> Stream.map(fn page ->
    %Sitemapper.URL{
      loc: "#{domain}/guides/#{page.id}/#{page.language}",
      lastmod: page.modified_at |> DateTime.to_date()
    }
  end)

Stream.concat(home_urls, guide_urls)
|> Sitemapper.generate(config)
|> Sitemapper.persist(config)
|> Stream.run()
