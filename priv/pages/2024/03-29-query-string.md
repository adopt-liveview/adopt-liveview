%{
title: "Parâmetros genéricos com query string",
author: "Lubien",
tags: ~w(getting-started),
section: "Navegação",
description: "Recebendo dados do URL sem saber quais são",
previous_page_id: "route-params",
next_page_id: "navigate-to-the-same-route"
}

---

A variável `params` passada ao `mount/3` não se limita a parâmetros no caminho do URL, ela também pode conter dados vindo da query string. Vamos criar uma LiveView simples em que se o usuário passar a query string `?admin_mode=secret123` ele pode ver algo só para admins. Crie e execute `query_string.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.3"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(params, _session, socket) do
    admin? = params["admin_mode"] == "secret123"
    socket = assign(socket, :admin?, admin?)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <h1>Welcome to my Website!</h1>
    <.link :if={@admin?} navigate={~p"/admin"}>Go to admin panel</.link>
    """
  end
end

LiveviewPlayground.start()
```

Esta LiveView reutilizou diversas coisas abordadas em aulas anteriores. O principal aqui é o fato de que recebemos a variável params sem especificar nenhum param em específico. Deste modo, se o usuário passar uma query string vazia nosso sistema simplesmente deixará o assign `admin?` como falso.

## Resumindo!

- A variável `params` recebe qualquer coisa na query string em formato chave-valor como `?x=10&y=12`.
- Como a variável `params` é um mapa podemos usar a sintaxe `params["chave"]` para acessar valores opcionais.
