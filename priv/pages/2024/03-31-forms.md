%{
title: "Componente de formulário",
author: "Lubien",
tags: ~w(getting-started),
section: "Formulários",
description: "Entendendo o básico de forms em Phoenix"
}

---

Formulários são partes essenciais de muitas aplicação Phoenix. Também são um dos maiores pontos de confusão de pessoas que estão entrando em LiveView. Durante as próximas aulas iremos aprender sobre formulários de uma maneira bottom-up, isto é, iremos implementar algumas coisas no início para entender o que o Phoenix está resolvendo com seus componentes.

Se, no início, você achar que está muito complicado e o framework é muito difícil não se preocupe pois no final você vai ver que todas essas coisas são resolvidas com componentes prontos e bibliotecas que o Phoenix trás consigo.

## O formulário mais simples de todos

Quando você estudou o básico de HTML aposto que você em algum momento teve que construir um formulário que tinha alguns inputs e poderia ser enviado. Vamos começar com essa meta. Vamos criar um formulário de criação de um produto. Crie e execute `first_form.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.5"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  def handle_event("create_product", %{"product" => product_params}, socket) do
    IO.inspect({"Form submitted!!", product_params})
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="bg-grey-100">
      <form phx-submit="create_product" class="flex flex-col max-w-96 mx-auto bg-gray-100 p-24">
        <h1>Creating a product</h1>
        <input type="text" name="product[name]" placeholder="Name" />
        <input type="text" name="product[description]" placeholder="Description" />
        <button type="submit">Send</button>
      </form>
    </div>
    """
  end
end

LiveviewPlayground.start(scripts: ["https://cdn.tailwindcss.com?plugins=forms"])
```

### Tailwind plugin `forms`

Se olhar na nossa área de `scripts` em `LiveViewPlayground.start` deve notar que adicionamos `?plugins=forms` ao URL do CDN. Este plugin apenas adiciona alguns estilos padrão para formulários HTML. Em projetos reais Phoenix com Tailwind ele já vem pré-instalado portanto você não precisa se preocupar. Iremos estar utilizando esse plugin bastante de agora em diante.

### HEEx e o binding `phx-submit`

