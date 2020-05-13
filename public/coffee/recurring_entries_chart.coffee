class @RecurringEntriesChart
  constructor: ->
    @element = $('#recurring-entries-chart')

    return unless @element.length

    @dataCache = {}

    HighchartsConfig.init()
    @init()

    @buttons = $('.js-chart-button')
    @buttons.on('click', @_handleClick)

  init: ->
    @_loadData @element.data('url'), (data) =>
      @_loadChart(data)

  _handleClick: (e) =>
    $button = $(e.currentTarget)
    $otherButton = @buttons.not($button)

    url = $button.data('url')

    @_loadData url, (data) =>
      $button.addClass('active')
      $otherButton.removeClass('active')

      chartData = @_processChartData(data)

      @chart.series[1].setData(chartData.series.expenses.data)
      @chart.series[0].setData(chartData.series.remainder.data)
      @chart.series[2].setData(chartData.series.predictedBalance.data)
      @chart.series[3].setData(chartData.series.balance.data)

      @chart.xAxis[0].setCategories(chartData.categories)

      @chart.xAxis[0].removePlotLine('year-separator')

      $.each chartData.plotLines, (_, plotLine) =>
        @chart.xAxis[0].addPlotLine(plotLine)

  _loadData: (url, callback) ->
    if @dataCache[url]
      return callback(@dataCache[url])

    $.getJSON url, (data) =>
      @dataCache[url] = data
      callback(@dataCache[url])

  _loadChart: (data) ->
    chartData = @_processChartData(data)

    options =
      chart:
        type: 'column'
        height: 500
        spacing: [5, 0, 5, 0]
      title: null
      xAxis:
        categories: chartData.categories
        plotLines: chartData.plotLines
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
        pointFormat: '<span style="color:{series.color}">{series.name}</span>: <b>{point.y} Kč</b><br/>',
        shared: true
      # plotOptions:
      #   series:
      #     stacking: 'normal'
      legend:
        enabled: false
      series: [
        chartData.series.expenses,
        chartData.series.remainder,
        chartData.series.predictedBalance,
        chartData.series.balance
      ]
      credits:
        enabled: false

    @chart = Highcharts.chart(@element.attr('id'), options)

  _processChartData: (data) ->
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

    plotLines = []
    yearTmp   = null
    index     = 0

    for date, item of data
      date    = new Date(date)
      month   = Highcharts.getOptions().lang.months[date.getMonth()]
      year    = date.getFullYear()
      yearTmp = year unless yearTmp

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

      if year != yearTmp
        plotLines.push(@_createPlotLine(index - 0.5, date.getFullYear()))
        yearTmp = year

      series.expenses.data.push(expenses)
      series.remainder.data.push(remainder)
      series.predictedBalance.data.push(predictedBalance)
      series.balance.data.push(balance)
      index += 1

    {
      series: series
      categories: categories
      plotLines: plotLines
    }

  _createPlotLine: (value, text) ->
    {
      id: 'year-separator'
      color: '#e6e6e6'
      value: value
      width: 1
      label:
        text: text
        style:
          color: '#cccccc'
    }
