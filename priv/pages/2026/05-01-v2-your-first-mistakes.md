%{
title: "Seus primeiros erros",
author: "Lubien",
tags: ~w(getting-started),
section: "Fundamentos",
description: "Vamos aprender na base do erro",
previous_page_id: "v2-mounts-and-assigns",
next_page_id: "v2-events"
}

---

%{
title: "Este guia é uma continuação direta do guia anterior",
type: :warning,
description: ~H"""
Se você caiu diretamente nessa página pode ser confuso pois ela é uma continuação direta do código da aula anterior. Se quiser pular a aula anterior e começar direto por esta, você pode clonar a versão inicial desta aula usando o comando <code class="select-all">`git clone https://github.com/adopt-liveview/v2-myapp.git --branch mounts-and-assigns-done`</code>.
"""
} %% .callout

## Se preparando para os piores cenários

Erros acontecem! Às vezes digitamos algo errado, às vezes esquecemos parte do código que já pensamos em escrever. Apesar de frustrante, exceções no código estão lá para lhe ajudar. Neste guia iremos aprender a tratar algumas dessas exceções para que quando você passe por elas na vida real você já esteja blindado. Escolhi esses erros e decidi por eles tão cedo neste curso pois são erros que os iniciantes em LiveView que eu auxiliei passaram por eles múltiplas vezes.

## Esqueci de adicionar um `assign`!