Iremos começar a análise pelo nosso código HEEx. As tags form e input são apenas o que você viu quando estudou HTML sem qualquer modificação. O novo elementro introduzido aqui é o binding [`phx-submit`](https://hexdocs.pm/phoenix_live_view/form-bindings.html#form-events). Assim como o `phx-click` este binding mapeia um evento do HTML, neste caso o envio de um formuário, para um `handle_event/3` na nossa LiveView.

### Mapeando atributos de input `name` para mapas

Outro ponto que você pode ter estranhado é que os atributos `name` em nosso código HEEx usam o formato `product[name]`. Apesar de não ser obrigatório esta tem sido a convenção do Phoenix desde antes do LiveView existir e a recomendação seria que você continuasse com ela. Não se preocupe que mais tarde veremos que isso tudo é feito automaticamente, por enquanto vamos apenas seguir o baile.

Quando possuímos um form HTML com inputs `product[name]` e `product[description]` isso gera um mapa equivalente no formato `%{"product" => %{"name" => "", "description" => ""}}`. Isso facilita nós recuperarmos este valor no nosso `handle_event/3`. Acredito que sempre é bom frisar este tópico pois é algo que geralmente não vejo explicado em documentações de frameworks.

### Recebendo o form com `handle_event/3`

Em nosso HEEx adicionamos ao form `phx-submit="create_product"` portanto deveremos tratar o event `"create_product"` na forma `handle_event("create_product", %{"product" => product_params}, socket)`. Note que os `params` foram pegos usando o match do formato explicado anteriormente, por isso o Phoenix prefere seguir esta convenção.

Nosso `handle_event/3` não faz nada demais, ele apenas gera uma mensagem no seu terminal e nada além disso. Parabéns, você criou seu primeiro formulário em Phoenix LiveView!

## Conhecendo o componente de formulário

No momento não fazemos qualquer tipo de validação com nosso formulário. Para auxílio nosso o Phoenix possui uma estrutura de dados chamada [`Phoenix.HTML.Form`
](https://hexdocs.pm/phoenix_html/3.3.0/Phoenix.HTML.Form.html) que simplifica o gerenciamento de formulários além de trazer um sistema de validações para nós.

### Novas estruturas de dados

Quando convertemos um mapa no formato `%{name: "", description: ""}` para `Phoenix.HTML.Form` uma variável no formato abaixo é criada:

```elixir
%Phoenix.HTML.Form{
  source: %{"description" => "", "name" => ""},
  impl: Phoenix.HTML.FormData.Map,
  id: "product",
  name: "product",
  data: %{},
  action: nil,
  hidden: [],
  params: %{"description" => "", "name" => ""},
  errors: [],
  options: [],
  index: nil
}
```

Além disso, supondo que sua variável seja `form`, você consegue acessar os campos em uma estrutura chamada [`Phoenix.HTML.FormField`](https://hexdocs.pm/phoenix_html/3.3.0/Phoenix.HTML.FormField.html) que segue o seguinte formato:

```elixir
%Phoenix.HTML.FormField{
  id: "product_name",
  name: "product[name]",
  errors: [],
  field: :name,
  form: %Phoenix.HTML.Form{...},
  value: ""
}
```

Vamos aplicar elas na prática!

### O componente `<.form>`

Projetos Phoenix vem inclusos com um novo componente chamado [`<.form>`](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#form/1). O objetivo deste componente é gerar HTML básico para formulários além de oferecer outras vantagens como proteção contra [CSRF](https://owasp.org/www-community/attacks/csrf) (quando necessário), validação extra de erros e method spoofing. A preferência será sempre usar esse componente ao invés da tag `<form>`.

Vamos experimentar. Crie e execute um arquivo chamado `first_form_component.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.5"}
])

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view

  @initial_state %{
    "name" => "",
    "description" => ""
  }

  def mount(_params, _session, socket) do
    form = to_form(@initial_state, as: :product)
    {:ok, assign(socket, form: form)}
  end

  def handle_event("create_product", %{"product" => product_params}, socket) do
    IO.inspect({"Form submitted!!", product_params})
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="bg-grey-100">
      <.form
        for={@form}
        phx-submit="create_product"
        class="flex flex-col max-w-96 mx-auto bg-gray-100 p-24"
      >
        <h1>Creating a product</h1>
        <input type="text" id={@form[:name].id} name={@form[:name].name} placeholder="Name" />

        <input
          type="text"
          id={@form[:description].id}
          name={@form[:description].name}
          placeholder="Description"
        />

        <button type="submit">Send</button>
      </.form>
    </div>
    """
  end
end

LiveviewPlayground.start(scripts: ["https://cdn.tailwindcss.com?plugins=forms"])
```

### Usando `to_form/2` para gerar formulários

No topo do nosso módulo criamos um [module attribute](https://hexdocs.pm/elixir/module-attributes.html) chamado `@initial_state` para ajudar na leitura do nosso código e tornar esse estado facilmente acessível no futuro. Além disso, introduzimos um `mount/3` que cria um assign chamado `form` com o valor da função [`to_form/2`](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#to_form/2) passando nosso `@initial_state` e como opção `as: :product`. O motivo de colocarmos esta opção é para que nossos campos do formulário sigam o formato `product[name]`.

## Renderizando nosso `<.form>`

Indo ao código HEEx podemos notar que a primeira diferença é que paramos de usar a tag HTML `<form>` e adicionamos o componente `<.form>` passando o assign `for={@form}`. Isso é tudo que este componente precisa!

Um pouco mais abaixo modificamos nossas tags `input` para receber cada campo do formulário no formato `@form[:name]`. Cada um destes representa um `Phoenix.HTML.FormField` e usamos as propriedades `id` e `name` do campo nos atributos com os mesmos nomes.

Agora você deve estar pensando: "meu código ficou mais verboso, qual a vantagem?". A motivação é mais simples do que parece: podemos componentizar nossas tags `input`!

## O componente `.input`

Devido ao fato de você ter estruturado seus dados em `Phoenix.HTML.FormField` agora podemos facilmente construir um componente que lê esse dado e automaticamente adiciona propriedades necessárias como `name` e `id`. Crie e execute um arquivo chamado `first_form_component.exs`:

```elixir
Mix.install([
  {:liveview_playground, "~> 0.1.5"}
])

defmodule CoreComponents do
  use LiveviewPlaygroundWeb, :html

  attr :field, Phoenix.HTML.FormField, required: true
  attr :type, :string, default: "text"
  attr :rest, :global, include: ~w(placeholder type)

  def input(assigns) do
    ~H"""
    <input type="text" id={@field.id} name={@field.name} {@rest} />
    """
  end
end

defmodule PageLive do
  use LiveviewPlaygroundWeb, :live_view
  import CoreComponents

  @initial_state %{
    "name" => "",
    "description" => ""
  }

  def mount(_params, _session, socket) do
    form = to_form(@initial_state, as: :product)
    {:ok, assign(socket, form: form)}
  end

  def handle_event("create_product", %{"product" => product_params}, socket) do
    IO.inspect({"Form submitted!!", product_params})
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="bg-grey-100">
      <.form
        for={@form}
        phx-submit="create_product"
        class="flex flex-col max-w-96 mx-auto bg-gray-100 p-24"
      >
        <h1>Creating a product</h1>
        <.input field={@form[:name]} placeholder="Name" />
        <.input field={@form[:description]} placeholder="Description" />

        <button type="submit">Send</button>
      </.form>
    </div>
    """
  end
end

LiveviewPlayground.start(scripts: ["https://cdn.tailwindcss.com?plugins=forms"])
```

### Implementando o `<.input>`

Com pouco código conseguimos criar um componente `<.input field={@form[:name]}>` que mapeia automaticamente as propriedades necessárias. Além disso criamos um `attr` que define o `type` como `"text"` por padrão e um `attr` global para receber qualquer outra propriedade necessária. Caso no futuro queiramos modificar os estilos de todos os input em nosso sistema também temos um lugar centralizado para fazer isso.

%{
title: "Vou ter que criar meus componentes de input em todos os projetos Phoenix que eu fizer?",
description: ~H"""
Vim aqui especialmente para lhe dar um spoiler que a resposta é não, o Phoenix já gera este componente para você de um modo infinitamente melhor do que eu posso lhe ensinar. Apenas se lembre que estas aulas são bottom-up, estamos lhe ensinando a fazer para que você entenda como eles funcionam.
"""
} %% .callout

## Resumindo!

- Formulários em LiveView usam o binding `phx-submit` para disparar um `handle_event/3` com o respectivo nome do evento.
- O Phoenix prefere usar em seus `input` o formato `nome_do_pai[filho]` para facilitar gerenciar qual formulátio contém que dado. Isso gera mapas como `%{"nome_do_pai" => %{"filho" => ""}}` nos eventos de `phx-submit`.
- A preferência para criar formulários sempre será de usar o componente `<.form>` ao invés da tag `<form>`.
- Para preparar um dado no formato `Phoenix.HTML.Form` a função `to_form/2` converte um dado `to_form(%{name: ""}, as: :product)` no formato adequado.
- Preferimos adicionar `as: :nome_do_pai` como opção do `to_form/2` para seguir a convenção do Phoenix de como organizar os atributos `name` de nossas tags `input`.
- Usar formuários no formato `Phoenix.HTML.Form` facilita a criação de componentes para inputs.
