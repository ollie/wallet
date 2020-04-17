class @RecurringExpensesChart
  constructor: ->
    @element = $('#recurring-expenses-chart')

    return unless @element.length

    HighchartsConfig.init()
    @init()

  init: ->
    $.getJSON @element.data('url'), (data) =>
      series =
        previous_period_expenses:
          name: 'Výdaje minulý rok'
          showInNavigator: true
          color: '#cccccc'
          type: 'column'
          index: 2
          data: []

        expenses:
          name: 'Výdaje'
          showInNavigator: true
          color: '#C73C35'
          type: 'column'
          index: 3
          data: []

      plotLines = []
      yearTmp   = null

      for item in data
        date      = new Date(item.date)
        year      = date.getFullYear()
        yearTmp  ?= year
        timestamp = date.getTime()

        previous_period_expenses = Number(item.previous_period_expenses)
        expenses = Number(item.expenses)

        if year != yearTmp
          plotLineTimestamp = Date.UTC(year, 0, 1)
          plotLines.push(@_createPlotLine(plotLineTimestamp, year))
          yearTmp = year

        series.previous_period_expenses.data.push([timestamp, previous_period_expenses])
        series.expenses.data.push([timestamp, expenses])

      options =
        chart:
          height: 500
          spacing: [5, 0, 5, 0]
        type: 'line'
        xAxis:
          plotLines: plotLines
        series: [series.previous_period_expenses, series.expenses]
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

  _createPlotLine: (value, text) ->
    {
      color: '#e6e6e6'
      value: value
      width: 1
      label:
        text: text
        style:
          color: '#cccccc'
    }