Vamos voltar ao `page_live.ex` e esquecer de adicionar um assign no `mount/3` porém vamos usá-lo na `render/1`:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def mount(_params, _session, socket) do
    # Ops, esqueci de fazer esse assign
    # socket = assign(socket, name: "Lubien")
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    Hello {@name}
    """
  end
end

```

Em produção seu usuário estaria vendo um "Internal Server Error" e no seu terminal várias linhas de erro devem aparecer:

```elixir
[info] Sent 500 in 22ms
[error] ** (KeyError) key :name not found in:

    %{
      socket: #Phoenix.LiveView.Socket<
        id: "phx-GHzLG4kXVF0LYQUC",
        endpoint: MyappWeb.Endpoint,
        view: MyappWeb.PageLive,
        parent_pid: nil,
        root_pid: nil,
        router: MyappWeb.Router,
        assigns: #Phoenix.LiveView.Socket.AssignsNotInSocket<>,
        transport_pid: nil,
        sticky?: false,
        ...
      >,
      __changed__: %{},
      flash: %{},
      live_action: :home
    }

    (myapp 0.1.0) lib/myapp_web/live/page_live.ex:12: anonymous fn/2 in MyappWeb.PageLive.render/1
    (phoenix_live_view 1.1.16) lib/phoenix_live_view/diff.ex:420: Phoenix.LiveView.Diff.traverse/6
    (phoenix_live_view 1.1.16) lib/phoenix_live_view/diff.ex:146: Phoenix.LiveView.Diff.render/4
    (phoenix_live_view 1.1.16) lib/phoenix_live_view/static.ex:291: Phoenix.LiveView.Static.to_rendered_content_tag/4
    (phoenix_live_view 1.1.16) lib/phoenix_live_view/static.ex:171: Phoenix.LiveView.Static.do_render/4
    (phoenix_live_view 1.1.16) lib/phoenix_live_view/controller.ex:39: Phoenix.LiveView.Controller.live_render/3
    (phoenix 1.8.1) lib/phoenix/router.ex:416: Phoenix.Router.__call__/5
    (myapp 0.1.0) lib/myapp_web/endpoint.ex:1: MyappWeb.Endpoint.plug_builder_call/2
    (myapp 0.1.0) deps/plug/lib/plug/debugger.ex:155: MyappWeb.Endpoint."call (overridable 3)"/2
    (myapp 0.1.0) lib/myapp_web/endpoint.ex:1: MyappWeb.Endpoint.call/2
    (phoenix 1.8.1) lib/phoenix/endpoint/sync_code_reload_plug.ex:22: Phoenix.Endpoint.SyncCodeReloadPlug.do_call/4
    (bandit 1.8.0) lib/bandit/pipeline.ex:131: Bandit.Pipeline.call_plug!/2
    (bandit 1.8.0) lib/bandit/pipeline.ex:42: Bandit.Pipeline.run/5
    (bandit 1.8.0) lib/bandit/http1/handler.ex:13: Bandit.HTTP1.Handler.handle_data/3
    (bandit 1.8.0) lib/bandit/delegating_handler.ex:18: Bandit.DelegatingHandler.handle_data/3
    (bandit 1.8.0) lib/bandit/delegating_handler.ex:8: Bandit.DelegatingHandler.handle_continue/2
    (stdlib 7.0.1) gen_server.erl:2424: :gen_server.try_handle_continue/3
    (stdlib 7.0.1) gen_server.erl:2291: :gen_server.loop/4
    (stdlib 7.0.1) proc_lib.erl:333: :proc_lib.init_p_do_apply/3
```

Vamos digerir essa mensagem passo a passo! A primeira informação útil aqui é justamente a primeira linha de erro:

```elixir
[info] Sent 500 in 22ms
```

Ela indica que a conexão com a LiveView do seu usuário foi terminada subitamente pois o processo que continha a view morreu. Ou seja, faz sentido o erro ser "Internal Server Error" pois algo não foi tratado pelo programador que fez a LiveView. A próxima informação de extrema importância está justamente na exceção que fez sua LiveView morrer:

```elixir
[error] ** (KeyError) key :name not found in:

    %{
      socket: #Phoenix.LiveView.Socket<
        id: "phx-GHzLG4kXVF0LYQUC",
        endpoint: MyappWeb.Endpoint,
        view: MyappWeb.PageLive,
        parent_pid: nil,
        root_pid: nil,
        router: MyappWeb.Router,
        assigns: #Phoenix.LiveView.Socket.AssignsNotInSocket<>,
        transport_pid: nil,
        sticky?: false,
        ...
      >,
      __changed__: %{},
      flash: %{},
      live_action: :home
    }
```

Em Elixir uma `KeyError` significa que em dado momento você tinha um mapa e tentou acessar uma chave que não existe nele como em `meu_mapa.chave_inexistente`. Lembrando que na nossa `render/1` usamos `@name` que é o mesmo que `assigns.name`, faz sentido ter sido uma `KeyError`. Para deixar a mensagem de erro acima ainda mais clara, podemos simplificá-la assim:

```elixir
[error] ** (KeyError) key :name not found in:

    %{
      socket: #Phoenix.LiveView.Socket<>,
      __changed__: %{},
      flash: %{},
      live_action: :home
    }
```

Lembra quando falamos o que um `socket` tem na aula anterior? Eles têm `flash`, `__changed__` e `live_action`. Apesar da exceção não ter sido extremamente óbvia, podemos interpretar que isso é a falta de um assign. Porém imagine que você tem um projeto LiveView gigante. Como encontrar onde está faltando este assign? Vamos olhar no `stack trace`.

```elixir
(myapp 0.1.0) lib/myapp_web/live/page_live.ex:12: anonymous fn/2 in MyappWeb.PageLive.render/1
(phoenix_live_view 1.1.16) lib/phoenix_live_view/diff.ex:420: Phoenix.LiveView.Diff.traverse/6
(phoenix_live_view 1.1.16) lib/phoenix_live_view/diff.ex:146: Phoenix.LiveView.Diff.render/4
(phoenix_live_view 1.1.16) lib/phoenix_live_view/static.ex:291: Phoenix.LiveView.Static.to_rendered_content_tag/4
(phoenix_live_view 1.1.16) lib/phoenix_live_view/static.ex:171: Phoenix.LiveView.Static.do_render/4
(phoenix_live_view 1.1.16) lib/phoenix_live_view/controller.ex:39: Phoenix.LiveView.Controller.live_render/3
(phoenix 1.8.1) lib/phoenix/router.ex:416: Phoenix.Router.__call__/5
(myapp 0.1.0) lib/myapp_web/endpoint.ex:1: MyappWeb.Endpoint.plug_builder_call/2
(myapp 0.1.0) deps/plug/lib/plug/debugger.ex:155: MyappWeb.Endpoint."call (overridable 3)"/2
(myapp 0.1.0) lib/myapp_web/endpoint.ex:1: MyappWeb.Endpoint.call/2
(phoenix 1.8.1) lib/phoenix/endpoint/sync_code_reload_plug.ex:22: Phoenix.Endpoint.SyncCodeReloadPlug.do_call/4
(bandit 1.8.0) lib/bandit/pipeline.ex:131: Bandit.Pipeline.call_plug!/2
(bandit 1.8.0) lib/bandit/pipeline.ex:42: Bandit.Pipeline.run/5
(bandit 1.8.0) lib/bandit/http1/handler.ex:13: Bandit.HTTP1.Handler.handle_data/3
(bandit 1.8.0) lib/bandit/delegating_handler.ex:18: Bandit.DelegatingHandler.handle_data/3
(bandit 1.8.0) lib/bandit/delegating_handler.ex:8: Bandit.DelegatingHandler.handle_continue/2
(stdlib 7.0.1) gen_server.erl:2424: :gen_server.try_handle_continue/3
(stdlib 7.0.1) gen_server.erl:2291: :gen_server.loop/4
(stdlib 7.0.1) proc_lib.erl:333: :proc_lib.init_p_do_apply/3
```

Um `stack trace` serve para demonstrar a cadeia de chamadas de funções até chegar na exceção do seu código. Cada linha tem o formato `(nome_da_dependencia versao) pasta/nome_do_arquivo:linha: NomeDoModulo.nome_da_funcao/aridade`. Ser capaz de ler stack traces vai tornar seu dia-a-dia como programador muito mais simples. Aqui vai a primeira dica de como descobrir onde está o problema: ignore todas as linhas que são de bibliotecas (aquelas que começam com parênteses e o nome não é o seu projeto). Com isso nos resta:

```elixir
(myapp 0.1.0) lib/myapp_web/live/page_live.ex:12: anonymous fn/2 in MyappWeb.PageLive.render/1
# ...
(myapp 0.1.0) lib/myapp_web/endpoint.ex:1: MyappWeb.Endpoint.plug_builder_call/2
(myapp 0.1.0) deps/plug/lib/plug/debugger.ex:155: MyappWeb.Endpoint."call (overridable 3)"/2
(myapp 0.1.0) lib/myapp_web/endpoint.ex:1: MyappWeb.Endpoint.call/2
```

Interpretando o trace que nos resta:

- No arquivo `lib/myapp_web/live/page_live.ex`.
- Na linha `12`.
- Temos uma função anônima que recebe dois argumentos (`anonymous fn/2`).
- Rodando dentro da função PageLive.render que recebe um argumento (`PageLive.render/1`).

O que existe na linha 12 desse arquivo? `Hello {@name}`. Diagnóstico: o assign `name` não existe. Solução: adicioná-lo ao nosso `mount/3`:

```elixir
def mount(_params, _session, socket) do
  socket = assign(socket, name: "Mundo")
  {:ok, socket}
end
```

%{
title: ~H"O que era aquele <code>`anonymous fn/2`</code>?",
description: ~H"""
Lembra que usamos as tags <code>`{}`</code> para interpolar código? O seu <code>`@name`</code> está dentro da função anônima de interpolação. Isso é algo interno do LiveView, o importante mesmo era saber o arquivo + linha + função.
"""
} %% .callout

## Imutabilidade

Vamos atualizar o `page_live.ex` temporariamente assim:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def mount(_params, _session, socket) do
    assign(socket, name: "Lubien")
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    Hello {@name}
    """
  end
