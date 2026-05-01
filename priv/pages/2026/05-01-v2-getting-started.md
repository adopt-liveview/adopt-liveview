%{
title: "Instalando o setup com Phoenix Express!",
author: "Lubien",
tags: ~w(getting-started),
section: "Introdução",
description: "Vamos aprender como fazer uma LiveView rodar no seu computador",
next_page_id: "v2-first-liveview"
}

---

## Phoenix Express

A galera do Phoenix quis tornar o processo de onboarding absurdamente simples e criou uma forma de instalar o Elixir (caso você ainda não tenha) e gerar um projeto Phoenix com um único comando! Usando o seu terminal, vá até o diretório onde você quer criar o seu projeto e rode o comando:

Para macOS/Ubuntu:

```
curl https://new.phoenixframework.org/myapp | sh
```

Para Windows PowerShell:

```
curl.exe -fsSO https://new.phoenixframework.org/myapp.bat; .\myapp.bat
```

Preste atenção na saída do comando. Em algum momento ele vai exibir uma mensagem parecida com esta:

```
# Export the PATH so the current shell can find 'elixir' and 'mix'
export PATH=...
export PATH=...
```

Copie ambas as linhas com `export` e adicione-as ao seu `~/.bashrc` ou `~/.zshrc` ou qualquer arquivo de configuração do shell que você use.


## Ou: instalação manual

Se você preferir instalar tudo manualmente, pode seguir as instruções no site oficial do Elixir: https://elixir-lang.org/install.html

Em seguida, inicie o seu projeto Phoenix com os seguintes comandos:

1. `mix archive.install hex phx_new`
2. `mix phx.new myapp`
3. `cd myapp`
4. `mix setup`

## "Myapp"

Nos dois casos estamos criando um projeto Phoenix chamado "Myapp". Vamos utilizá-lo durante as próximas etapas. Em um projeto real você executaria esses comandos com um nome verdadeiro para o seu projeto, mas para deixar este tutorial o mais genérico possível estamos usando "Myapp".

## Conclusão

Neste ponto você já deve ser capaz de rodar o seguinte comando para iniciar o seu servidor:

```sh
$ mix phx.server
[info] Running MyappWeb.Endpoint with Bandit 1.8.0 at 127.0.0.1:4000 (http)
[info] Access MyappWeb.Endpoint at http://localhost:4000
[watch] build finished, watching for changes...
≈ tailwindcss v4.1.7

/*! 🌼 daisyUI 5.0.35 */
Done in 85ms
```

Parabéns, você está pronto para começar a mexer com Phoenix! Acesse http://localhost:4000 para ver a sua página inicial padrão.