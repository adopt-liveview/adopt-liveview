%{
title: "My first LiveView project",
author: "Lubien",
tags: ~w(getting-started),
section: "CRUD",
description: "Finally a project!",
previous_page_id: "v2-simple-forms-with-ecto",
next_page_id: "v2-cleanup"
}

---

This section of the course is going to be very special. We will put into practice many things that we already talked about previously to create a very simple queue ticket system. Basically a CRUD (Create-Read-Update-Delete).

To simulate a real project we will name our project `Lineup`. Our main module will be called `Lineup`, our web module `LineupWeb` and our main business logic will live under `Lineup.Queue`.

## Optional step: Read this if you skipped the fundamentals section

If you have just joined our course and didn't use Phoenix Express before feel free to install Elixir using the [official setup script](https://elixir-lang.org/install.html#install-scripts) which will also include Erlang then install `mix phx.new` by running `mix archive.install hex phx_new`.

## SQLite time

For this specific CRUD we will use Ecto (the library that helps us work with databases) alongside SQLite3. We chose SQLite for two very simple reasons:

- **Does not require installing anything extra on your computer**: just install the library and the database can be started.
- **What we will learn here is easily reusable in other databases**: we will focus on fundamental Ecto operations so it doesn't matter if you intend to use PostgreSQL or MySQL in the future the code will be the same.

## Setting things up

Previously we used Phoenix Express to install Elixir, Erlang and create a Phoenix Project immediately. Right now you should also have installed a new helper command: `mix phx.new`!

To create a new Phoenix project using `mix phx.new` all you have to do is run `mix phx.new lineup --database sqlite3`. 

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

You will be immediately prompted to install dependencies and compile everything, feel free to accept by pressing enter.

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

Just like the instructions say, run `cd lineup` followed by `mix ecto.create` to create your database.

## In case of trouble

In case you had trouble setting things up using the above commands or you just want to see the initial state of this project you can clone our base project that I prepared. Using your terminal:

```
git clone https://github.com/adopt-liveview/lineup.git
cd lineup
mix setup
```

With these commands you should have a base Phoenix project. The `mix setup` command not only installs things but also compiles dependencies and sets up the database too. 

## Recap!

* You can either use Phoenix Express or `mix phx.new` to create new projects.
* Phoenix will always give you instructions on what to do next after starting a new project so don't skip on that.
* `mix ecto.create` will create your database.
* `mix setup` will prepare everything for you which includes creating your database too.
