class @ExpensesChart
  constructor: ->
    @element = $('#expenses-chart')

    return unless @element.length

    HighchartsConfig.init()
    @init()

  init: ->
    $.getJSON @element.data('url'), (data) =>
      return unless data.length

      data = data.map (item) ->
        name: item.name
        data: [Number(item.sum)]

      options =
        title: null
        chart:
          type: 'column'
          spacing: [5, 0, 5, 0]
        xAxis:
          categories: ['Výdaje']
        yAxis:
          title: null
        tooltip:
          valueSuffix: ' Kč'
        # plotOptions:
        #   series:
        #     animation: 500
        series: data

      Highcharts.chart(@element.attr('id'), options)
