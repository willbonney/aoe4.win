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

// *****
// *****
// *****
import Chart from "chart.js/auto";

let hooks = {};
hooks.OpponentsByCountry = {
  mounted() {
    const regionNamesInEnglish = new Intl.DisplayNames(["en"], {
      type: "region",
    });
    const ctx = this.el;
    const data = {
      type: "doughnut",
      data: {
        datasets: [
          {
            data: [],
            backgroundColor: [
              "#FFC107",
              "#FF9800",
              "#FF69B4",
              "#E91E63",
              "#9C27B0",
              "#673AB7",
              "#3F51B5",
              "#2196F3",
              "#03A9F4",
              "#00BCD4",
              "#009688",
              "#4CAF50",
              "#8BC34A",
              "#CDDC39",
              "#FFEB3B",
              "#FFC400",
              "#FFAB40",
              "#FF66CC",
              "#E64A19",
              "#795548",
              "#607D8B",
              "#455A64",
              "#37474F",
              "#263238",
              "#212121",
            ],
          },
        ],
        hoverOffset: 4,
        borderJoinStyle: "bevel",
      },
      options: {
        responsive: true,
        plugins: {
          tooltip: {
            callbacks: {
              label: function (context) {
                return `${context.formattedValue}%`;
              },
            },
          },
          legend: {
            position: "top",
          },
          title: {
            display: false,
            text: "Opponents by Country",
          },
        },
      },
    };
    const chart = new Chart(ctx, data);
    this.handleEvent("update-player", (event) => {
      console.log("event", event);
      chart.data.datasets[0].data = Object.values(event.byCountry);
      chart.data.labels = Object.keys(event.byCountry).map((twoLetterCountryCode) =>
        regionNamesInEnglish.of(twoLetterCountryCode.toUpperCase())
      );
      chart.update();
    });
  },
  beforeUnmount() {
    this.handleEvent("update-player", null);
  },
};
hooks.MovingAverages = {
  mounted() {
    const ctx = this.el;
    const data = {
      type: "line",
      data: {},
      options: {
        responsive: true,
        plugins: {
          // tooltip: {
          //   callbacks: {
          //     label: function (context) {
          //       return `${context.formattedValue}%`;
          //     },
          //   },
          // },
          legend: {
            position: "top",
          },
          title: {
            display: false,
            text: "Moving Average",
          },
        },
      },
    };
    const sortByDate = (unsorted) => unsorted.sort((a, b) => new Date(a.updated_at) - new Date(b.updated_at));
    const chart = new Chart(ctx, data);
    this.handleEvent("update-player", (event) => {
      console.log("event", event);
      const sorted = sortByDate(event.movingAverages);

      chart.data.datasets.push(
        {
          data: sortByDate(sorted).map(({ moving_average_5g }) => moving_average_5g),
          label: "5 Game",
        },
        {
          data: sortByDate(sorted).map(({ moving_average_10g }) => moving_average_10g),
          label: "10 Game",
        },
        {
          data: sortByDate(sorted).map(({ moving_average_20g }) => moving_average_20g),
          label: "20 Game",
        }
      );
      chart.data.labels = sorted.map((m) =>
        new Date(m.updated_at).toLocaleDateString("en-US", {
          month: "short",
          day: "numeric",
        })
      );
      chart.update();
    });
  },
  beforeUnmount() {
    this.handleEvent("update-player", null);
  },
};

// *****
// *****
// *****

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");

let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: hooks,
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

//.from https://medium.com/@lionel.aimerie/integrating-chart-js-into-elixir-phoenix-for-visual-impact-9a3991f0690f
