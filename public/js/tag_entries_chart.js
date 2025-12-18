class TagEntriesChart {
  #element

  constructor() {
    this.#element = $("#tag-entries-chart")

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
            color: "#fedd44",
            lineWidth: 4,
            type: "line",
            index: 1,
            marker: {
              lineWidth: 4,
              radius: 6,
              lineColor: "#fedd44",
              fillColor: "white"
            },
            data: []
          },

          incomes: {
            name: "Příjmy",
            showInNavigator: true,
            color: "#108A00",
            lineWidth: 4,
            type: "line",
            index: 2,
            marker: {
              lineWidth: 4,
              radius: 6,
              lineColor: "#108A00",
              fillColor: "white"
            },
            data: []
          },

          expenses: {
            name: "Výdaje",
            showInNavigator: true,
            color: "#C73C35",
            lineWidth: 4,
            type: "line",
            index: 3,
            marker: {
              lineWidth: 4,
              radius: 6,
              lineColor: "#C73C35",
              fillColor: "white"
            },
            data: []
          }
        }

        const plotLines = []
        let yearTmp = null

        for (const item of data) {
          const date = new Date(item.date)
          const year = date.getFullYear()
          yearTmp = yearTmp !== null ? yearTmp : year
          const timestamp = date.getTime()

          const total = Number(item.total)
          const incomes = Number(item.incomes)
          const expenses = Number(item.expenses)

          if (year !== yearTmp) {
            const plotLineTimestamp = Date.UTC(year, 0, 1)
            plotLines.push(this.#createPlotLine(plotLineTimestamp, year))
            yearTmp = year
          }

          series.total.data.push([timestamp, total])
          series.incomes.data.push([timestamp, incomes])
          series.expenses.data.push([timestamp, expenses])
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
          series: [series.total, series.incomes, series.expenses],
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

window.TagEntriesChart = TagEntriesChart
