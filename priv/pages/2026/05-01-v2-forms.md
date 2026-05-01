%{
title: "Componente de formulário",
author: "Lubien",
tags: ~w(getting-started),
section: "Formulários",
description: "Entendendo o básico de forms em Phoenix",
previous_page_id: "v2-lists-with-slots",
next_page_id: "v2-form-validation"
}

---

%{
title: "Este guia é uma continuação direta do guia anterior",
type: :warning,
description: ~H"""
Se você entrou direto nesta página, pode ser confuso pois ela é uma continuação direta do código da aula anterior. Caso queira pular a aula anterior e começar direto nesta, você pode clonar a versão inicial para esta aula usando o comando <code class="select-all">`git clone https://github.com/adopt-liveview/v2-myapp.git --branch lists-with-slots-done`</code>.
"""
} %% .callout

Formulários são partes essenciais de muitas aplicações Phoenix. Também são um dos maiores pontos de confusão para quem está começando com LiveView. Durante as próximas aulas iremos aprender sobre formulários de uma maneira bottom-up. Isso significa que vamos começar implementando algumas coisas para entender o que o Phoenix está resolvendo com seus componentes built-in.

Se no início você achar que está muito complicado e o framework é muito difícil, não se preocupe — no final você vai ver que todas essas coisas são resolvidas com componentes prontos, pois o Phoenix é um framework batteries-included.

## O formulário mais simples de todos

