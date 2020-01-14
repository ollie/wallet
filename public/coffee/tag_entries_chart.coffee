class @TagEntriesChart
  constructor: ->
    @element = $('#tag-entries-chart')

    return unless @element.length

    HighchartsConfig.init()
    @init()

  init: ->
    $.getJSON @element.data('url'), (data) =>
      series =
        total:
          name: 'Celkem'
          showInNavigator: true
          color: '#fedd44'
          lineWidth: 4
          type: 'line'
          index: 1
          marker:
            lineWidth: 4
            radius: 6
            lineColor: '#fedd44'
            fillColor: 'white'
          data: []

        incomes:
          name: 'Příjmy'
          showInNavigator: true
          color: '#108A00'
          lineWidth: 4
          type: 'line'
          index: 2
          marker:
            lineWidth: 4
            radius: 6
            lineColor: '#108A00'
            fillColor: 'white'
          data: []

        expenses:
          name: 'Výdaje'
          showInNavigator: true
          color: '#C73C35'
          lineWidth: 4
          type: 'line'
          index: 3
          marker:
            lineWidth: 4
            radius: 6
            lineColor: '#C73C35'
            fillColor: 'white'
          data: []

      plotLines = []
      yearTmp   = null

      for item in data
        date      = new Date(item.date)
        year      = date.getFullYear()
        yearTmp  ?= year
        timestamp = date.getTime()

        total    = Number(item.total)
        incomes  = Number(item.incomes)
        expenses = Number(item.expenses)

        if year != yearTmp
          plotLineTimestamp = Date.UTC(year, 0, 1)
          plotLines.push(@_createPlotLine(plotLineTimestamp, year))
          yearTmp = year

        series.total.data.push([timestamp, total])
        series.incomes.data.push([timestamp, incomes])
        series.expenses.data.push([timestamp, expenses])

      options =
        chart:
          height: 500
          spacing: [5, 0, 5, 0]
        type: 'line'
        xAxis:
          plotLines: plotLines
        series: [series.total, series.incomes, series.expenses]
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
          selected: 1
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
