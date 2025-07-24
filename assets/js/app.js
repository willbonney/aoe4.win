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

// from https://medium.com/@lionel.aimerie/integrating-chart-js-into-elixir-phoenix-for-visual-impact-9a3991f0690f

import Chart from "chart.js/auto";
import { easing } from "chart.js/helpers";

const MUI_COLORS = [
  "rgba(255, 193, 7, 1)", // #FFC107
  "rgba(255, 152, 0, 1)", // #FF9800
  "rgba(255, 105, 180, 1)", // #FF69B4
  "rgba(233, 30, 99, 1)", // #E91E63
  "rgba(156, 39, 176, 1)", // #9C27B0
  "rgba(103, 58, 183, 1)", // #673AB7
  "rgba(63, 81, 181, 1)", // #3F51B5
  "rgba(33, 150, 243, 1)", // #2196F3
  "rgba(3, 169, 244, 1)", // #03A9F4
  "rgba(0, 188, 212, 1)", // #00BCD4
  "rgba(0, 150, 136, 1)", // #009688
  "rgba(76, 175, 80, 1)", // #4CAF50
  "rgba(139, 195, 74, 1)", // #8BC34A
  "rgba(205, 220, 57, 1)", // #CDDC39
  "rgba(255, 235, 59, 1)", // #FFEB3B
  "rgba(255, 196, 0, 1)", // #FFC400
  "rgba(255, 171, 64, 1)", // #FFAB40
  "rgba(255, 102, 204, 1)", // #FF66CC
  "rgba(230, 74, 25, 1)", // #E64A19
  "rgba(121, 85, 72, 1)", // #795548
  "rgba(96, 125, 139, 1)", // #607D8B
  "rgba(69, 90, 100, 1)", // #455A64
  "rgba(55, 71, 79, 1)", // #37474F
  "rgba(38, 50, 56, 1)", // #263238
  "rgba(33, 33, 33, 1)", // #212121
];

const getMinutesFromBucket = (bucket) => {
  const bucketLabels = {
    _lt_600: "< 10 Minutes",
    _600_to_899: "10-15 Minutes",
    _900_to_1199: "15-20 Minutes",
    _1200_to_1499: "20-25 Minutes",
    _1500_to_1799: "25-30 Minutes",
    _1800_to_2099: "30-35 Minutes",
    _2100_to_2399: "35-40 Minutes",
    _2400_to_2999: "40-50 Minutes",
    _gt_3000: "> 50 Minutes",
  };

  const bucketOrder = Object.keys(bucketLabels);

  return { label: bucketLabels[bucket], order: bucketOrder.indexOf(bucket) };
};

