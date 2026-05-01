%{
title: "Básico de HEEx",
author: "Lubien",
tags: ~w(getting-started),
section: "HEEx",
description: "Aprenda como HEEx entende HTML de uma forma diferente",
previous_page_id: "v2-heex-is-not-html",
next_page_id: "v2-conditional-rendering"
}

---

%{
title: "Este guia é uma continuação direta do guia anterior",
type: :warning,
description: ~H"""
Se você chegou diretamente nessa página, pode ficar confuso porque é uma continuação direta do código da aula anterior. Se quiser pular a aula anterior e começar direto por aqui, você pode clonar a versão inicial desta aula com o comando <code class="select-all">`git clone https://github.com/adopt-liveview/v2-myapp.git --branch events-done`</code>.
"""
} %% .callout

Para facilitar o seu futuro no LiveView, vamos aprender algumas coisas simples sobre o funcionamento do HEEx que vão tornar seu dia a dia mais produtivo.

## Renderização de Elixir

Vamos atualizar o `page_live.ex` para isso:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def render(assigns) do
    ~H"""
    <h2>Hello {"Lubien"}</h2>
    <h2>Hello {1 + 1}</h2>
    <h2>Hello {"Chris" <> " " <> "McCord"}</h2>
    <h2>Hello <% "King Crimson" |> IO.puts() %></h2>
    """
  end
end
```

Neste arquivo temos 3 interpolações HEEx e uma tag no nosso código. HEEx dá suporte a renderizar qualquer tipo de código que implemente o protocolo [`Phoenix.HTML.Safe`](https://hexdocs.pm/phoenix_html/Phoenix.HTML.Safe.html).

- O primeiro caso renderiza a string `"Lubien"`.
- O segundo caso renderiza o inteiro 2.
- O terceiro caso apenas usa o operador de concatenar strings [`<>`](https://hexdocs.pm/elixir/1.12/Kernel.html#%3C%3E/2) cujo resultado é "Chris McCord".

Mas e o quarto caso? Nada aparece na sua tela. O motivo é simples: usamos a tag `<% %>`, note que não existe um `=` após o primeiro `%`. Em HEEx isso significa "execute este código mas não renderize o resultado". Como ele utiliza a função [`IO.puts/2`](https://hexdocs.pm/elixir/1.12/IO.html#puts/2), você consegue ver o resultado no seu terminal.

%{
title: "Então eu posso adicionar lógica ao meu HEEx!",
type: :warning,
description: ~H"""
A resposta direta é sim, você pode, porém isso significa que sua lógica será executada toda vez que o HEEx for recalculado quando algum assign mudar. <.link navigate="https://hexdocs.pm/phoenix_live_view/assigns-eex.html#common-pitfalls" target="\_blank">A recomendação do time do Phoenix</.link> é que você faça qualquer lógica em assigns para evitar possíveis problemas de performance. No futuro aprenderemos outros modos de ter lógica no seu HEEx de forma eficiente.
"""
} %% .callout

## Renderizando algo que não pode ser convertido em string

Agora vamos tentar isso:

```elixir
defmodule User do
  defstruct id: nil, name: nil
end

defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def render(assigns) do
    ~H"""
    <h2>Hello {%User{id: 1, name: "Lubien"}}</h2>
    """
  end
end
```

Você vai notar um "Internal Server Error" e a exceção no seu terminal:

```elixir
[info] GET /
[debug] Processing with MyappWeb.PageLive.__live__/0
  Parameters: %{}
  Pipelines: [:browser]
[info] Sent 500 in 50ms
[error] ** (Protocol.UndefinedError) protocol Phoenix.HTML.Safe not implemented for User (a struct). This protocol is implemented for: Atom, BitString, Date, DateTime, Decimal, Duration, Float, Integer, List, NaiveDateTime, Phoenix.LiveComponent.CID, Phoenix.LiveView.Component, Phoenix.LiveView.Comprehension, Phoenix.LiveView.JS, Phoenix.LiveView.Rendered, Time, Tuple, URI

Got value:

    %User{id: 1, name: "Lubien"}

    (phoenix_html 4.3.0) lib/phoenix_html/safe.ex:1: Phoenix.HTML.Safe.impl_for!/1
    (phoenix_html 4.3.0) lib/phoenix_html/safe.ex:15: Phoenix.HTML.Safe.to_iodata/1
    (myapp 0.1.0) lib/myapp_web/live/page_live.ex:10: anonymous fn/2 in MyappWeb.PageLive.render/1
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
```

Como mencionado anteriormente, o protocolo `Phoenix.HTML.Safe` é necessário para renderizarmos dados do Elixir. O motivo pelo qual esse protocolo existe é que o time do Phoenix converte o dado original do Elixir em uma estrutura chamada `iodata`, que é mais eficiente para ser enviada ao usuário.

Se você quiser apenas fazer um debug rápido de um dado que não pode ser renderizado pelo HEEx, a recomendação seria usar inspect: `<h2>Hello {inspect(%User{id: 1, name: "Lubien"})}</h2>`. Se você realmente precisar ensinar o HEEx a interpretar seu struct, pode também implementar o protocolo você mesmo. Atualizando o exemplo anterior:

```elixir
defmodule User do
  defstruct id: nil, name: nil
end

defimpl Phoenix.HTML.Safe, for: User do
  def to_iodata(user) do
    "User #{user.id} is named #{user.name}"
  end
end

defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def render(assigns) do
    ~H"""
    <h2>Hello {%User{id: 1, name: "Lubien"}}</h2>
    """
  end
end
```

Usando [`defimpl/3`](https://hexdocs.pm/elixir/1.14/Kernel.html#defimpl/3) conseguimos definir o callback `to_iodata/1` do protocolo e converter o usuário para string (algo que HEEx consegue renderizar).

Vale mencionar que se você decidir retornar qualquer tipo de HTML aqui, você fica responsável por garantir que não existe nenhuma vulnerabilidade como [XSS](https://owasp.org/www-community/attacks/xss/). Imagine se seu usuário tem um nome com `<svg onload=alert(1)>` e você não escapou esse dado? Portanto, evite esta prática sempre que possível.

## Renderização de `nil`

Vamos simplificar nosso código para apenas isso:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def render(assigns) do
    ~H"""
    <h2>Hello {"Lubien"}</h2>
    <h2>Hello {nil}</h2>
    """
  end
end

```

Neste cenário vemos que quando a interpolação `{}` recebe `nil` o resultado é não renderizar absolutamente nada. Isso será útil logo mais!

## Renderização de atributos HTML

Agora tente isto:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def render(assigns) do
    bg_for_hello_phoenix = "bg-black"
    multiple_attributes = %{style: "color: yellow", class: "bg-black"}

    ~H"""
    <style>
      .color-red { color: red }
      .bg-black { background-color: black }
      .bg-red { background-color: red }
    </style>

    <h2 style="color: red" class="bg-black">Hello World</h2>
    <h2 style="color: white" class={"bg-" <> "red"}>Hello Elixir</h2>
    <h2 class={[bg_for_hello_phoenix, nil, "color-red"]}>Hello Phoenix</h2>
    <h2 {multiple_attributes}>Hello LiveView</h2>
    """
  end
end
```

Existem múltiplas maneiras de adicionar atributos HTML em HEEx para a conveniência do desenvolvedor. Vamos verificar cada um deles.

No primeiro caso (Hello World) adicionamos `style="color: red"` que funciona como qualquer outro HTML no mundo. Neste formato não há nenhum tipo de processamento extra. Em `class={"bg-black"}`, ao usar chaves estamos dizendo que o conteúdo dentro delas é um código Elixir. Qualquer código Elixir como `class={calculate_class()}` (supondo que a função exista) ou `class={"bg-#{@my_background}"}` (supondo que o assign exista) será válido!

No segundo caso (Hello Elixir) apenas demonstramos mais uma vez o que foi explicado no caso anterior. Em `class={"bg-" <> "red"}` pode-se notar um exemplo de usar o operador `<>` para calcular a classe final.

No terceiro exemplo (Hello Phoenix) existe uma dica de ouro: você pode passar uma lista com múltiplas strings para um atributo e ao final ela será automaticamente unida, e os valores que forem `nil` serão ignorados. O motivo que torna essa técnica poderosa é que facilita trabalhar com variáveis, como podemos ver a `bg_for_hello_phoenix` sendo utilizada.

O último caso (Hello LiveView) adiciona mais uma forma de trabalhar com atributos. Se você precisar algum dia adicionar atributos de modo dinâmico, isto é, você não sabe exatamente quais atributos vão ou não entrar de antemão, pode usar a sintaxe de adicionar um mapa do Elixir dentro da tag de abertura do HTML e o HEEx vai entender que cada chave do mapa representa um atributo.

%{
title: "Posso usar variáveis na minha render function?",
description: ~H"""
Sim, não há problema em simplesmente adicionar variáveis antes do seu HEEx, especialmente se você fizer isso apenas para deixar o código mais legível (imagine que você tem uma quantidade absurda de classes, por exemplo), mas você verá warnings dizendo que a recomendação oficial é transformar essas variáveis em assigns. Em aulas futuras aprenderemos como fazer isso de uma maneira bem simples e legível.
"""
} %% .callout

## Uma observação sobre uma sintaxe antiga

Antes das interpolações como `{this}` existirem, a forma padrão do HEEx renderizar coisas em HTML era a tag `<%= this %>`. Similar à tag `<% %>` (que não renderiza), esta vem com um `=`. Hoje em dia, se você usar formatadores em projetos novos, elas serão automaticamente convertidas para interpolações a menos que se enquadrem em [casos específicos](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#sigil_H/2-interpolating-blocks). Ainda vamos usar `<%= %>` no futuro para estruturas de controle!

## Resumindo!

- Usar a tag `{}` renderiza código Elixir que o protocolo `Phoenix.HTML.Safe` aceita.
- Usar a tag `<% %>` apenas executa código Elixir e não renderiza nada.
- Você pode implementar `Phoenix.HTML.Safe` para structs, mas deve estar ciente dos riscos de segurança que isso pode trazer.
- HEEx considera `nil` como algo que não deve ser renderizado; isso é útil caso você queira trabalhar com variáveis opcionais.
- Em HEEx, atributos HTML com o valor entre chaves executam qualquer código Elixir válido para gerar o valor do atributo.
- Em HEEx, você também pode passar listas para atributos para simplificar a mistura de strings e variáveis.
- Em HEEx, você pode passar um mapa entre chaves na tag HTML para que múltiplos atributos sejam adicionados de forma dinâmica.
- Projetos antigos usavam a sintaxe de interpolação `<%= %>` ao invés de `{}`.
- `<%= %>` é usado principalmente para estruturas de controle (`if`, `else`...).