class @BalanceChart
  constructor: ->
    @element = $('#balances-chart')

    return unless @element.length

    HighchartsConfig.init()
    @init()

  init: ->
    $.getJSON @element.data('url'), (data) =>
      series =
        total:
          name: 'Celkem'
          showInNavigator: true
          color: '#7cb5ec'
          lineWidth: 4
          type: 'line'
          index: 4
          marker:
            lineWidth: 4
            radius: 6
            lineColor: '#7cb5ec'
            fillColor: 'white'
          data: []

        target:
          name: 'Cíl'
          showInNavigator: true
          color: '#fedd44'
          lineWidth: 4
          type: 'line'
          index: 3
          marker:
            lineWidth: 4
            radius: 6
            lineColor: '#fedd44'
            fillColor: 'white'
          data: []

        incomes:
          name: 'Příjmy'
          showInNavigator: false
          color: '#108A00'
          type: 'column'
          index: 1
          data: []

        expenses:
          name: 'Výdaje'
          showInNavigator: false
          color: '#C73C35'
          type: 'column'
          index: 2
          data: []

      for item in data
        date     = Date.parse(item.date)
        total    = Number(item.total)
        target   = Number(item.target) unless item.target == null
        incomes  = Number(item.incomes)
        expenses = Number(item.expenses)

        series.total.data.push([date, total])
        series.target.data.push([date, target])
        series.incomes.data.push([date, incomes])
        series.expenses.data.push([date, expenses])

      options =
        chart:
          height: 500
          spacing: [5, 0, 5, 0]
        type: 'line'
        series: [series.total, series.target, series.incomes, series.expenses]
        # plotOptions:
        #   series:
        #     animation: 500
        rangeSelector:
          buttons: [
            {
              type: 'year'
              count: 1
              text: 'Rok'
            },
            {
              type: 'all'
              text: 'Vše'
            }
          ]
          selected: 0
          inputBoxWidth: 100
          inputDateFormat: '%B %Y'
          inputEditDateFormat: '%d. %m. %Y'
        credits:
          enabled: false

      Highcharts.stockChart(@element.attr('id'), options)
