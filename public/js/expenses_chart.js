class ExpensesChart {
  #element

  constructor() {
    this.#element = $("#expenses-chart")

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
        if (!data.length) {
          return
        }

        data = data.map(item => {
          return {
            name: item.name,
            data: [Number(item.sum)]
          }
        })

        const options = {
          title: null,
          chart: {
            type: "column",
            spacing: [5, 0, 5, 0]
          },
          xAxis: {
            categories: ["Výdaje"]
          },
          yAxis: {
            title: null
          },
          tooltip: {
            valueSuffix: " Kč"
          },
          series: data
        }

        Highcharts.chart(this.#element.attr("id"), options)
      }
    )
  }
}

window.ExpensesChart = ExpensesChart
