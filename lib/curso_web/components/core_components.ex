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
          class=" flex items-center gap-x-1 text-base font-semibold text-slate-500 hover:text-slate-600 dark:text-slate-400 dark:hover:text-slate-300"
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
      image={"https://i.imgur.com/2St7UBs.jpg"}
    />
  """

  attr :title, :string
  attr :description, :string
  # attr :image, :string

  # WIP
  def hero(assigns) do
    ~H"""
    <div class="overflow-hidden bg-slate-900 dark:-mb-32 dark:mt-[-4.75rem] dark:pb-32 dark:pt-[4.75rem]">
      <div class="py-16 sm:px-2 lg:relative lg:px-0 lg:py-20">
        <div class="mx-auto grid max-w-2xl grid-cols-1 items-center gap-x-8 gap-y-16 px-4 lg:max-w-8xl lg:grid-cols-2 lg:px-8 xl:gap-x-16 xl:px-12">
          <div class="relative z-10 md:text-center lg:text-left">
            <div class="relative">
              <p class="inline bg-gradient-to-r from-indigo-200 via-sky-400 to-indigo-200 bg-clip-text font-display text-5xl tracking-tight text-transparent">
                <%= @title %>
              </p>
              <p class="mt-3 text-2xl tracking-tight text-slate-400">
                <%= @description %>
              </p>
              <div class="mt-8 flex gap-4 md:justify-center lg:justify-start">
                <.link_button
                  href="/"
                  class="rounded-full bg-sky-300 py-2 px-4 text-sm font-semibold text-slate-900 hover:bg-sky-200 focus:outline-none focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-sky-300/50 active:bg-sky-500"
                >
                  Get Started
                </.link_button>

                <.link_button
                  href="/"
                  class="rounded-full bg-slate-800 py-2 px-4 text-sm font-medium text-white hover:bg-slate-700 focus:outline-none focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-white/50 active:text-slate-400"
                >
                  View Github
                </.link_button>
              </div>
            </div>
          </div>
        </div>
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

  def copy_button(assigns) do
    assigns = assign_new(assigns, :default_text_id, fn -> "#{assigns.id}-default-text" end)
    assigns = assign_new(assigns, :copied_text_id, fn -> "#{assigns.id}-copied-text" end)

    ~H"""
    <.button
      id={@id}
      type="button"
      class="copy-button absolute whitespace-nowrap !py-1 !px-2 -top-4 right-3 !inline-flex items-center !bg-sky-500"
      phx-update="ignore"
      phx-click={
        JS.dispatch("copy_code_to_clipboard", to: @selector)
        |> JS.hide(to: "[id=\"#{@default_text_id}\"]")
        |> JS.show(to: "[id=\"#{@copied_text_id}\"]")
        |> JS.remove_class("!bg-sky-500", to: "[id=\"#{@id}\"]")
        |> JS.add_class("!bg-green-500", to: "[id=\"#{@id}\"]")
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
      phx-click={JS.navigate(~p"/guides/#{@page.id}/#{lang}")}
      type="button"
      aria-label="Toggle locale"
      class="group rounded-lg bg-white/90 px-2 py-2 shadow-md shadow-black/5 ring-1 ring-black/5 backdrop-blur transition dark:bg-slate-700 dark:ring-inset dark:ring-white/5"
    >
      <img
        src={"/images/flags/#{@locale}.png"}
        class="h-5 w-5 fill-zinc-700 stroke-zinc-500 transition dark:fill-teal-400/10 dark:stroke-teal-500"
      />
    </button>
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
end