Quando você estudou o básico de HTML, aposto que em algum momento teve que construir um formulário com alguns inputs que poderia ser enviado. Vamos começar com essa meta. Vamos criar um formulário de criação de produto. Atualize seu `page_live.ex` assim:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

  def handle_event("create_product", %{"product" => product_params}, socket) do
    IO.inspect({"Form submitted!!", product_params})
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <form phx-submit="create_product" class="flex flex-col max-w-96 mx-auto p-24">
        <h1 class="text-blue-500">Creating a product</h1>
        <input type="text" name="product[name]" placeholder="Name" />
        <input type="text" name="product[description]" placeholder="Description" />
        <button type="submit">Send</button>
      </form>
    </div>
    """
  end
end
```

### HEEx e o binding `phx-submit`

Olhe nosso código HEEx. As tags form e input são exatamente o que você viu quando estudou HTML, sem qualquer modificação. A novidade introduzida aqui é o binding [`phx-submit`](https://hexdocs.pm/phoenix_live_view/form-bindings.html#form-events). Assim como o `phx-click`, este binding mapeia o envio de um formulário para um `handle_event/3` na nossa LiveView.

### Mapeando atributos `name` de inputs para mapas

Outro ponto que você pode ter estranhado é que os atributos `name` no nosso código HEEx usam o formato `product[name]`. Apesar de não ser obrigatório, esta tem sido a convenção do Phoenix desde antes do LiveView existir e a recomendação é que você continue seguindo ela. Não se preocupe muito, veremos mais tarde que isso tudo é feito automaticamente.

Quando temos um form HTML com inputs `product[name]` e `product[description]`, isso gera um mapa equivalente no formato `%{"product" => %{"name" => "", "description" => ""}}`. Isso facilita recuperarmos esse valor no nosso `handle_event/3`. Acredito que sempre é bom frisar este tópico, pois é algo que geralmente não vejo explicado em documentações de frameworks.

### Recebendo o form com `handle_event/3`

Em nosso código HEEx adicionamos ao form `phx-submit="create_product"`, portanto devemos tratar o evento `"create_product"` como `handle_event("create_product", %{"product" => product_params}, socket)`. Note que os `params` foram capturados usando o pattern matching do formato explicado anteriormente, pois o Phoenix prefere seguir esta convenção.

Nosso `handle_event/3` não faz nada de especial — ele apenas gera uma mensagem no seu terminal e nada mais. Parabéns, você criou seu primeiro formulário em Phoenix LiveView!

## Conhecendo o componente de formulário

No momento não fazemos qualquer tipo de validação com nosso formulário. Para nos ajudar, o Phoenix possui uma estrutura de dados chamada [`Phoenix.HTML.Form`](https://hexdocs.pm/phoenix_html/3.3.0/Phoenix.HTML.Form.html) que simplifica o gerenciamento de formulários e nos oferece um sistema de validações.

### Novas estruturas de dados

Quando convertemos um mapa no formato `%{name: "", description: ""}` para `Phoenix.HTML.Form`, uma variável no formato abaixo é criada:

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

Supondo que sua variável seja `form`, você pode acessar os campos em uma estrutura chamada [`Phoenix.HTML.FormField`](https://hexdocs.pm/phoenix_html/3.3.0/Phoenix.HTML.FormField.html) com o seguinte formato:

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

Vamos aplicar isso no nosso código!

### O componente `<.form>`

Projetos Phoenix vêm com um componente chamado [`<.form>`](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#form/1). O objetivo deste componente é gerar HTML básico para formulários além de oferecer vantagens como proteção contra [CSRF](https://owasp.org/www-community/attacks/csrf) (quando necessário), validação extra de erros e method spoofing. A preferência será sempre usar esse componente ao invés da tag `<form>`.

Vamos experimentar. Atualize seu `page_live.ex` para usar `<.form>` e conectar os inputs via `Phoenix.HTML.FormField`:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

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
    <div>
      <.form
        for={@form}
        phx-submit="create_product"
        class="flex flex-col max-w-96 mx-auto p-24"
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
```

### Usando `to_form/2` para gerar formulários

No topo do nosso módulo criamos um [module attribute](https://hexdocs.pm/elixir/module-attributes.html) chamado `@initial_state` para ajudar na leitura do código e tornar esse estado facilmente acessível no futuro. Além disso, introduzimos um `mount/3` que cria um assign chamado `form` com o valor da função [`to_form/2`](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#to_form/2) passando nosso `@initial_state` e como opção `as: :product`. O motivo de colocarmos esta opção é para que nossos campos do formulário sigam o formato `product[name]`.

## Renderizando nosso `<.form>`

Analisando o código HEEx, podemos notar que a primeira diferença é que paramos de usar a tag HTML `<form>` e adicionamos o componente `<.form>` passando o assign `for={@form}`. É tudo que esse componente precisa!

Um pouco mais abaixo modificamos nossas tags `input` para receber cada campo do formulário no formato `@form[:name]`. Cada um desses representa um `Phoenix.HTML.FormField` e usamos as propriedades `id` e `name` do campo nos atributos com os mesmos nomes.

Agora você deve estar pensando: "Meu código ficou mais verboso, qual é a vantagem?". A motivação é mais simples do que parece: podemos componentizar nossas tags `input`!

## O componente `<.my_input>`

Pelo fato de você ter estruturado seus dados em `Phoenix.HTML.FormField`, agora podemos facilmente construir um componente que lê esse dado e automaticamente adiciona as propriedades necessárias como `name` e `id`. Comece adicionando um componente `my_input` ao `my_core_components.ex`:

```elixir
defmodule MyappWeb.MyCoreComponents do
  use MyappWeb, :verified_routes
  use Phoenix.Component

  slot :title do
    attr :class, :string
  end

  slot :subtitle
  slot :inner_block

  def hero(assigns) do
    ~H"""
    <div class="bg-gray-800 text-white py-20">
      <div class="container mx-auto text-center">
        <h1 :for={title_slot <- @title} class={["text-4xl font-bold", Map.get(title_slot, :class)]}>
          {render_slot(title_slot)}
        </h1>
        <p class="mt-4 text-lg">{render_slot(@subtitle)}</p>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.my_button>Save data</.my_button>
      <.my_button type="submit" class="text-blue-500">Save data</.my_button>
      <.my_button type="submit" color="red">Delete account</.my_button>
  """
  attr :color, :string, default: "blue", examples: ~w(blue red yellow green)
  attr :class, :string, default: nil
  attr :rest, :global, default: %{type: "button"}, include: ~w(type style)
  slot :inner_block, required: true

  def my_button(assigns) do
    ~H"""
    <button
      class={[
        "text-white bg-#{@color}-700 hover:bg-#{@color}-800 focus:ring-4 focus:ring-#{@color}-300 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 dark:bg-#{@color}-600 dark:hover:bg-#{@color}-700 focus:outline-none dark:focus:ring-#{@color}-800",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  attr :terms, :list, required: true
  slot :dt, required: true
  slot :dd, required: true

  def dl(assigns) do
    ~H"""
    <dl class="max-w-xs mx-auto">
      <div class="grid grid-cols-1 gap-y-2">
        <div :for={item <- @terms} class="border-b border-gray-300">
          <dt class="text-lg font-semibold">{render_slot(@dt, item)}</dt>
          <dd class="text-gray-600">{render_slot(@dd, item)}</dd>
        </div>
      </div>
    </dl>
    """
  end

  attr :field, Phoenix.HTML.FormField, required: true
  attr :type, :string, default: "text"
  attr :rest, :global, include: ~w(placeholder type)

  def my_input(assigns) do
    ~H"""
    <input type={@type} id={@field.id} name={@field.name} {@rest} />
    """
  end
end
```

Agora atualize seu `page_live.ex` para usar `<.my_input>`:

```elixir
defmodule MyappWeb.PageLive do
  use MyappWeb, :live_view

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
    <div>
      <.form
        for={@form}
        phx-submit="create_product"
        class="flex flex-col max-w-96 mx-auto p-24"
      >
        <h1 class="text-blue-500">Creating a product</h1>
        <.my_input field={@form[:name]} placeholder="Name" />
        <.my_input field={@form[:description]} placeholder="Description" />

        <button type="submit">Send</button>
      </.form>
    </div>
    """
  end
end
```

### Implementando o `<.my_input>`

Com pouco código conseguimos criar um componente `<.my_input field={@form[:name]}>` que mapeia automaticamente as propriedades necessárias. Além disso criamos um `attr` que define o `type` como `"text"` por padrão e um `attr` global para receber qualquer outra propriedade necessária. Caso no futuro queiramos modificar os estilos de todos os inputs do nosso sistema, temos um lugar centralizado para fazer isso.

%{
title: "Vou ter que criar meus componentes de input em todos os projetos Phoenix que eu fizer?",
description: ~H"""
Vim aqui especialmente para lhe dar um spoiler: a resposta é não. O Phoenix já gera esse componente para você de uma maneira infinitamente melhor do que eu posso lhe ensinar. Apenas lembre que estas aulas são bottom-up — estamos lhe ensinando a fazer para que você entenda como eles funcionam.
"""
} %% .callout

## Resumindo!

- Formulários em LiveView usam o binding `phx-submit` para disparar um `handle_event/3` com o respectivo nome do evento.
- O Phoenix prefere usar em seus `input` o formato `nome_do_pai[filho]` para facilitar gerenciar qual formulário contém qual dado. Isso gera mapas como `%{"nome_do_pai" => %{"filho" => ""}}` nos eventos de `phx-submit`.
- A preferência para criar formulários será sempre usar o componente `<.form>` ao invés da tag `<form>`.
- Para preparar um dado no formato `Phoenix.HTML.Form`, a função `to_form/2` converte o dado `to_form(%{name: ""}, as: :product)` no formato adequado.
- Preferimos adicionar `as: :nome_do_pai` como opção do `to_form/2` para seguir a convenção do Phoenix de como organizar os atributos `name` das nossas tags `input`.
- Usar formulários no formato `Phoenix.HTML.Form` facilita a criação de componentes para inputs.