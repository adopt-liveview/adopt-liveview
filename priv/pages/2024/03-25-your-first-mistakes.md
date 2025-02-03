%{
title: "Seus primeiros erros",
author: "Lubien",
tags: ~w(getting-started),
section: "Fundamentos",
description: "Vamos aprender na base do erro",
previous_page_id: "mount-and-assigns",
next_page_id: "events"
}

---

## Se preparando para os piores cenários

Erros acontecem! Às vezes digitamos algo errado, às vezes esquecemos parte do código que já pensamos em escrever. Apesar de frustrante, exceções no código estão lá para ajudá-lo. Neste guia iremos aprender a tratar algumas dessas exceções para que, ao passar por elas na vida real, você já esteja preparado para enfrentá-las. Esses erros foram escolhidos por serem os mais frequentes entre iniciantes em LiveView, surgindo repetidamente ao longo da jornada de aprendizado.

## Esqueci de adicionar um `assign`!

Vamos criar uma LiveView e esquecer de adicionar um assign no `mount/3` porém, iremos usá-lo na `render/1`. Vamos criar um arquivo chamado `missing_assign.exs` e rodar ele:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    Hello <%= @name %>
    """
  end
end

LiveviewPlayground.start()
```

No seu navegador você deve estar vendo um "Internal Server Error" e, no seu terminal estão aparecendo várias linhas de *error*:

```elixir
08:32:27.589 [error] #PID<0.374.0> running LiveviewPlayground.Endpoint (connection #PID<0.372.0>, stream id 2) terminated
Server: localhost:4000 (http)
Request: GET /
** (exit) an exception was raised:
    ** (KeyError) key :name not found in: %{
  socket: #Phoenix.LiveView.Socket<
    id: "phx-F7_-oDyLb_kqfgAD",
    endpoint: LiveviewPlayground.Endpoint,
    view: PageLive,
    parent_pid: nil,
    root_pid: nil,
    router: LiveviewPlayground.Router,
    assigns: #Phoenix.LiveView.Socket.AssignsNotInSocket<>,
    transport_pid: nil,
    ...
  >,
  __changed__: %{},
  flash: %{},
  live_action: :index
}
        priv/examples/your-first-mistakes/missing_assign.exs:14: anonymous fn/2 in PageLive.render/1
        (phoenix_live_view 0.18.18) lib/phoenix_live_view/diff.ex:398: Phoenix.LiveView.Diff.traverse/7
        (phoenix_live_view 0.18.18) lib/phoenix_live_view/diff.ex:544: anonymous fn/4 in Phoenix.LiveView.Diff.traverse_dynamic/7
        (elixir 1.16.1) lib/enum.ex:2528: Enum."-reduce/3-lists^foldl/2-0-"/3
        (phoenix_live_view 0.18.18) lib/phoenix_live_view/diff.ex:396: Phoenix.LiveView.Diff.traverse/7
        (phoenix_live_view 0.18.18) lib/phoenix_live_view/diff.ex:139: Phoenix.LiveView.Diff.render/3
        (phoenix_live_view 0.18.18) lib/phoenix_live_view/static.ex:252: Phoenix.LiveView.Static.to_rendered_content_tag/4
        (phoenix_live_view 0.18.18) lib/phoenix_live_view/static.ex:135: Phoenix.LiveView.Static.render/3
```

Vamos digerir essa mensagem passo a passo. Aqui, a primeira informação útil é justamente a primeira linha de erro:

```elixir
08:32:27.589 [error] #PID<0.374.0> running LiveviewPlayground.Endpoint (connection #PID<0.372.0>, stream id 2) terminated
```

Ela indica que a conexão com a LiveView do seu usuário foi terminada subtamente pois o processo que continha a view morreu. Ou seja, faz sentido o erro ser *Internal Server Error* pois algo não foi tratado pelo programador que fez a LiveView. A próxima informação de extrema importância está justamente na exceção que fez sua LiveView morrer (ou seja, causar um `exit`):

```elixir
** (exit) an exception was raised:
    ** (KeyError) key :name not found in: %{
  socket: #Phoenix.LiveView.Socket<
    id: "phx-F7_-oDyLb_kqfgAD",
    endpoint: LiveviewPlayground.Endpoint,
    view: PageLive,
    parent_pid: nil,
    root_pid: nil,
    router: LiveviewPlayground.Router,
    assigns: #Phoenix.LiveView.Socket.AssignsNotInSocket<>,
    transport_pid: nil,
    ...
  >,
  __changed__: %{},
  flash: %{},
  live_action: :index
}
```

Em Elixir uma `KeyError` significa que em um dado momento você tinha um mapa e tentou acessar uma chave que não existe nele no formato `mapa.chave_inexistente`. Vale lembrar que na nossa `render/1` fizemos `@name`, que é o mesmo que `assigns.name`. Portanto, faz sentido ter sido uma `KeyError`. Para deixar a mensagem de erro acima ainda mais clara, podemos simplificá-la como:

```elixir
** (exit) an exception was raised:
    ** (KeyError) key :name not found in: %{
  socket: %Phoenix.LiveView.Socket{},
  __changed__: %{},
  flash: %{},
  live_action: :index
}
```

Lembra quando na aula anterior, nós falamos o que um `socket` tem? Ele tem `flash`, `__changed__` e `live_action`. Apesar da exceção não ter sido extremamente óbvia podemos interpretar que isso é a falta de um `assign`. Porém, imagine que você tem um projeto LiveView gigante. Como encontrar onde está faltando este *assign*? Vamos olhar no `stack trace`.

```elixir
priv/examples/your-first-mistakes/missing_assign.exs:14: anonymous fn/2 in PageLive.render/1
(phoenix_live_view 0.18.18) lib/phoenix_live_view/diff.ex:398: Phoenix.LiveView.Diff.traverse/7
(phoenix_live_view 0.18.18) lib/phoenix_live_view/diff.ex:544: anonymous fn/4 in Phoenix.LiveView.Diff.traverse_dynamic/7
(elixir 1.16.1) lib/enum.ex:2528: Enum."-reduce/3-lists^foldl/2-0-"/3
(phoenix_live_view 0.18.18) lib/phoenix_live_view/diff.ex:396: Phoenix.LiveView.Diff.traverse/7
(phoenix_live_view 0.18.18) lib/phoenix_live_view/diff.ex:139: Phoenix.LiveView.Diff.render/3
(phoenix_live_view 0.18.18) lib/phoenix_live_view/static.ex:252: Phoenix.LiveView.Static.to_rendered_content_tag/4
(phoenix_live_view 0.18.18) lib/phoenix_live_view/static.ex:135: Phoenix.LiveView.Static.render/3
```

Um `stack trace` serve para demonstrar a cadeira de execução de funções até chegar na exceção que o seu código gerou. Cada linha tem o formato `(nome_da_dependencia versao) pasta/nome_do_arquivo:linha: NomeDoModulo.nome_da_funcao/aridade`. Ser capaz de ler *stack traces* vai tornar seu dia-a-dia como programador muito mais simples. Aqui vai a primeira dica de como descobrir onde está o problema do código: ignore todas as linhas que são de bibliotecas (aquelas que começam como parênteses). Com isso nos resta:

```elixir
priv/examples/your-first-mistakes/missing_assign.exs:14: anonymous fn/2 in PageLive.render/1
```

Interpretando o *trace* que nos resta:

- No arquivo `priv/examples/your-first-mistakes/missing_assign.exs`.
- Na linha `14`.
- Temos uma função anônima que recebe dois argumentos (`anonymous fn/2`).
- Rodando dentro da função PageLive.render que recebe um argumento (`PageLive.render/1`).

O que existe na linha 14 desse arquivo? `Hello <%= @name %>`.

Diagnóstico: o assigns `name` não existe.

Solução: adicionar ele ao nosso `mount/3`:

```elixir
def mount(_params, _session, socket) do
  socket = assign(socket, name: "Mundo")
  {:ok, socket}
end
```

%{
title: ~H"O que era aquele <code>`anonymous fn/2`</code>?",
description: ~H"""
Lembra que usamos as tags <code>`&lt;%= %&gt;`</code> para interpolar código? O seu <code>`@name`</code> está dentro da função anônima de interpolação, algo interno do LiveView. O importante mesmo era saber o arquivo + linha + função.
"""
} %% .callout

## Imutabilidade

Vamos criar um novo arquivo chamado `immutable.exs` dessa forma:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def mount(_params, _session, socket) do
    assign(socket, name: "Immutable")
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    Hello <%= @name %>
    """
  end
