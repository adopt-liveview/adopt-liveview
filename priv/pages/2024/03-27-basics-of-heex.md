%{
title: "Básico de HEEx",
author: "Lubien",
tags: ~w(getting-started),
section: "Fundamentos",
description: "Aprenda como HEEx entende HTML de uma forma diferente"
}

---

Para facilitar o seu futuro no LiveView vamos aprender algumas coisas simples sobre o funcionamento do HEEx que vão tornar seu dia a dia mais produtivo.

## Renderização de Elixir

Crie e execute um arquivo chamado `elixir_render.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    <h2>Hello <%= "Lubien" %></h2>
    <h2>Hello <%= 1 + 1 %></h2>
    <h2>Hello <%= "Chris" <> " " <> "McCord" %></h2>
    <h2>Hello <% "King Crimson" |> IO.puts() %></h2>
    """
  end
end

LiveviewPlayground.start()
```

Neste arquivo possuímos 4 tags do HEEx para interpolar código. HEEx dá suporte a renderizar qualquer tipo de código que implemente o protocolo [`Phoenix.HTML.Safe`](https://hexdocs.pm/phoenix_html/Phoenix.HTML.Safe.html).

- O primeiro case renderiza a string `"Lubien"`.
- O segundo caso renderiza o inteiro 2.
- O terceiro caso apenas usa o operador de concatenar strings [`<>`](https://hexdocs.pm/elixir/1.12/Kernel.html#%3C%3E/2) cujo resultado é "Chris McCord".

Mas e o quarto caso? Nada aparece na sua tela. O motivo é simples: usamos a tag `<% %>`, note que não existe um `=` após o primeiro `%`. Em HEEx isso significa "execute este código mas não renderize o resultado". Como ele utiliza a função [`IO.puts/2`](https://hexdocs.pm/elixir/1.12/IO.html#puts/2) você consegue ver o resultado no seu terminal.

%{
title: "Então eu posso adicionar lógica ao meu HEEx!",
type: :warning,
description: ~H"""
A resposta direta é sim, você pode, porém isso significa que toda vez seu HEEx for recalculado quando algum assign mudar a sua lógica irá ser executada mais uma vez. <.link navigate="https://hexdocs.pm/phoenix_live_view/assigns-eex.html#pitfalls" target="\_blank">A recomendação do time do Phoenix</.link> é que você faça qualquer lógica em assigns para evitar possíveis problemas de performance. No futuro iremos aprender outros modos de ter lógica em seu HEEx de forma eficiente.
"""
} %% .callout

## Renderizando algo que não pode ser convertido em string

Crie e execute um arquivo chamado `cant_render.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule User do
  defstruct id: nil, name: nil
end

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    <h2>Hello <%= %User{id: 1, name: "Lubien"} %></h2>
    """
  end
end

LiveviewPlayground.start()
```

Você irá notar um "Internal Server Error" e no seu terminal a exceção:

```elixir
** (exit) an exception was raised:
    ** (Protocol.UndefinedError) protocol Phoenix.HTML.Safe not implemented for %User{id: 1, name: "Lubien"} of type User (a struct). This protocol is implemented for the following type(s): Atom, BitString, Date, DateTime, Float, Integer, List, NaiveDateTime, Phoenix.HTML.Form, Phoenix.LiveComponent.CID, Phoenix.LiveView.Component, Phoenix.LiveView.Comprehension, Phoenix.LiveView.JS, Phoenix.LiveView.Rendered, Time, Tuple, URI
        (phoenix_html 3.3.3) lib/phoenix_html/safe.ex:1: Phoenix.HTML.Safe.impl_for!/1
        (phoenix_html 3.3.3) lib/phoenix_html/safe.ex:15: Phoenix.HTML.Safe.to_iodata/1
        priv/examples/basics-of-heex/cant_render.exs:14: anonymous fn/2 in PageLive.render/1
        (phoenix_live_view 0.18.18) lib/phoenix_live_view/diff.ex:398: Phoenix.LiveView.Diff.traverse/7
        (phoenix_live_view 0.18.18) lib/phoenix_live_view/diff.ex:544: anonymous fn/4 in Phoenix.LiveView.Diff.traverse_dynamic/7
        (elixir 1.16.1) lib/enum.ex:2528: Enum."-reduce/3-lists^foldl/2-0-"/3
        (phoenix_live_view 0.18.18) lib/phoenix_live_view/diff.ex:396: Phoenix.LiveView.Diff.traverse/7
        (phoenix_live_view 0.18.18) lib/phoenix_live_view/diff.ex:139: Phoenix.LiveView.Diff.render/3
```

Como mencionado anteriormente, o protocolo `Phoenix.HTML.Safe` é necessário para podermos renderizar um dado do Elixir. Isso acontece não por uma questão de limitação do LiveView ou segurança, o motivo que esse protocolo existe é pois o time do Phoenix converte o dado original Elixir em uma estrutura chamada `iodata` que é mais eficiente em ser enviada para seu usuário.

Se você quiser apenas fazer o debug rápido de um dado que não pode ser renderizado pelo HEEx a recomendação seria você usar inspect: `<h2>Hello <%= inspect(%User{id: 1, name: "Lubien"}) %></h2>`. Se você realmente tiver a necessidade de ensinar o HEEx a interpretar seu struct você também pode implementar o protocolo você mesmo. Crie e execute um arquivo chamado `impl_phoenix_html_safe.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
], consolidate_protocols: false)

defmodule User do
  defstruct id: nil, name: nil
end

defimpl Phoenix.HTML.Safe, for: User do
  def to_iodata(user) do
    "User #{user.id} is named #{user.name}"
  end
end

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    <h2>Hello <%= %User{id: 1, name: "Lubien"} %></h2>
    """
  end
end

LiveviewPlayground.start()
```

Usando [`defimpl/3`](https://hexdocs.pm/elixir/1.14/Kernel.html#defimpl/3) conseguimos definir o callback `to_iodata/1` do protocolo e converter o usuário para string (dado que o HEEx consegue renderizar). Vale mencionar que de você decidir retornar qualquer tipo de HTML aqui você fica responsável de garantir que não existe nenhuma vulnerabilidade como [XSS](https://owasp.org/www-community/attacks/xss/). Imagine se seu usuário possui um nome com `<svg onload=alert(1)>` e você não escapou esse dado? Portanto evite esta prática sempre que possível.

## Renderização de `nil`

Crie e execute um arquivo chamado `nil_render.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    ~H"""
    <h2>Hello <%= "Lubien" %></h2>
    <h2>Hello <%= nil %></h2>
    """
  end
end

LiveviewPlayground.start()
```

Neste cenário verificamos que quando a tag `<%= %>` recebe `nil` o resultado é não renderizar absolutamente nada. Isso será útil logo mais!

## Renderização de atributos HTML

Crie e execute um arquivo chamado `attribute_render.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.1"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def render(assigns) do
    bg_for_hello_phoenix = "bg-black"
    multiple_attributes = %{style: "color: yellow", class: "bg-black"}

    ~H"""
    <style>
    .color-red { color: red }
    .bg-black { background-color: black }
    .bg-red { background-color: red }
    </style>

    <h2 style="color: red" class={"bg-black"}>Hello World</h2>
    <h2 style={"color: white"} class={"bg-" <> "red"}>Hello Elixir</h2>
    <h2 class={[bg_for_hello_phoenix, nil, "color-red"]}>Hello Phoenix</h2>
    <h2 {multiple_attributes}>Hello LiveView</h2>
    """
  end
end

LiveviewPlayground.start()

```

Existem múltiplas maneiras para adicionarmos atributos HTML em HEEx para a conveniência do desenvolvedor. Vamos verificar cada um deles.

No primeiro caso (Hello World) nós adicionamos `style="color: red"` que funciona como qualquer outro HTML no mundo. Neste formato pode-se dizer que não existe nenhum tipo de processamento extra. Já na `class={"bg-black"}` ao usarmos as chaves nós estamos dizendo que o conteúdo dentro delas compreende um código Elixir. Qualquer código Elixir como `class={calculate_class()}` (supondo que a função exista) ou `class={"bg-{@my_background}"}` (supondo que o assign exista) será valido!

No segundo caso (Hello Elixir)apenas demonstramos mais uma vez o que foi explicado no caso anterior. Em `class={"bg-" <> "red"}` pode-se notar um exemplo de usar o operador `<>` para calcular a classe final.

No terceiro exemplo (Hello Phoenix) existe uma dica de ouro: você pode passar uma array com multiplas string para um atributo e no final será automaticamente unido e os valores que forem `nil` serão ignorados. O motivo que torna essa técnica poderosa é que facilita trabalhar com variáveis como podemos ver a `bg_for_hello_phoenix` sendo utilizada.

O último caso (Hello LiveView) adiciona mais uma fora de trabalhar com atributos. Se você precisar algum dia adicionar atributos de modo dinâmico, isto é, você não sabe exatamente quais atributos vão entrar ou não de antemão, você pode usar a syntax de adicionar um mapa do elixir dentro da tag de abertura do HTML e o HEEx vai entender que cada chave no seu mapa representa um atributo.

%{
title: "Posso usar variáveis na minha render funcion?",
description: ~H"""
Sim, não existe problema você simplesmente adicionar variáveis antes do seu HEEx especialmente se você fizer isso só para deixar o código mais legível (imagine que você tem uma quantidade absurda de classes por exemplo) porém você verá warnings dizendo que a recomendação oficial é transformar estas variáveis em assigns. Em aulas futuras aprenderemos como fazer isso de uma maneira bem simples e legível.
"""
} %% .callout

## Resumindo!

- Usar a tag `<%= %>` renderiza código Elixir que o protocolo `Phoenix.HTML.Safe` aceita.
- Usar a tag `<% %>` apenas executa código Elixir e não renderiza nada.
- Você pode implementar `Phoenix.HTML.Safe` para structs porém deve estar ciente dos riscos de segurança que isso pode trazer.
- HEEx considera `nil` como algo que não deve ser renderizado, isto é útil caso você queira trabalhar com variáveis opcionais.
- Em HEEx, atributos HTML com o valor ao redor de chaves executam qualquer código Elixir válido para gerar valor do atributo.
- Em HEEx, você também pode passar listas para atributos para simplificar misturar strings e variáveis.
- Em HEEx, você pode passar um mapa entre chaves na tag HTML para que múltiplos atributos sejam adicionados de forma dinâmica.
