defmodule CursoWeb.Feedback do
  use CursoWeb, :live_component

  @default_value %{"content" => ""}

  def update(assigns, socket) do
    form = to_form(@default_value, as: :feedback)
    {:ok, assign(socket, assigns) |> assign(form: form)}
  end

  def handle_event("validate", %{"feedback" => attrs}, socket) do
    form = to_form(attrs, as: :feedback)
    {:noreply, assign(socket, form: form)}
  end

  def handle_event(
        "send_to_github",
        %{"feedback" => feedback},
        %{assigns: %{page: page}} = socket
      ) do
    form = to_form(@default_value, as: :feedback)

    params = %{title: "Feedback about `#{page.id}`", body: feedback["content"]}

    url = "https://github.com/adopt-liveview/feedback/issues/new?#{URI.encode_query(params)}"

    {:noreply,
     assign(socket, form: form)
     |> push_event("open_new_tab", %{url: url})}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.form
        for={@form}
        class={@class}
        phx-target={@myself}
        phx-change="validate"
        phx-submit="send_to_github"
      >
        <div>
          <div class="mt-2">
            <div
              id="tabs-1-panel-1"
              class="-m-0.5 rounded-lg p-0.5"
              aria-labelledby="tabs-1-tab-1"
              role="tabpanel"
              tabindex="0"
            >
              <label for="comment" class="sr-only"><%= gettext("Feedback") %></label>
              <div>
                <.input
                  type="textarea"
                  field={@form[:content]}
                  rows="3"
                  class="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
                  placeholder={gettext("What's your feedback about this lesson?")}
                />
              </div>
            </div>
          </div>
        </div>
        <div class="mt-2 flex justify-end">
          <.button type="submit" phx-disable-with={gettext("Opening GitHub...")}>
            <%= gettext("Send to GitHub") %>
          </.button>
        </div>
      </.form>
    </div>
    """
  end
end