end
```

Você consegue identificar o erro? Abra sua página. Você verá o mesmo `KeyError` que conversamos anteriormente. Desta vez fizemos o assign do `name`, não deveria funcionar?

Para entender esse problema precisamos falar brevemente sobre imutabilidade. Em Elixir você não pode modificar variáveis. Veja o seguinte exemplo:

```elixir
person = %{name: "Lubien"}
Map.put(person, :name, "João")
dbg(person) # Continua %{name: "Lubien"}
```

Isso acontece pois, diferente de linguagens de programação com valores mutáveis (como JavaScript), os dados em Elixir são imutáveis. Você não pode modificar um mapa existente, mas pode criar um mapa novo com alguma modificação.

```elixir
person = %{name: "Lubien"}
person = Map.put(person, :name, "João")
dbg(person) # %{name: "João"}
```

Neste caso, criamos um segundo mapa e atribuímos seu valor ao identificador `person`. Se você modificar um dado, provavelmente vai querer armazenar a modificação na original ou em outra variável. Voltando à nossa LiveView, o código com problema está justamente aqui:

```elixir
assign(socket, name: "Immutable")
{:ok, socket}
```

A solução é bem simples. Assim como `Map.put` retorna um novo mapa com o dado novo, a função `assign/2` retorna um novo socket com o assign adicionado:

```elixir
socket = assign(socket, name: "Immutable")
{:ok, socket}
```

## Resumindo

- Se você ver um `KeyError` dizendo que não foi possível acessar uma propriedade de um mapa que possui `live_action`, `socket` e `flash`, suspeite que você esqueceu de fazer um assign.
- Lembre-se que Elixir é uma linguagem de programação imutável, então você precisa armazenar o resultado das chamadas de função em algum lugar.