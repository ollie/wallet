class BalanceChart {
  #element

  constructor() {
    this.#element = $("#balances-chart")

    if (!this.#element.length) {
      return
    }

    HighchartsConfig.init()
    this.#init()
  }

  #init() {
    $.getJSON(
      this.#element.data("url"),
      data => {
        const series = {
          total: {
            name: "Celkem",
            showInNavigator: true,
            color: "#7cb5ec",
            lineWidth: 4,
            type: "line",
            index: 4,
            marker: {
              lineWidth: 4,
              radius: 6,
              lineColor: "#7cb5ec",
              fillColor: "white",
            },
            data: []
          },

          target: {
            name: "Cíl",
            showInNavigator: true,
            color: "#fedd44",
            lineWidth: 4,
            type: "line",
            index: 3,
            marker: {
              lineWidth: 4,
              radius: 6,
              lineColor: "#fedd44",
              fillColor: "white",
            },
            data: []
          },

          incomes: {
            name: "Příjmy",
            showInNavigator: false,
            color: "#108A00",
            type: "column",
            index: 1,
            data: []
          },

          expenses: {
            name: "Výdaje",
            showInNavigator: false,
            color: "#C73C35",
            type: "column",
            index: 2,
            data: []
          }
        }

        let plotLines = []
        let yearTmp = null

        for (const item of data) {
          const date = new Date(item.date)
          const year = date.getFullYear()
          yearTmp = yearTmp !== null ? yearTmp : year
          const timestamp = date.getTime()

          const total = Number(item.total)
          const target = item.target !== null ? Number(item.target) : undefined
          const incomes = Number(item.incomes)
          const expenses = Number(item.expenses)

          if (year !== yearTmp) {
            const plotLineTimestamp = Date.UTC(year, 0, 1)
            plotLines.push(this.#createPlotLine(plotLineTimestamp, year))
            yearTmp = year
          }

          series.total.data.push([timestamp, total])
          series.target.data.push([timestamp, target])
          series.incomes.data.push([timestamp, incomes])
          series.expenses.data.push([timestamp, expenses])
        }

        const options = {
          chart: {
            height: 500,
            spacing: [5, 0, 5, 0],
          },
          type: "line",
          xAxis: {
            plotLines: plotLines
          },
          series: [series.total, series.target, series.incomes, series.expenses],
          rangeSelector: {
            buttons: [
              {
                type: "year",
                count: 1,
                text: "Rok"
              },
              {
                type: "all",
                text: "Vše"
              }
            ],
            selected: 0,
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

window.BalanceChart = BalanceChart
