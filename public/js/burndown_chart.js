class BurndownChart {
  #element

  constructor() {
    this.#element = $("#burndown-chart")

    if (!this.#element.length) {
      return
    }

    HighchartsConfig.init()
    this.init()
  }

  init() {
    $.getJSON(
      this.#element.data("url"),
      data => {
        if (!data.length) {
          return
        }

        const series = {
          actual: {
            name: "Celkem",
            showInNavigator: true,
            color: "#7cb5ec",
            lineWidth: 4,
            type: "line",
            index: 3,
            marker: {
              lineWidth: 4,
              radius: 6,
              lineColor: "#7cb5ec",
              fillColor: "white"
            },
            data: []
          },

          unaccounted: {
            name: "Nezaúčtované",
            showInNavigator: false,
            color: "#f1c40f",
            lineWidth: 4,
            type: "line",
            index: 2,
            marker: {
              lineWidth: 4,
              radius: 6,
              lineColor: "#f1c40f",
              fillColor: "white"
            },
            data: []
          },

          target: {
            name: "Cíl",
            showInNavigator: false,
            color: "#dddddd",
            lineWidth: 4,
            type: "line",
            index: 1,
            marker: {
              lineWidth: 4,
              radius: 6,
              lineColor: "#dddddd",
              fillColor: "white"
            },
            data: []
          }
        }

        const plotLines = []

        for (const item of data) {
          const date = new Date(item.date)
          const timestamp = date.getTime()

          let balance = null
          if (item.balance !== null) {
            balance = Number(item.balance)
          }

          let targetBalance = null
          if (item.target_balance !== null) {
            targetBalance = Number(item.target_balance)
          }

          let balanceWithUnaccounted = null
          if (item.balance_with_unaccounted !== null) {
            balanceWithUnaccounted = Number(item.balance_with_unaccounted)
          }

          if (date.getDate() === 1) {
            const monthName = Highcharts.getOptions().lang.months[date.getMonth()]
            plotLines.push(this.#createPlotLine(timestamp, monthName))
          }

          series.actual.data.push([timestamp, balance])
          if (balanceWithUnaccounted !== null) {
            series.unaccounted.data.push([timestamp, balanceWithUnaccounted])
          }
          series.target.data.push([timestamp, targetBalance])
        }

        const options = {
          chart: {
            height: 500,
            spacing: [5, 0, 5, 0]
          },
          type: "line",
          xAxis: {
            plotLines: plotLines
          },
          series: [series.actual, series.unaccounted, series.target],
          rangeSelector: {
            buttons: [
              {
                type: "week",
                count: 1,
                text: "Týden"
              },
              {
                type: "all",
                text: "Vše"
              }
            ],
            selected: 1,
            inputBoxWidth: 100,
            inputDateFormat: "%B %Y",
            inputEditDateFormat: "%d. %m. %Y"
          },
          credits: {
            enabled: false
          }
        }

        Highcharts.stockChart(this.#element.attr("id"), options)
      }
    )
  }

  #createPlotLine(value, text) {
    return {
      color: "#e6e6e6",
      value: value,
      width: 1,
      label: {
        text: text,
        style: {
          color: "#cccccc"
        }
      }
    }
  }
}

window.BurndownChart = BurndownChart