const hooks = {};
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
            backgroundColor: MUI_COLORS,
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
              label: (context) => `${context.formattedValue}%`,
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
    this.handleEvent("update-opponents-by-country", (event) => {
      const threshold = 5; // Percentage threshold for "Other" category
      let otherPercentage = 0;
      const filteredData = Object.entries(event.byCountry).reduce((acc, [country, percentage]) => {
        if (percentage >= threshold) {
          acc[country] = percentage;
        } else {
          otherPercentage += percentage;
        }
        return acc;
      }, {});

      if (otherPercentage > 0) {
        filteredData.other = otherPercentage;
      }

      chart.data.datasets[0].data = Object.values(filteredData);
      chart.data.labels = Object.keys(filteredData).map((country) =>
        country === "other" ? "Other" : regionNamesInEnglish.of(country.toUpperCase())
      );
      chart.update();
    });
  },
  beforeUnmount() {
    this.handleEvent("update-opponents-by-country", null);
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

hooks.RankHistory = {
  mounted() {
    const ctx = this.el;
    const data = {
      type: "line",
      data: {},
      options: {
        responsive: true,
        layout: {
          padding: {
            right: 30,
          },
        },
        scales: {
          y: {
            reverse: true,
            min: 1,
            title: {
              display: true,
              text: "Rank",
            },
            ticks: {
              callback: function (value) {
                return `#${value.toFixed(0).toLocaleString()}`;
              },
            },
          },
          x: {
            // reverse: true, // Removed to fix animation direction
          },
        },
        plugins: {
          legend: {
            position: "top",
            display: false,
          },
          title: {
            display: false,
            text: "Rank History",
          },
        },
      },
    };

    // // Animation configuration - moved after data declaration
    // const totalDuration = 10000;
    // const delayBetweenPoints = 300;
    // const previousY = (ctx) => ctx.index === 0 ? ctx.chart.scales.y.getPixelForValue(50) : ctx.chart.getDatasetMeta(ctx.datasetIndex).data[ctx.index - 1].getProps(['y'], true).y;
    // const animation = {
    // 	x: {
    // 		type: 'number',
    // 		easing: 'linear',
    // 		duration: delayBetweenPoints,
    // 		from: NaN, // the point is initially skipped
    // 		delay(ctx) {
    // 			if (ctx.type !== 'data' || ctx.xStarted) {
    // 				return 0;
    // 			}
    // 			ctx.xStarted = true;
    // 			return ctx.index * delayBetweenPoints;
    // 		}
    // 	},
    // 	y: {
    // 		type: 'number',
    // 		easing: 'linear',
    // 		duration: delayBetweenPoints,
    // 		from: previousY,
    // 		delay(ctx) {
    // 			if (ctx.type !== 'data' || ctx.yStarted) {
    // 				return 0;
    // 			}
    // 			ctx.yStarted = true;
    // 			return ctx.index * delayBetweenPoints;
    // 		}
    // 	}
    // };
    console.log("data", data);

    const previousY = (ctx) =>
      ctx.index === 0
        ? ctx.chart.scales.y.getPixelForValue(50)
        : ctx.chart.getDatasetMeta(ctx.datasetIndex).data[ctx.index - 1].getProps(["y"], true).y;

    const getAnimation = (firstSeason, dataLength) => {
      const easeOutQuad = easing.easeOutQuad;
      const totalDuration = 2000;
      const duration = (ctx) => (easeOutQuad(ctx.index / dataLength) * totalDuration) / dataLength;
      const delay = (ctx) => easeOutQuad(ctx.index / dataLength) * totalDuration;

      return {
        x: {
          type: "number",
          easing: "linear",
          duration: duration,
          from: NaN, // the point is initially skipped
          delay(ctx) {
            if (ctx.type !== "data" || ctx.xStarted) {
              return 0;
            }
            ctx.xStarted = true;
            return delay(ctx);
          },
        },
        y: {
          type: "number",
          easing: "linear",
          duration: duration,
          from: previousY,
          delay(ctx) {
            if (ctx.type !== "data" || ctx.yStarted) {
              return 0;
            }
            ctx.yStarted = true;
            return delay(ctx);
          },
        },
      };
    };

    const chart = new Chart(ctx, data);
    this.handleEvent("update-player", (event) => {
      const rankData = event.rankHistory.map(({ rank, season }) => rank).reverse();
      const maxRankValue = Math.max(...rankData);

      data.options.animation = getAnimation(event.rankHistory[0].season, rankData.length);
      chart.data.datasets.push({
        data: rankData,
        label: "Rank",
        pointStyle: "circle",
        pointRadius: 10,
        pointHoverRadius: 15,
        fill: false,
        stepped: true,
        borderColor: MUI_COLORS[1],
        backgroundColor: MUI_COLORS[1],
      });
      chart.data.labels = event.rankHistory.map((m) => `Season ${m.season}`);

      chart.options.scales.y.max = 1.2 * maxRankValue;
      chart.update();
    });
  },
  beforeUnmount() {
    this.handleEvent("update-player", null);
  },
};

hooks.WrsByGameLength = {
  mounted() {
    const ctx = this.el;
    const data = {
      type: "bar",
      data: {},

      options: {
        responsive: true,
        scales: {
          y: {
            title: {
              display: true,
              text: "Win %",
            },
            beginAtZero: true,
          },
        },
        plugins: {
          legend: {
            display: false,
          },
          tooltip: {
            callbacks: {
              label: (context) => `${context.formattedValue}%`,
            },
          },
          title: {
            display: false,
            text: "WRs by Game Length",
          },
        },
      },
    };

    const chart = new Chart(ctx, data);
    this.handleEvent("update-wrs", (event) => {
      console.log("event", event);
      const split = Object.entries(event.byLength);
      const sortedSplit = split.sort((a, b) => getMinutesFromBucket(a[0]).order - getMinutesFromBucket(b[0]).order);

      chart.data.datasets.push({
        data: sortedSplit.map(([length, wr]) => wr),
        label: "Win Rate",
        borderColor: MUI_COLORS.slice(0, sortedSplit.length),
        backgroundColor: MUI_COLORS.map((color) => `${color.slice(0, -4)}, 0.4)`).slice(0, sortedSplit.length),
        borderWidth: 1,
        barThickness: 50,
      });
      chart.data.labels = sortedSplit.map(([length]) => getMinutesFromBucket(length).label);
      chart.update();
    });
  },
  beforeUnmount() {
    this.handleEvent("update-wrs", null);
  },
};

// *****
// *****
// *****

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");

const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: hooks,
});
// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#273649" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;

// *****
// *****
// *****

// from https://fly.io/phoenix-files/copy-to-clipboard-with-phoenix-liveview/

window.addEventListener("phx:copy", (event) => {
  let text = event.target.value;

  navigator.clipboard
    .writeText(text)
    .then(() => {})
    .catch((err) => {});
});
