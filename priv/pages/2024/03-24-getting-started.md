%{
title: "Instalando o setup!",
author: "Lubien",
tags: ~w(getting-started),
section: "Introdução",
description: "Vamos aprender como fazer uma LiveView rodar no seu computador",
next_page_id: "first-liveview"
}

---

## Instalando o runtime

O primeiro passo será instalar Elixir e Erlang.

Se você não tem nenhum dos dois instalados a recomendação é que você use a ferramenta `asdf` pois ela vai facilitar tanto instalar agora como gerenciar várias versões das ferramentas no futuro.

## Instalando `asdf`

Usando um terminal basta rodar o comando:

```bash
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.10.2
```

Uma vez que o `asdf` tiver sido clonado você precisa adicionar ele ao seu perfil do shell.

Se você usa `bash` (provavelmente você usa 😉):

```
echo '. "$HOME/.asdf/asdf.sh"' >> ~/.bashrc
echo '. "$HOME/.asdf/completions/asdf.bash"' >> ~/.bashrc
```

Se você usa `zshell` o comando seria:

```
echo '. "$HOME/.asdf/asdf.sh"' >> ~/.zshrc
```

%{
title: "Não achou o seu shell aqui?",
description: ~H"""
Navegue até <.link navigate="https://asdf-vm.com/guide/getting-started.html#_3-install-asdf" target="\_blank">lista de exemplos</.link> e procure o seu shell no guia oficial
"""
} %% .callout

Após instalar tudo abra um novo terminal e verifique que ele está instalado usando `asdf version`. A versão do seu `asdf` não importa.

```sh
$ asdf version
v0.10.0-77fd510
```

## Instalando o Erlang

O `asdf` funciona através de plugins. Você precisa instalar o plugin do Erlang para poder instalar versões dele:

```
asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git
```

%{
title: "O erlang pode ser muito chato de instalar",
type: :warning,
description: ~H"""
Dependendo do seu sistema operacional você pode ter dores de cabeça diferentes. Recomendo dar uma breve lida <.link navigate="https://github.com/asdf-vm/asdf-erlang#before-asdf-install" target="\_blank">nesta área</.link> caso você passe problemas no próximo passo.
"""
} %% .callout

Vamos instalar o Erlang 26.2.2 e ativar ele globalmente.

```sh
asdf install erlang 26.2.2
asdf global erlang 26.2.2
```

## Instalando o Elixir

Diferente do Erlang este deve ser bem mais simples.

```sh
asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git
asdf install elixir 1.16.1-otp-26
asdf global elixir 1.16.1-otp-26
```

## Conclusão

Neste momento você deve ser capaz de rodar o seguinte comando:

```sh
$ elixir --version
Erlang/OTP 26 [erts-14.2.2] [source] [64-bit] [smp:10:10] [ds:10:10:10] [async-threads:1] [jit]

Elixir 1.16.1 (compiled with Erlang/OTP 26)
```

Parabéns, você está pronto para começar a mexer com LiveView!