%{
title: "Installing the setup!",
author: "Lubien",
tags: ~w(getting-started),
section: "Introduction",
description: "Let's learn how to make a LiveView run on your computer",
next_page_id: "first-liveview"
}

---

## Installing the runtime

The first step will be to install Elixir and Erlang.

If you don't have either installed, we recommend that you use the `asdf` tool as it will make it easier to both install now and manage multiple versions of the tools in the future.

## Installing `asdf`

Using a terminal just run the command:

```bash
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.10.2
```

Once `asdf` has been cloned you need to add it to your shell profile.

If you use `bash` (you probably do 😉):

```
echo '. "$HOME/.asdf/asdf.sh"' >> ~/.bashrc
echo '. "$HOME/.asdf/completions/asdf.bash"' >> ~/.bashrc
```

If you use `zshell` the command would be:

```
echo '. "$HOME/.asdf/asdf.sh"' >> ~/.zshrc
```

%{
title: "Didn't find your shell here?",
description: ~H"""
Navigate to <.link navigate="https://asdf-vm.com/guide/getting-started.html#_3-install-asdf" target="\_blank">list of examples</.link> and look for the your shell in the official guide
"""
} %% .callout

After installing everything, open a new terminal and check that it is installed using `asdf version`. The version of your `asdf` doesn't matter.

```sh
$ asdf version
v0.10.0-77fd510
```

## Installing Erlang

`asdf` works through plugins. You need to install the Erlang plugin to be able to install versions of them:

```
asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git
```

%{
title: "Erlang can be very annoying to install",
type: :warning,
description: ~H"""
Depending on your operating system you may experience different headaches. I recommend taking a quick read <.link navigate="https://github.com/asdf-vm/asdf-erlang#before-asdf-install" target="\_blank">this area</.link> if you pass problems in the next step.
"""
} %% .callout

Let's install Erlang 26.2.2 and activate it globally.

```sh
asdf install erlang 26.2.2
asdf global erlang 26.2.2
```

## Installing Elixir

Unlike Erlang, this should be much simpler.

```sh
asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git
asdf install elixir 1.16.1-otp-26
asdf global elixir 1.16.1-otp-26
```

## Conclusion

At this point you should be able to run the following command:

```sh
$ elixir --version
Erlang/OTP 26 [erts-14.2.2] [source] [64-bit] [smp:10:10] [ds:10:10:10] [async-threads:1] [jit]

Elixir 1.16.1 (compiled with Erlang/OTP 26)
```

Congratulations, you're ready to start tinkering with LiveView!
