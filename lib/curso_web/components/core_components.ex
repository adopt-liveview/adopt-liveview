defmodule CursoWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as modals, tables, and
  forms. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The default components use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn
  how to customize them or feel free to swap in another framework altogether.

  Icons are provided by [heroicons](https://heroicons.com). See `icon/1` for usage.
  """
  use Phoenix.Component
  use CursoWeb, :verified_routes

  alias Phoenix.LiveView.JS
  import CursoWeb.Gettext

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        This is a modal.
      </.modal>

  JS commands may be passed to the `:on_cancel` to configure
  the closing/cancel event, for example:

      <.modal id="confirm" on_cancel={JS.navigate(~p"/posts")}>
        This is another modal.
      </.modal>

  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div id={"#{@id}-bg"} class="bg-zinc-50/90 fixed inset-0 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-3xl p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="shadow-zinc-700/10 ring-zinc-700/10 relative hidden rounded-2xl bg-white p-14 shadow-lg ring-1 transition"
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-20 hover:opacity-40"
                  aria-label={gettext("close")}
                >
                  <.icon name="hero-x-mark-solid" class="h-5 w-5" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                <%= render_slot(@inner_block) %>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={[
        "fixed top-2 right-2 mr-2 w-80 sm:w-96 z-50 rounded-lg p-3 ring-1",
        @kind == :info && "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-cyan-900",
        @kind == :error && "bg-rose-50 text-rose-900 shadow-md ring-rose-500 fill-rose-900"
      ]}
      {@rest}
    >
      <p :if={@title} class="flex items-center gap-1.5 text-sm font-semibold leading-6">
        <.icon :if={@kind == :info} name="hero-information-circle-mini" class="h-4 w-4" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle-mini" class="h-4 w-4" />
        <%= @title %>
      </p>
      <p class="mt-2 text-sm leading-5"><%= msg %></p>
      <button type="button" class="group absolute top-1 right-1 p-2" aria-label={gettext("close")}>
        <.icon name="hero-x-mark-solid" class="h-5 w-5 opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id}>
      <.flash kind={:info} title={gettext("Success!")} flash={@flash} />
      <.flash kind={:error} title={gettext("Error!")} flash={@flash} />
      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error")}
        phx-connected={hide("#client-error")}
        hidden
      >
        <%= gettext("Attempting to reconnect") %>
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error")}
        phx-connected={hide("#server-error")}
        hidden
      >
        <%= gettext("Hang in there while we get back on track") %>
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="mt-10 space-y-8 bg-white">
        <%= render_slot(@inner_block, f) %>
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
          <%= render_slot(action, f) %>
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)
  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 rounded-lg bg-zinc-900 hover:bg-zinc-700 py-2 px-3",
        "text-sm font-semibold leading-6 text-white active:text-white/80",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @doc """
  Renders a link button.

  ## Examples

    <.link_button
      href={"https://www.github.com"}
      class="text-sky-500"
      target="_blank"
      rel="noopener noreferrer"
    >
      View Github
    </.link_button>
  """
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href target rel)
  slot :inner_block, required: true

  def link_button(assigns) do
    ~H"""
    <.link class={@class} {@rest}>
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
               range radio search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  slot :inner_block

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div phx-feedback-for={@name}>
      <label class="flex items-center gap-4 text-sm leading-6 text-zinc-600">
        <input type="hidden" name={@name} value="false" />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="rounded border-zinc-300 text-zinc-900 focus:ring-0"
          {@rest}
        />
        <%= @label %>
      </label>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <select
        id={@id}
        name={@name}
        class="mt-2 block w-full rounded-md border border-gray-300 bg-white shadow-sm focus:border-zinc-400 focus:ring-0 sm:text-sm"
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value=""><%= @prompt %></option>
        <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
      </select>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <textarea
        id={@id}
        name={@name}
        class={[
          "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
          "min-h-[6rem] phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
          "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="block text-sm font-semibold leading-6 text-zinc-800">
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="mt-3 flex gap-3 text-sm leading-6 text-rose-600 phx-no-feedback:hidden">
      <.icon name="hero-exclamation-circle-mini" class="mt-0.5 h-5 w-5 flex-none" />
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", @class]}>
      <div>
        <h1 class="text-lg font-semibold leading-8 text-zinc-800">
          <%= render_slot(@inner_block) %>
        </h1>
        <p :if={@subtitle != []} class="mt-2 text-sm leading-6 text-zinc-600">
          <%= render_slot(@subtitle) %>
        </p>
      </div>
      <div class="flex-none"><%= render_slot(@actions) %></div>
    </header>
    """
  end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
      <table class="w-[40rem] mt-11 sm:w-full">
        <thead class="text-sm text-left leading-6 text-zinc-500">
          <tr>
            <th :for={col <- @col} class="p-0 pb-4 pr-6 font-normal"><%= col[:label] %></th>
            <th :if={@action != []} class="relative p-0 pb-4">
              <span class="sr-only"><%= gettext("Actions") %></span>
            </th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700"
        >
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group hover:bg-zinc-50">
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={["relative p-0", @row_click && "hover:cursor-pointer"]}
            >
              <div class="block py-4 pr-6">
                <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50 sm:rounded-l-xl" />
                <span class={["relative", i == 0 && "font-semibold text-zinc-900"]}>
                  <%= render_slot(col, @row_item.(row)) %>
                </span>
              </div>
            </td>
            <td :if={@action != []} class="relative w-14 p-0">
              <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
                <span class="absolute -inset-y-px -right-4 left-0 group-hover:bg-zinc-50 sm:rounded-r-xl" />
                <span
                  :for={action <- @action}
                  class="relative ml-4 font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
                >
                  <%= render_slot(action, @row_item.(row)) %>
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <div class="mt-14">
      <dl class="-my-4 divide-y divide-zinc-100">
        <div :for={item <- @item} class="flex gap-4 py-4 text-sm leading-6 sm:gap-8">
          <dt class="w-1/4 flex-none text-zinc-500"><%= item.title %></dt>
          <dd class="text-zinc-700"><%= render_slot(item) %></dd>
        </div>
      </dl>
    </div>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div class="mt-16">
      <.link
        navigate={@navigate}
        class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
      >
        <.icon name="hero-arrow-left-solid" class="h-3 w-3" />
        <%= render_slot(@inner_block) %>
      </.link>
    </div>
    """
  end

  attr :class, :string, default: ""
  attr :locale, :string, default: "en"
  attr :pathname, :string, default: "/"
  attr :on_click, Phoenix.LiveView.JS, default: %Phoenix.LiveView.JS{}

  def navigation(assigns) do
    assigns =
      assign_new(assigns, :pathname, fn -> "/" end)
      |> assign(:items, Curso.Pages.content_map(assigns[:locale] || "en"))

    ~H"""
    <nav class={"text-base lg:text-sm #{@class}"}>
      <ul role="list" class="space-y-9">
        <%= for section <- @items do %>
          <li>
            <h2 class="font-display font-medium text-slate-900 dark:text-white">
              <%= section.title %>
            </h2>
            <ul
              role="list"
              class="mt-2 space-y-2 border-l-2 border-slate-100 lg:mt-4 lg:space-y-4 lg:border-slate-200 dark:border-slate-800"
            >
              <%= for link <- section.links do %>
                <li class="relative">
                  <.link
                    patch={link.href}
                    class={link_class(link.href, @pathname)}
                    phx-click={@on_click}
                  >
                    <%= link.title %>
                  </.link>
                </li>
              <% end %>
            </ul>
          </li>
        <% end %>
      </ul>
    </nav>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def prose(assigns) do
    assigns =
      assign_new(assigns, :total_classes, fn ->
        [
          assigns.class || "",
          "prose prose-slate max-w-none dark:prose-invert dark:text-slate-400",
          # headings
          "prose-headings:scroll-mt-28 prose-headings:font-display prose-headings:font-normal lg:prose-headings:scroll-mt-[8.5rem]",
          # lead
          "prose-lead:text-slate-500 dark:prose-lead:text-slate-400",
          # links
          "prose-a:font-semibold dark:prose-a:text-sky-400",
          # link underline
          "prose-a:no-underline prose-a:shadow-[inset_0_-2px_0_0_var(--tw-prose-background,#fff),inset_0_calc(-1*(var(--tw-prose-underline-size,4px)+2px))_0_0_var(--tw-prose-underline,theme(colors.sky.300))] hover:prose-a:[--tw-prose-underline-size:6px] dark:[--tw-prose-background:theme(colors.slate.900)] dark:prose-a:shadow-[inset_0_calc(-1*var(--tw-prose-underline-size,2px))_0_0_var(--tw-prose-underline,theme(colors.sky.800))] dark:hover:prose-a:[--tw-prose-underline-size:6px]",
          # pre
          "prose-pre:rounded-xl prose-pre:bg-slate-900 prose-pre:shadow-lg dark:prose-pre:bg-slate-800/60 dark:prose-pre:shadow-none dark:prose-pre:ring-1 dark:prose-pre:ring-slate-300/10",
          # hr
          "dark:prose-hr:border-slate-800"
        ]
        |> Enum.join(" ")
      end)

    ~H"""
    <div class={@total_classes} {@rest}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr :class, :string
  attr :rest, :global, include: ~w(phx-mounted)
  slot :inner_block, required: true

  def docs_layout(assigns) do
    ~H"""
    <div
      id="docs-layout"
      class={[
        "min-w-0 max-w-2xl flex-auto px-4 py-16 lg:max-w-none lg:pl-8 lg:pr-0 xl:px-16",
        @class
      ]}
    >
      <article>
        <%= render_slot(@inner_block) %>
      </article>
    </div>
    """
  end

  attr :type, :atom, default: :note

  def callout(assigns) do
    assigns =
      assign_new(assigns, :styles, fn ->
        mapper = %{
          note: %{
            container: "bg-sky-50 dark:bg-slate-800/60 dark:ring-1 dark:ring-slate-300/10",
            title: "text-sky-900 dark:text-sky-400",
            body:
              "text-sky-800 [--tw-prose-background:theme(colors.sky.50)] prose-a:text-sky-900 prose-code:text-sky-900 dark:text-slate-300 dark:prose-code:text-slate-300",
            icon: "hero-light-bulb-solid"
          },
          warning: %{
            container: "bg-amber-50 dark:bg-slate-800/60 dark:ring-1 dark:ring-slate-300/10",
            title: "text-amber-900 dark:text-amber-500",
            body:
              "text-amber-800 [--tw-prose-underline:theme(colors.amber.400)] [--tw-prose-background:theme(colors.amber.50)] prose-a:text-amber-900 prose-code:text-amber-900 dark:text-slate-300 dark:[--tw-prose-underline:theme(colors.sky.700)] dark:prose-code:text-slate-300",
            icon: "hero-exclamation-triangle-solid"
          }
        }

        mapper[assigns.type]
      end)

    ~H"""
    <div class={["my-8 flex rounded-3xl p-6", @styles.container]}>
      <.icon name={@styles.icon} class={"h-6 w-6 my-1 #{@styles.title}"} />
      <div class="ml-4 flex-auto">
        <p class={["m-0 font-display text-xl", @styles.title]}>
          <%= @title %>
        </p>
        <div class={["prose mt-2.5", @styles.body]}>
          <%= @description %>
        </div>
      </div>
    </div>
    """
  end

  attr :dir, :string, default: "next", values: ~w(previous next)
  attr :url, :string, default: nil
  slot :inner_block

  def page_link(assigns) do
    ~H"""
    <div class={@dir === "next" && "ml-auto text-right"}>
      <dt class="font-display text-sm font-medium text-slate-900 dark:text-white">
        <span :if={@dir === "previous"}><%= gettext("Previous") %></span>
        <span :if={@dir === "next"}><%= gettext("Next") %></span>
      </dt>
      <dd class="mt-1">
        <.link
          href={@url}
          class="flex items-center gap-x-1 text-base font-semibold text-slate-500 hover:text-slate-600 dark:text-slate-400 dark:hover:text-slate-300"
          phx-click={
            JS.dispatch("plausible", detail: %{name: "navigate_lesson", props: %{direction: @dir}})
          }
        >
          <.icon
            :if={@dir === "previous"}
            name="hero-arrow-right-solid"
            class="h-4 w-4 flex-none fill-current -scale-x-100"
          />

          <%= render_slot(@inner_block) %>

          <.icon
            :if={@dir === "next"}
            name="hero-arrow-right-solid"
            class="h-4 w-4 flex-none fill-current"
          />
        </.link>
      </dd>
    </div>
    """
  end

  attr :previous_page, Curso.Pages.Post, default: nil
  attr :next_page, Curso.Pages.Post, default: nil
  attr :locale, :string, default: "en"

  def prev_next_links(assigns) do
    ~H"""
    <div class="not-prose mt-12 flex border-t border-slate-200 pt-6 dark:border-slate-800">
      <.page_link
        :if={@previous_page}
        dir="previous"
        url={~p"/guides/#{@previous_page.id}/#{@locale}"}
      >
        <%= @previous_page.title %>
      </.page_link>
      <.page_link :if={@next_page} dir="next" url={~p"/guides/#{@next_page.id}/#{@locale}"}>
        <%= @next_page.title %>
      </.page_link>
    </div>
    """
  end

  attr :table_of_contents, :list, required: true

  def table_of_contents(assigns) do
    assigns =
      assign_new(assigns, :main, fn ->
        {_, href, title} = List.first(assigns.table_of_contents)
        %{href: href, title: title}
      end)

    assigns =
      assign_new(assigns, :toc, fn ->
        assigns.table_of_contents
        |> Enum.drop(1)
        |> Enum.reduce([], fn
          {2, href, title}, items ->
            [{href, title, []} | items]

          {_, href, title}, [{parent_href, parent_title, items} | rest] ->
            [{parent_href, parent_title, [{href, title} | items]} | rest]
        end)
        |> Enum.map(fn {href, title, items} ->
          {href, title, Enum.reverse(items)}
        end)
        |> Enum.reverse()
      end)

    ~H"""
    <nav class="w-56">
      <h2
        id="on-this-page-title"
        class="font-display text-sm font-medium text-slate-900 dark:text-white"
      >
        <%= @main.title %>
      </h2>
      <ol role="list" class="mt-4 space-y-3 text-sm">
        <li :for={{href, title, items} <- @toc}>
          <h3>
            <.link
              href={href}
              class="font-normal text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-300 !text-sky-500"
            >
              <%= title %>
            </.link>
          </h3>
          <ol role="list" class="mt-2 space-y-3 pl-5 text-slate-500 dark:text-slate-400">
            <li :for={{href, title} <- items} class="">
              <.link href={href} class="hover:text-slate-600 dark:hover:text-slate-300">
                <%= title %>
              </.link>
            </li>
          </ol>
        </li>
      </ol>
    </nav>
    """
  end

  @doc """
  Renders a Hero component.

  ## Examples
    <.hero
      title={"Road to Elixir"}
      description={"lorem ipsum dolor"}
      locale={assigns[:locale]}
    />
  """

  attr :title, :string
  attr :description, :string
  attr :locale, :string

  def hero(assigns) do
    ~H"""
    <div class="overflow-hidden bg-slate-900 dark:-mb-32 dark:mt-[-4.75rem] dark:pb-32 dark:pt-[4.75rem]">
      <div class="py-16 sm:px-2 lg:relative lg:px-0 lg:py-24">
        <div class="mx-auto flex flex-col max-w-2xl items-center gap-x-4 gap-y-12 px-4 lg:max-w-8xl lg:flex-row lg:px-6 xl:gap-x-8 xl:px-8">
          <div class="h-56 w-56">
            <img src="/images/sticker.png" alt={gettext("Adopt LiveView")} class="h-52 w-52 mx-auto" />
          </div>
          <div class="relative z-10 md:text-center lg:text-left col-span-4">
            <div class="relative">
              <p class="inline bg-gradient-to-r from-indigo-200 via-sky-400 to-indigo-200 bg-clip-text font-display text-5xl tracking-tight text-transparent">
                <%= @title %>
              </p>
              <p class="mt-3 text-2xl tracking-tight text-slate-400">
                <%= @description %>
              </p>
              <div class="mt-8 flex gap-4 md:justify-center lg:justify-start">
                <.link_button
                  href={~p"/guides/getting-started/#{@locale}"}
                  class="rounded-full bg-sky-300 py-2 px-4 text-sm font-semibold text-slate-900 hover:bg-sky-200 focus:outline-none focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-sky-300/50 active:bg-sky-500"
                >
                  <%= gettext("Get started") %>
                </.link_button>
              </div>
            </div>
          </div>
          <div class="relative lg:static xl:pl-10">
            <div class="absolute inset-x-[-50vw] -bottom-48 -top-32 [mask-image:linear-gradient(transparent,white,white)] lg:-bottom-32 lg:-top-32 lg:left-[calc(50%+14rem)] lg:right-0 lg:[mask-image:none] dark:[mask-image:linear-gradient(transparent,white,transparent)] lg:dark:[mask-image:linear-gradient(white,white,transparent)]">
              <.hero_background />
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def hero_background(assigns) do
    ~H"""
    <svg
      aria-hidden="true"
      viewBox="0 0 668 1069"
      width={668}
      height={1069}
      fill="none"
      class="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 lg:left-0 lg:translate-x-0 lg:translate-y-[-60%]"
    >
      <defs>
        <clipPath>
          <path fill="#fff" transform="rotate(-180 334 534.4)" d="M0 0h668v1068.8H0z" />
        </clipPath>
      </defs>
      <g opacity=".4" strokeWidth={4}>
        <path
          opacity=".3"
          d="M584.5 770.4v-474M484.5 770.4v-474M384.5 770.4v-474M283.5 769.4v-474M183.5 768.4v-474M83.5 767.4v-474"
          stroke="#334155"
        />
        <path
          d="M83.5 221.275v6.587a50.1 50.1 0 0 0 22.309 41.686l55.581 37.054a50.102 50.102 0 0 1 22.309 41.686v6.587M83.5 716.012v6.588a50.099 50.099 0 0 0 22.309 41.685l55.581 37.054a50.102 50.102 0 0 1 22.309 41.686v6.587M183.7 584.5v6.587a50.1 50.1 0 0 0 22.31 41.686l55.581 37.054a50.097 50.097 0 0 1 22.309 41.685v6.588M384.101 277.637v6.588a50.1 50.1 0 0 0 22.309 41.685l55.581 37.054a50.1 50.1 0 0 1 22.31 41.686v6.587M384.1 770.288v6.587a50.1 50.1 0 0 1-22.309 41.686l-55.581 37.054A50.099 50.099 0 0 0 283.9 897.3v6.588"
          stroke="#334155"
        />
        <path
          d="M384.1 770.288v6.587a50.1 50.1 0 0 1-22.309 41.686l-55.581 37.054A50.099 50.099 0 0 0 283.9 897.3v6.588M484.3 594.937v6.587a50.1 50.1 0 0 1-22.31 41.686l-55.581 37.054A50.1 50.1 0 0 0 384.1 721.95v6.587M484.3 872.575v6.587a50.1 50.1 0 0 1-22.31 41.686l-55.581 37.054a50.098 50.098 0 0 0-22.309 41.686v6.582M584.501 663.824v39.988a50.099 50.099 0 0 1-22.31 41.685l-55.581 37.054a50.102 50.102 0 0 0-22.309 41.686v6.587M283.899 945.637v6.588a50.1 50.1 0 0 1-22.309 41.685l-55.581 37.05a50.12 50.12 0 0 0-22.31 41.69v6.59M384.1 277.637c0 19.946 12.763 37.655 31.686 43.962l137.028 45.676c18.923 6.308 31.686 24.016 31.686 43.962M183.7 463.425v30.69c0 21.564 13.799 40.709 34.257 47.529l134.457 44.819c18.922 6.307 31.686 24.016 31.686 43.962M83.5 102.288c0 19.515 13.554 36.412 32.604 40.645l235.391 52.309c19.05 4.234 32.605 21.13 32.605 40.646M83.5 463.425v-58.45M183.699 542.75V396.625M283.9 1068.8V945.637M83.5 363.225v-141.95M83.5 179.524v-77.237M83.5 60.537V0M384.1 630.425V277.637M484.301 830.824V594.937M584.5 1068.8V663.825M484.301 555.275V452.988M584.5 622.075V452.988M384.1 728.537v-56.362M384.1 1068.8v-20.88M384.1 1006.17V770.287M283.9 903.888V759.85M183.699 1066.71V891.362M83.5 1068.8V716.012M83.5 674.263V505.175"
          stroke="#334155"
        />
        <circle
          cx="83.5"
          cy="384.1"
          r="10.438"
          transform="rotate(-180 83.5 384.1)"
          fill="#1E293B"
          stroke="#334155"
        />
        <circle
          cx="83.5"
          cy="200.399"
          r="10.438"
          transform="rotate(-180 83.5 200.399)"
          stroke="#334155"
        />
        <circle
          cx="83.5"
          cy="81.412"
          r="10.438"
          transform="rotate(-180 83.5 81.412)"
          stroke="#334155"
        />
        <circle
          cx="183.699"
          cy="375.75"
          r="10.438"
          transform="rotate(-180 183.699 375.75)"
          fill="#1E293B"
          stroke="#334155"
        />
        <circle
          cx="183.699"
          cy="563.625"
          r="10.438"
          transform="rotate(-180 183.699 563.625)"
          fill="#1E293B"
          stroke="#334155"
        />
        <circle
          cx="384.1"
          cy="651.3"
          r="10.438"
          transform="rotate(-180 384.1 651.3)"
          fill="#1E293B"
          stroke="#334155"
        />
        <circle
          cx="484.301"
          cy="574.062"
          r="10.438"
          transform="rotate(-180 484.301 574.062)"
          fill="#0EA5E9"
          fillOpacity=".42"
          stroke="#0EA5E9"
        />
        <circle
          cx="384.1"
          cy="749.412"
          r="10.438"
          transform="rotate(-180 384.1 749.412)"
          fill="#1E293B"
          stroke="#334155"
        />
        <circle
          cx="384.1"
          cy="1027.05"
          r="10.438"
          transform="rotate(-180 384.1 1027.05)"
          stroke="#334155"
        />
        <circle
          cx="283.9"
          cy="924.763"
          r="10.438"
          transform="rotate(-180 283.9 924.763)"
          stroke="#334155"
        />
        <circle
          cx="183.699"
          cy="870.487"
          r="10.438"
          transform="rotate(-180 183.699 870.487)"
          stroke="#334155"
        />
        <circle
          cx="283.9"
          cy="738.975"
          r="10.438"
          transform="rotate(-180 283.9 738.975)"
          fill="#1E293B"
          stroke="#334155"
        />
        <circle
          cx="83.5"
          cy="695.138"
          r="10.438"
          transform="rotate(-180 83.5 695.138)"
          fill="#1E293B"
          stroke="#334155"
        />
        <circle
          cx="83.5"
          cy="484.3"
          r="10.438"
          transform="rotate(-180 83.5 484.3)"
          fill="#0EA5E9"
          fillOpacity=".42"
          stroke="#0EA5E9"
        />
        <circle
          cx="484.301"
          cy="432.112"
          r="10.438"
          transform="rotate(-180 484.301 432.112)"
          fill="#1E293B"
          stroke="#334155"
        />
        <circle
          cx="584.5"
          cy="432.112"
          r="10.438"
          transform="rotate(-180 584.5 432.112)"
          fill="#1E293B"
          stroke="#334155"
        />
        <circle
          cx="584.5"
          cy="642.95"
          r="10.438"
          transform="rotate(-180 584.5 642.95)"
          fill="#1E293B"
          stroke="#334155"
        />
        <circle
          cx="484.301"
          cy="851.699"
          r="10.438"
          transform="rotate(-180 484.301 851.699)"
          stroke="#334155"
        />
        <circle
          cx="384.1"
          cy="256.763"
          r="10.438"
          transform="rotate(-180 384.1 256.763)"
          stroke="#334155"
        />
      </g>
    </svg>
    """
  end

  attr :title, :string, required: true
  attr :icon, :string, required: true
  attr :description, :string, default: nil
  attr :href, :string, required: false, default: nil
  attr :under_construction, :boolean, default: false
  attr :icon_class, :string, default: ""

  def quick_link(assigns) do
    ~H"""
    <div class="group relative rounded-xl border border-slate-200 dark:border-slate-800">
      <div
        :if={@under_construction == false}
        class="absolute -inset-px rounded-xl border-2 border-transparent opacity-0 [background:linear-gradient(var(--quick-links-hover-bg,theme(colors.sky.50)),var(--quick-links-hover-bg,theme(colors.sky.50)))_padding-box,linear-gradient(to_top,theme(colors.indigo.400),theme(colors.cyan.400),theme(colors.sky.500))_border-box] group-hover:opacity-100 dark:[--quick-links-hover-bg:theme(colors.slate.800)]"
      >
      </div>
      <div class="relative overflow-hidden rounded-xl p-6">
        <.icon name={@icon} class={"h-8 w-8 my-1 " <> @icon_class} />
        <h2 class="mt-4 font-display text-base text-slate-900 dark:text-white">
          <.link :if={@href} navigate={@href}>
            <span class="absolute -inset-px rounded-xl"></span>
            <%= @title %>
          </.link>
          <div :if={@under_construction}>
            <span class="absolute -inset-px rounded-xl"></span>
            <%= @title %>
          </div>
        </h2>
        <span :if={@under_construction} class="rounded-lg bg-red-500 text-white text-xs px-1.5 py-0.5">
          <%= gettext("Under construction") %>
        </span>
        <p class="mt-1 text-sm text-slate-700 dark:text-slate-400">
          <%= @description %>
        </p>
      </div>
    </div>
    """
  end

  @doc """
  Renders button that dispatchs a "copy_code_to_clipboard".

  ## Examples
    <.copy_button id="my-id" selector="[id=\"element-id\"]" />

  ## Note:

  Make sure your app.js contains this:

    window.addEventListener("copy_code_to_clipboard", (event) => {
      if ("clipboard" in navigator) {
        const text = event.target.innerText;
        navigator.clipboard.writeText(text);
      } else {
        alert("Sorry, your browser does not support clipboard copy.");
      }
    });
  """

  attr :id, :string, required: true, doc: "Unique ID for this component"
  attr :selector, :string, required: true, doc: "Element to be selected"
  attr :class, :string, default: "", doc: "Class for the button"

  def copy_button(assigns) do
    assigns = assign_new(assigns, :default_text_id, fn -> "#{assigns.id}-default-text" end)
    assigns = assign_new(assigns, :copied_text_id, fn -> "#{assigns.id}-copied-text" end)

    ~H"""
    <.button
      id={@id}
      type="button"
      class={
        "copy-button absolute whitespace-nowrap !py-1 !px-2 -top-4 right-3 !inline-flex items-center !bg-sky-500 " <> @class

      }
      phx-update="ignore"
      phx-click={
        JS.dispatch("copy_code_to_clipboard", to: @selector)
        |> JS.hide(to: "[id=\"#{@default_text_id}\"]")
        |> JS.show(to: "[id=\"#{@copied_text_id}\"]")
        |> JS.remove_class("!bg-sky-500", to: "[id=\"#{@id}\"]")
        |> JS.add_class("!bg-green-500", to: "[id=\"#{@id}\"]")
        |> JS.dispatch("plausible", detail: %{name: "copy_code", props: %{}})
      }
    >
      <span id={@default_text_id} class="block">
        <.icon name="hero-clipboard-solid" class="h-4 w-4" />
        <%= gettext("Copy") %>
      </span>
      <span id={@copied_text_id} class="hidden">
        <.icon name="hero-check-solid" class="h-4 w-4" />
        <%= gettext("Copied!") %>
      </span>
    </.button>
    """
  end

  attr :title, :string, default: nil
  attr :section, :string, default: nil
  attr :rest, :global, include: ~w(id)
  slot :inner_block

  def docs_header(assigns) do
    ~H"""
    <header class="mb-9 space-y-1" {@rest}>
      <p if={@section} class="font-display text-sm font-medium text-sky-500">
        <%= @section %>
      </p>
      <h1 if={@title} class="font-display text-3xl tracking-tight text-slate-900 dark:text-white">
        <%= @title %>
      </h1>

      <%= render_slot(@inner_block) %>
    </header>
    """
  end

  def show_mobile_navigation(js \\ %JS{}) do
    js
    |> JS.show(to: "#mobile-navigation")
    |> JS.add_class("overflow-hidden", to: "body")
  end

  def hide_mobile_navigation(js \\ %JS{}) do
    js
    |> JS.hide(to: "#mobile-navigation")
    |> JS.remove_class("overflow-hidden", to: "body")
  end

  def toggle_mobile_navigation(assigns) do
    ~H"""
    <button type="button" phx-click={show_mobile_navigation()}>
      <.icon name="hero-bars-3-solid" class="h-6 w-6 bg-slate-500 flex-none fill-current" />
    </button>
    """
  end

  def mobile_navigation(assigns) do
    ~H"""
    <div
      id="mobile-navigation"
      class="fixed inset-0 overflow-y-auto z-50 bg-slate-900/50 pr-10 backdrop-blur hidden"
    >
      <div
        phx-click-away={hide_mobile_navigation()}
        class="min-h-full w-full max-w-xs bg-white px-4 pb-12 pt-5 sm:px-6 dark:bg-slate-900"
      >
        <div class="flex items-center mb-2">
          <button id="mobile-navigation-close" type="button" phx-click={hide_mobile_navigation()}>
            <.icon name="hero-x-mark-solid" class="h-6 w-6 bg-slate-500 flex-none fill-current" />
          </button>
        </div>
        <.navigation
          pathname={assigns[:pathname]}
          locale={assigns[:locale]}
          on_click={JS.dispatch("click", to: "#mobile-navigation-close")}
        />
      </div>
    </div>
    """
  end

  defp link_class(href, pathname) when href == pathname,
    do:
      "block w-full pl-3.5 font-semibold text-sky-500 before:bg-sky-500 before:pointer-events-none before:absolute before:-left-1 before:top-1/2 before:h-1.5 before:w-1.5 before:-translate-y-1/2 before:rounded-full"

  defp link_class(_, _),
    do:
      "block w-full pl-3.5 text-slate-500 before:hidden before:bg-slate-300 hover:text-slate-600 hover:before:block dark:text-slate-400 dark:before:bg-slate-700 dark:hover:text-slate-300"

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in your `assets/tailwind.config.js`.

  ## Examples

      <.icon name="hero-x-mark-solid" />
      <.icon name="hero-arrow-path" class="ml-1 w-3 h-3 animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: nil

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  def toggle_locale(assigns) do
    ~H"""
    <button
      :for={lang <- ["br", "en"]}
      :if={@locale != lang}
      phx-click={JS.navigate("#{@base_url_for_locale}#{lang}")}
      type="button"
      aria-label={gettext("Toggle locale")}
      class="group rounded-lg bg-white/90 px-2 py-2 shadow-md shadow-black/5 ring-1 ring-black/5 backdrop-blur transition dark:bg-slate-700 dark:ring-inset dark:ring-white/5"
    >
      <img
        src={"/images/flags/#{@locale}.png"}
        alt={gettext("Toggle locale")}
        class="h-5 w-5 fill-zinc-700 stroke-zinc-500 transition dark:fill-teal-400/10 dark:stroke-teal-500"
      />
    </button>
    """
  end

  attr :title, :string, required: true
  attr :description, :string, default: nil
  attr :page_breadcumb_list, :string, default: nil
  attr :author, :string, default: "Lubien"
  attr :avatar, :string, default: "https://avatars.githubusercontent.com/u/9121359"
  attr :url, :string, default: "http://localhost:4000"
  attr :canonical, :string, required: true
  attr :theme, :string, default: "shadesOfPurple"

  def metadata_generator(assigns) do
    assigns =
      assign_new(assigns, :image_query, fn ->
        URI.encode_query(%{
          title: assigns.title,
          author: assigns.author,
          avatar: assigns.avatar,
          websiteUrl: assigns.url,
          theme: assigns.theme
        })
      end)

    ~H"""
    <link rel="canonical" href={@url} />
    <!-- Open Graph / Facebook -->
    <meta property="og:title" content={@title} />
    <meta property="og:type" content="website" />
    <meta property="og:url" content={@url} />
    <meta property="og:description" content={@description} />
    <meta
      property="og:image"
      content={"https://dynamic-og-image-generator.vercel.app/api/generate?#{@image_query}"}
    />
    <!-- Twitter -->
    <meta property="twitter:title" content={@title} />
    <meta property="twitter:card" content="summary_large_image" />
    <meta property="twitter:url" content={@url} />
    <meta property="twitter:description" content={@description} />
    <meta
      property="twitter:image"
      content={"https://dynamic-og-image-generator.vercel.app/api/generate?#{@image_query}"}
    />

    <script :if={@page_breadcumb_list} type="application/ld+json">
      <%= {:safe, @page_breadcumb_list} %>
    </script>
    """
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(CursoWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(CursoWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  @doc """
  Shows progress bar in the page header.
  """
  attr :progress, :integer, default: 0, doc: "Page reading progress"

  def progress_bar(assigns) do
    assigns |> dbg()

    ~H"""
    <div
      :if={@progress}
      class="h-1 bg-sky-300 w-full"
      id="progress-bar"
      phx-hook="ReadingProgress"
      style={"width: " <> Integer.to_string(@progress) <> "%"}
    >
    </div>
    """
  end
end
