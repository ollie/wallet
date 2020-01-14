class @BurndownChart
  constructor: ->
    @element = $('#burndown-chart')

    return unless @element.length

    HighchartsConfig.init()
    @init()

  init: ->
    $.getJSON @element.data('url'), (data) =>
      return unless data.length

      series =
        actual:
          name: 'Celkem'
          showInNavigator: true
          color: '#7cb5ec'
          lineWidth: 4
          type: 'line'
          index: 2
          marker:
            lineWidth: 4
            radius: 6
            lineColor: '#7cb5ec'
            fillColor: 'white'
          data: []

        target:
          name: 'Cíl'
          showInNavigator: false
          color: '#fedd44'
          lineWidth: 2
          type: 'line'
          index: 1
          marker:
            lineWidth: 4
            radius: 6
            lineColor: '#fedd44'
            fillColor: 'white'
          data: []

      plotLines = []

      for item in data
        date      = new Date(item.date)
        timestamp = date.getTime()

        balance = if item.balance == null
          null
        else
          Number(item.balance)
        target_balance = if item.target_balance == null
          null
        else
          Number(item.target_balance)

        if date.getDate() == 1
          monthName = Highcharts.getOptions().lang.months[date.getMonth()]
          plotLines.push(@_createPlotLine(timestamp, monthName))

        series.actual.data.push([timestamp, balance])
        series.target.data.push([timestamp, target_balance])

      options =
        chart:
          height: 500
          spacing: [5, 0, 5, 0]
        type: 'line'
        xAxis:
          plotLines: plotLines
        series: [series.actual, series.target]
        # plotOptions:
        #   series:
        #     animation: 500
        rangeSelector:
          buttons: [
            {
              type: 'week'
              count: 1
              text: 'Týden'
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
