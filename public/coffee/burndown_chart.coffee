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
          index: 3
          marker:
            lineWidth: 4
            radius: 6
            lineColor: '#7cb5ec'
            fillColor: 'white'
          data: []

        unaccounted:
          name: 'Nezaúčtované'
          showInNavigator: false
          color: '#f1c40f'
          lineWidth: 4
          type: 'line'
          index: 2
          marker:
            lineWidth: 4
            radius: 6
            lineColor: '#f1c40f'
            fillColor: 'white'
          data: []

        target:
          name: 'Cíl'
          showInNavigator: false
          color: '#dddddd'
          lineWidth: 4
          type: 'line'
          index: 1
          marker:
            lineWidth: 4
            radius: 6
            lineColor: '#dddddd'
            fillColor: 'white'
          data: []

      plotLines = []

      for item in data
        date      = new Date(item.date)
        timestamp = date.getTime()

        balance = null
        balance = Number(item.balance) unless item.balance == null

        targetBalance = null
        targetBalance = Number(item.target_balance) unless item.target_balance == null

        balanceWithUnaccounted = null
        balanceWithUnaccounted = Number(item.balance_with_unaccounted) unless item.balance_with_unaccounted == null

        if date.getDate() == 1
          monthName = Highcharts.getOptions().lang.months[date.getMonth()]
          plotLines.push(@_createPlotLine(timestamp, monthName))

        series.actual.data.push([timestamp, balance])
        series.unaccounted.data.push([timestamp, balanceWithUnaccounted]) unless balanceWithUnaccounted == null
        series.target.data.push([timestamp, targetBalance])

      options =
        chart:
          height: 500
          spacing: [5, 0, 5, 0]
        type: 'line'
        xAxis:
          plotLines: plotLines
        series: [series.actual, series.unaccounted, series.target]
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
