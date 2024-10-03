// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";
import darkModeHook from "../vendor/dark_mode";

let Hooks = {};

const readingProgressHook = {
  mounted(){
    window.addEventListener("scroll", () => {
      const height = document.documentElement.scrollHeight - document.documentElement.clientHeight;
      const scrollTop = document.body.scrollTop || document.documentElement.scrollTop;
      const readingProgress = Math.floor((scrollTop / height) * 100);

      this.pushEvent("reading_progress", readingProgress);
    });
  },
}

Hooks.DarkThemeToggle = darkModeHook;
Hooks.ReadingProgressHook = readingProgressHook;

window.addEventListener("copy_code_to_clipboard", (event) => {
  if ("clipboard" in navigator) {
    const text = event.target.innerText;
    navigator.clipboard.writeText(text);
  } else {
    alert("Sorry, your browser does not support clipboard copy.");
  }
});

window.addEventListener("phx:open_new_tab", (event) => {
  window.open(event.detail.url, "_blank").focus();
});
window.addEventListener("plausible", (event) => {
  window.plausible(event.detail.name, { props: event.detail.props });
});

window.addEventListener("scroll_to_top", (event) => {
  window.scrollTo(0, 0);
});

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