end

LiveviewPlayground.start()
```

Você consegue identificar o erro? Execute o arquivo com `elixir immutable.exs` e abra sua página. Você verá o mesmo `KeyError` que relatamos anteriormente. Desta vez fizemos o *assign* do `name`. Por que não funciona?

Para entender este problema precisamos brevemente falar sobre imutabilidade. Em Elixir você não pode modificar variáveis. Veja o seguinte exemplo:

```elixir
person = %{name: "Lubien"}
Map.put(person, :name, "João")
dbg(person) # Continua %{name: "Lubien"}
```

Isso acontece pois, diferente de linguagens de programação com valores mutáveis (como JavaScript), os dados em Elixir são imutáveis. Você não pode modificar um mapa existente, porém você pode criar um mapa novo com uma modificação específica.

```elixir
person = %{name: "Lubien"}
person = Map.put(person, :name, "João")
dbg(person) # %{name: "João"}
```

Neste caso, criamos um segundo mapa e atribuímos esse valor ao identificador `person`. Se modificar um dado, você provavelmente vai querer armazenar a modificação na original ou em outra. Voltando a nossa LiveView, o código com problema está justamente aqui:

```elixir
assign(socket, name: "Immutable")
{:ok, socket}
```

A solução é bem simples. Assim como Map.put retorna um novo mapa com o dado novo, a função `assign/2` retorna um novo *socket* com o *assign* adicionado:

```elixir
socket = assign(socket, name: "Immutable")
{:ok, socket}
```

## Resumindo

- Caso veja um `KeyError` dizendo que não foi possível acessar uma propriedade de um mapa que possui `live_action`, `socket` e `flash`, suspeite que você esqueceu de fazer um *assign*.
- Lembre-se que Elixir é uma linguagem de programação imutável, protanto você precisa armazenar o resultado de chamadas de função em algum lugar.
