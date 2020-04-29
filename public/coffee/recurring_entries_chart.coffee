class @RecurringEntriesChart
  constructor: ->
    @element = $('#recurring-entries-chart')

    return unless @element.length

    HighchartsConfig.init()
    @init()

  init: ->
    $.getJSON @element.data('url'), (data) =>
      categories = []
      series =
        expenses:
          name: 'Výdaje'
          color: '#C73C35'
          stacking: 'normal'
          index: 2
          data: []
        remainder:
          name: 'Polštář'
          color: '#108A00'
          stacking: 'normal'
          index: 1
          data: []
        predictedBalance:
          type: 'line'
          yAxis: 1
          name: 'Odhad bilance'
          color: '#fedd44'
          index: 3
          lineWidth: 4
          marker:
            symbol: 'circle'
            lineWidth: 4
            radius: 6
            lineColor: '#fedd44'
            fillColor: 'white'
          data: []
        balance:
          type: 'line'
          yAxis: 1
          name: 'Bilance'
          color: '#7cb5ec'
          index: 4
          lineWidth: 4
          marker:
            symbol: 'circle'
            lineWidth: 4
            radius: 6
            lineColor: '#7cb5ec'
            fillColor: 'white'
          data: []

      for month, item of data
        categories.push(month)

        expenses  = Number(item.expenses)
        remainder = Number(item.remainder)

        predictedBalance = if item.predicted_balance == null
          false
        else
          Number(item.predicted_balance)

        balance = if item.balance == null
          false
        else
          Number(item.balance)

        series.expenses.data.push(expenses)
        series.remainder.data.push(remainder)
        series.predictedBalance.data.push(predictedBalance)
        series.balance.data.push(balance)

      options =
        chart:
          type: 'column'
          height: 500
          spacing: [5, 0, 5, 0]
        title: null
        xAxis:
          categories: categories
        yAxis: [
          {
            title: null
          },
          {
            title: null,
            opposite: true
          }
        ]
        tooltip:
          pointFormat: '<span style="color:{series.color}">{series.name}</span>: <b>{point.y}</b><br/>',
          shared: true
        # plotOptions:
        #   series:
        #     stacking: 'normal'
        legend:
          enabled: false
        series: [series.expenses, series.remainder, series.predictedBalance, series.balance]
        credits:
          enabled: false

      Highcharts.chart(@element.attr('id'), options)
