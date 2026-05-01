%{
title: "Meu primeiro projeto LiveView",
author: "Lubien",
tags: ~w(getting-started),
section: "CRUD",
description: "Finalmente um projeto!",
previous_page_id: "v2-simple-forms-with-ecto",
next_page_id: "v2-cleanup"
}

---

Esta seção do curso vai ser muito especial. Vamos colocar em prática muitas coisas que já conversamos anteriormente para criar um sistema bem simples de filas de atendimento. Basicamente um CRUD (Create-Read-Update-Delete).

Para simular um projeto real vamos nomear nosso projeto de `Lineup`. Nosso módulo principal se chamará `Lineup`, nosso módulo web `LineupWeb` e nossa principal lógica de negócio ficará em `Lineup.Queue`.

## Passo opcional: Leia isso se você pulou a seção de fundamentos

Se você acabou de entrar no curso e não usou o Phoenix Express antes, sinta-se à vontade para instalar o Elixir usando o [script oficial de instalação](https://elixir-lang.org/install.html#install-scripts) que também incluirá o Erlang e em seguida instale o `mix phx.new` executando `mix archive.install hex phx_new`.

## Hora do SQLite

Para este CRUD específico vamos usar o Ecto (a biblioteca que nos ajuda a trabalhar com bancos de dados) junto com o SQLite3. Escolhemos o SQLite por dois motivos muito simples:

- **Não requer instalar nada extra no seu computador**: basta instalar a biblioteca e o banco de dados já pode ser iniciado.
- **O que aprenderemos aqui é facilmente reutilizável em outros bancos de dados**: vamos focar em operações fundamentais do Ecto, portanto não importa se você pretende usar PostgreSQL ou MySQL no futuro — o código será o mesmo.

## Configurando tudo

Anteriormente usamos o Phoenix Express para instalar o Elixir, Erlang e criar um projeto Phoenix imediatamente. Agora você também deve ter instalado um novo comando auxiliar: `mix phx.new`!

Para criar um novo projeto Phoenix usando `mix phx.new` basta executar `mix phx.new lineup --database sqlite3`.

```sh
$ mix phx.new lineup --database sqlite3
* creating lineup/lib/lineup/application.ex
* creating lineup/lib/lineup.ex
* creating lineup/lib/lineup_web/controllers/error_json.ex
* creating lineup/lib/lineup_web/endpoint.ex
* creating lineup/lib/lineup_web/router.ex
* creating lineup/lib/lineup_web/telemetry.ex
* creating lineup/lib/lineup_web.ex
* creating lineup/mix.exs
* creating lineup/README.md
* creating lineup/.formatter.exs
* creating lineup/.gitignore
* creating lineup/test/support/conn_case.ex
* creating lineup/test/test_helper.exs
* creating lineup/test/lineup_web/controllers/error_json_test.exs
* creating lineup/lib/lineup/repo.ex
* creating lineup/priv/repo/migrations/.formatter.exs
* creating lineup/priv/repo/seeds.exs
* creating lineup/test/support/data_case.ex
* creating lineup/lib/lineup_web/controllers/error_html.ex
* creating lineup/test/lineup_web/controllers/error_html_test.exs
* creating lineup/lib/lineup_web/components/core_components.ex
* creating lineup/lib/lineup_web/controllers/page_controller.ex
* creating lineup/lib/lineup_web/controllers/page_html.ex
* creating lineup/lib/lineup_web/controllers/page_html/home.html.heex
* creating lineup/test/lineup_web/controllers/page_controller_test.exs
* creating lineup/lib/lineup_web/components/layouts/root.html.heex
* creating lineup/lib/lineup_web/components/layouts.ex
* creating lineup/priv/static/images/logo.svg
* creating lineup/lib/lineup/mailer.ex
* creating lineup/lib/lineup_web/gettext.ex
* creating lineup/priv/gettext/en/LC_MESSAGES/errors.po
* creating lineup/priv/gettext/errors.pot
* creating lineup/priv/static/robots.txt
* creating lineup/priv/static/favicon.ico
* creating lineup/assets/js/app.js
* creating lineup/assets/vendor/topbar.js
* creating lineup/assets/tsconfig.json
* creating lineup/assets/css/app.css
* creating lineup/assets/vendor/heroicons.js
* creating lineup/assets/vendor/daisyui.js
* creating lineup/assets/vendor/daisyui-theme.js
* initializing git repository
```

Você será solicitado imediatamente a instalar as dependências e compilar tudo; pode aceitar tranquilamente pressionando enter.

```sh
Fetch and install dependencies? [Yn]
* running mix deps.get
* running mix assets.setup
* running mix deps.compile

We are almost there! The following steps are missing:

    $ cd lineup

Then configure your database in config/dev.exs and run:

    $ mix ecto.create

Start your Phoenix app with:

    $ mix phx.server

You can also run your app inside IEx (Interactive Elixir) as:

    $ iex -S mix phx.server
```

Assim como as instruções indicam, execute `cd lineup` seguido de `mix ecto.create` para criar seu banco de dados.

## Em caso de problemas

Caso você tenha tido dificuldades para configurar tudo com os comandos acima, ou simplesmente queira ver o estado inicial deste projeto, você pode clonar nosso projeto base que preparei. Usando seu terminal:

```
git clone https://github.com/adopt-liveview/lineup.git
cd lineup
mix setup
```

Com esses comandos você terá um projeto Phoenix base. O comando `mix setup` não só instala como também compila as dependências e configura o banco de dados.

## Resumindo!

* Você pode usar o Phoenix Express ou `mix phx.new` para criar novos projetos.
* O Phoenix sempre vai lhe dar instruções sobre o que fazer a seguir após iniciar um novo projeto, então não as ignore.
* `mix ecto.create` vai criar seu banco de dados.
* `mix setup` vai preparar tudo para você, incluindo a criação do banco de dados.