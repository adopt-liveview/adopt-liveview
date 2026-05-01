%{
title: "Parâmetros genéricos com query string",
author: "Lubien",
tags: ~w(getting-started),
section: "Navegação",
description: "Recebendo dados variáveis da URL",
previous_page_id: "v2-route-params",
next_page_id: "v2-navigate-to-the-same-route"
}

---

%{
title: "Este guia é uma continuação direta do guia anterior",
type: :warning,
description: ~H"""
Se você chegou diretamente nesta página, pode ser confuso pois ela é uma continuação direta do código da aula anterior. Se quiser pular a aula anterior e começar direto por esta, você pode clonar a versão inicial desta aula usando o comando <code class="select-all">`git clone https://github.com/adopt-liveview/v2-myapp.git --branch your-second-liveview-done`</code>.
"""
} %% .callout

A variável `params` passada ao `mount/3` não se limita a parâmetros no caminho do URL; ela também pode conter dados vindos da query string. Vamos criar uma LiveView simples onde, se o usuário passar a query string `?admin_mode=secret123`, ele pode ver algo exclusivo para admins. Atualize sua `PageLive` para isso:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

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
```

Esta LiveView reutilizou diversas coisas abordadas em aulas anteriores. O principal aqui é o fato de que recebemos o argumento params sem especificar nenhum param em específico. Se o usuário passar uma query string vazia, nosso sistema simplesmente deixará o assign `admin?` como falso. Abra `http://localhost:4000/?admin_mode=secret123` para ver a mensagem do painel de administração.

## Resumindo!

- A variável `params` recebe qualquer coisa na query string em formato chave-valor como `?x=10&y=12`.
- Como a variável `params` é um mapa, podemos usar a sintaxe `params["chave"]` para acessar valores opcionais.