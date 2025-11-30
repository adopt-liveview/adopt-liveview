%{
title: "Installing the setup with Phoenix Express!",
author: "Lubien",
tags: ~w(getting-started),
section: "Introduction",
description: "Let's learn how to make a LiveView run on your computer",
next_page_id: "v2-first-liveview"
}

---

## Phoenix Express

Folks at Phoenix wanted to bake onboarding stupdly simple and created an way of installing Elixir (if you don't have it installed) and generating a Phoenix project with a single command! Using your terminal go to a directory where you want to create your project and run the command:

For macOS/Ubuntu:

```
curl https://new.phoenixframework.org/myapp | sh
```

For Windows PowerShell:

```
curl.exe -fsSO https://new.phoenixframework.org/myapp.bat; .\myapp.bat
```

Make sure to read the output. At some point it will show you a message such as:

```
# Export the PATH so the current shell can find 'elixir' and 'mix'
export PATH=...
export PATH=...
```

Copy both `export` lines and add them to your `~/.bashrc` or `~/.zshrc` or whatever shell configuration file you use.


## Or: manual installation

If you want to install things manually, you can follow the instructions on Elixir's official website: https://elixir-lang.org/install.html

Then start your phoenix project with the following commands:

1. `mix archive.install hex phx_new`
2. `mix phx.new myapp`
3. `cd myapp`
4. `mix setup`

## "Myapp"

In both cases we are creating a Phoenix app called "Myapp". We will be using it during the next steps. In a real project you'd execute those commands with a real name for your project but to make this tutorial as generic as possible we are using "Myapp" instead.

## Conclusion

At this point you should be able to run the following command to start you server:

```sh
$ mix phx.server
[info] Running MyappWeb.Endpoint with Bandit 1.8.0 at 127.0.0.1:4000 (http)
[info] Access MyappWeb.Endpoint at http://localhost:4000
[watch] build finished, watching for changes...
≈ tailwindcss v4.1.7

/*! 🌼 daisyUI 5.0.35 */
Done in 85ms
```

Congratulations, you're ready to start tinkering with Phoenix! Head out to http://localhost:4000 to see your default home page.
