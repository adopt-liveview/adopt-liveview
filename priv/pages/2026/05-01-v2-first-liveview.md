%{
title: "Sua primeira LiveView",
author: "Lubien",
tags: ~w(getting-started),
section: "Introdução",
description: "Como iniciar programando com LiveView?",
previous_page_id: "v2-getting-started",
next_page_id: "v2-anatomy-of-a-liveview"
}

---

## Um passo de cada vez

O framework Phoenix traz consigo várias ferramentas configuradas para você não ter que se preocupar: envio de e-mails, sistema de presença em tempo real, clusterização etc. Por questão de simplicidade vamos aprender essas coisas aos poucos, então fique à vontade para ignorar todos os arquivos gerados pelo framework e vamos focar em criar sua primeira LiveView.

## A LiveView mais básica de todas

Por conveniência, vamos criar uma pasta chamada `live` dentro de `lib/myapp_web` para guardar nossas LiveViews. O comando abaixo resolve isso:

```
mkdir lib/myapp_web/live
```

Em seguida vamos criar nossa primeira LiveView. Com o seu editor favorito, crie um arquivo chamado `page_live.ex` dentro de `lib/myapp_web/live`:


```elixir
# conteúdo do arquivo page_live.ex

defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def render(assigns) do
    ~H"""
    Hello World
    """
  end
end

```

Agora precisamos dizer ao Phoenix onde essa LiveView deve ser renderizada. Abra `lib/myapp_web/router.ex` e procure uma seção parecida com esta:

```elixir
scope "/", MyappWeb do
  pipe_through :browser

  get "/", PageController, :home
end
```

Substitua `get "/", PageController, :home` por `live "/", PageLive, :home` e o seu hello world estará disponível em http://localhost:4000. Seu router deve ficar assim:

```elixir
scope "/", MyappWeb do
  pipe_through :browser

  live "/", PageLive, :home
end
```

## O que eu acabei de escrever?

Criamos um módulo `MyappWeb.PageLive` para ser nossa primeira LiveView e dissemos ao Phoenix para renderizá-la na rota raiz `/`. Como você pode ver bem no topo, usamos `use MyappWeb, :live_view` para torná-la uma LiveView, instalando todo o código necessário nos bastidores — você não precisa se preocupar com isso agora.

Você pode ter notado que tem bastante `MyappWeb` por aí. Isso é porque estamos usando o namespace `MyappWeb` para nossa LiveView. Em projetos Phoenix é muito comum ver que projetos chamados `Project` têm um módulo correspondente `ProjectWeb` para encapsular todo o código relacionado à web.

## Experimente

Tente colocar um pouco de HTML na sua função `render/1`.

## Sucesso!

Agora que você tem um playground de LiveView nas mãos, nos próximos passos vamos entender o que cada pedaço desse código representa.