class Confirm
  constructor: ->
    $items = $('[data-confirm]')
    $items.on('click', this._handleClick)

  _handleClick: (e) =>
    $item   = $(e.currentTarget)
    message = $item.data('confirm')

    if message && !confirm(message)
      e.preventDefault()



class HighchartsConfig
  constructor: ->
    Highcharts.setOptions
      credits:
        enabled: false
      lang:
        contextButtonTitle: 'Kontextové menu'
        decimalPoint: ','
        downloadCSV: 'Stáhnout CSV'
        downloadJPEG: 'Stáhnout JPEG'
        downloadPDF: 'Stáhnout PDF'
        downloadPNG: 'Stáhnout PNG'
        downloadSVG: 'Stáhnout SVG'
        downloadXLS: 'Stáhnout XLS'
        invalidDate: undefined
        loading: 'Načítám…'
        months: ['Leden' , 'Únor' , 'Březen' , 'Duben' , 'Květen' , 'Červen' , 'Červenec' , 'Srpen' , 'Září' , 'Říjen' , 'Listopad' , 'Prosinec']
        noData: 'Žádná data k zobrazení'
        numericSymbolMagnitude: 1000
        numericSymbols: ['k' , 'M' , 'G' , 'T' , 'P' , 'E']
        openInCloud: 'Otevřít v Highcharts Cloud'
        printChart: 'Tisknout'
        rangeSelectorFrom: 'Od'
        rangeSelectorTo: 'Do'
        rangeSelectorZoom: 'Zoom'
        resetZoom: 'Vyresetovat zoom'
        resetZoomTitle: 'Vyresetovat zoom na 1:1'
        shortMonths: ['Led' , 'Úno' , 'Bře' , 'Dub' , 'Kvě' , 'Čvn' , 'Čvc' , 'Spr' , 'Zář' , 'Říj' , 'Lis' , 'Pro']
        shortWeekdays: undefined
        thousandsSep: ' '
        weekdays: ['Neděle', 'Pondělí', 'Úterý', 'Středa', 'Čtvrtek', 'Pátek', 'Sobota']



class EntryForm
  constructor: ->
    @expenseButton = $('.js-expense')

    return unless @expenseButton.length

    @incomeButton     = $('.js-income')
    @amount           = $('.js-amount')
    @accountedOnInput = $('#entry-accounted_on')
    @dateInput        = $('#entry-date')
    @copyDate         = $('.js-copy-date')
    @todayDate        = $('.js-today-date')
    @tagCombinations  = $('.js-tag-combination')

    @expenseButton.on('click', @_handleExpenseButtonClick)
    @incomeButton.on('click', @_handleIncomeButtonClick)
    @amount.on('input', @_handleAmountInput)
    @copyDate.on('click', @_handleCopyDateClick)
    @todayDate.on('click', @_handleTodayDateClick)
    @tagCombinations.on('click', @_handleTagCombinationClick)

    @select = $('.js-selectize').selectize()

  _handleExpenseButtonClick: =>
    value = Number(@amount.val())

    @amount.val(-value) if value > 0

    @amount
      .data('type', 'expense')
      .focus()

    @expenseButton
      .addClass('btn-danger active')
      .removeClass('btn-default')

    @incomeButton
      .removeClass('btn-success active')
      .addClass('btn-default')

  _handleIncomeButtonClick: =>
    value = Number(@amount.val())

    @amount.val(-value) if value < 0

    @amount
      .data('type', 'income')
      .focus()

    @incomeButton
      .addClass('btn-success active')
      .removeClass('btn-default')

    @expenseButton
      .removeClass('btn-danger active')
      .addClass('btn-default')

  _handleAmountInput: =>
    value = @amount.val()

    return if value == ''

    number = Number(value)

    if (@amount.data('type') == 'expense' && number > 0) ||
    (@amount.data('type') == 'income' && number < 0)
      @amount.val(-value)

  _handleCopyDateClick: =>
    date = @dateInput.val()

    unless date
      @dateInput.focus()
      return

    @accountedOnInput
      .val(date)
      .focus()

  _handleTodayDateClick: =>
    today = new Date
    today = today.toISOString().substr(0, 10)

    @dateInput.val(today)
    @accountedOnInput
      .val(today)
      .focus()

  _handleTagCombinationClick: (e) =>
    e.preventDefault()

    $link  = $(e.currentTarget)
    tagIds = $link
      .find('[data-tag-id]')
      .map (_, tag) ->
        $(tag).data('tag-id')
      .toArray()

    @select[0].selectize.setValue(tagIds)



class Tags
  constructor: ->
    $tags = $('.js-tags')

    return unless $tags.length

    tagsHtml = $tags.html()

    $tags.sortable
      axis: 'y'
      containment: 'parent'
      handle: '.js-sortable-handle'
      tolerance: 'pointer'
      update: ->
        changes = {}

        $tags.find('li').each (i) ->
          newPosition = i + 1
          $tag        = $(this)
          oldPosition = $tag.data('position')

          return if newPosition == oldPosition

          $tag.attr('data-position', newPosition)
          changes[$tag.data('id')] = newPosition

        return if $.isEmptyObject(changes)

        $.ajax(
          $tags.data('path'),
          method: 'POST'
          data:
            positions: changes
          error: ->
            $tags.html(tagsHtml)
          success: ->
            tagsHtml = $tags.html()
        )



class ExpenseChart
  constructor: ->
    @element = $('#chart')

    return unless @element.length

    @init()

  init: ->
    $.getJSON @element.data('url'), (data) =>
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



class BalanceDiff
  constructor: ->
    @elements = $('.js-balance-diff')

    return unless @elements.length

    @diff  = $('#balance-diff')
    @items = []

    @elements.on('click', @_handleClick)

  _handleClick: (e) =>
    $input = $(e.currentTarget)

    unless $input.is(':checked')
      @_removeItem($input)
      return

    date   = Date.parse($input.data('date'))
    amount = Number($input.val())

    item =
      input:  $input
      amount: amount
      date:   date

    @_addItem(item)
    @_calculate()

  _addItem: (item) ->
    switch @items.length
      when 0
        @items.push(item)
      when 1
        if item.date > @items[0].date
          @items.unshift(item)
        else
          @items.push(item)
      else
        i.input.prop('checked', false) for i in @items
        @items = []
        @items.push(item)

  _removeItem: ($input) ->
    for item in @items
      item.input.prop('checked', false)

    @items = []
    $input.trigger('click')

  _calculate: ->
    if @items.length < 2
      @diff.text('')
      return

    diff  = @items[0].amount - @items[1].amount
    parts = parseFloat(diff).toFixed(2).split('.')

    parts[0] = parts[0].replace(/(\d)(?=(\d\d\d)+(?!\d))/g, '$1 ')
    textDiff = "#{parts.join(',')} Kč"

    textDiff = "+#{textDiff}" if diff >= 0

    @diff.text(textDiff)



class BalanceChart
  constructor: ->
    @element = $('#balances-chart')

    return unless @element.length

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
          index: 3
          marker:
            lineWidth: 4
            radius: 6
            lineColor: '#7cb5ec'
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
        incomes  = Number(item.incomes)
        expenses = Number(item.expenses)

        series.total.data.push([date, total])
        series.incomes.data.push([date, incomes])
        series.expenses.data.push([date, expenses])

      options =
        chart:
          height: 500
          spacing: [5, 0, 5, 0]
        type: 'line'
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
          selected: 0
          inputBoxWidth: 100
          inputDateFormat: '%B %Y'
          inputEditDateFormat: '%d. %m. %Y'
        credits:
          enabled: false

      Highcharts.stockChart(@element.attr('id'), options)



class TagEntriesChart
  constructor: ->
    @element = $('#tag-entries-chart')

    return unless @element.length

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

      for item in data
        date     = Date.parse(item.date)
        total    = Number(item.total)
        incomes  = Number(item.incomes)
        expenses = Number(item.expenses)

        series.total.data.push([date, total])
        series.incomes.data.push([date, incomes])
        series.expenses.data.push([date, expenses])

      options =
        chart:
          height: 500
          spacing: [5, 0, 5, 0]
        type: 'line'
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



class BalanceForm
  constructor: ->
    @balanceAmountInput = $('#balance-amount')

    return unless @balanceAmountInput.length

    @noteArea  = $('#balance-note')
    @sumButton = $('.js-bilances-sum')

    @sumButton.on('click', @_handleSumButtonClick)

  _handleSumButtonClick: (e) =>
    e.preventDefault()

    text  = @noteArea.val()
    parts = text.split(/\+/g)
    numbers = []
    sum   = 0

    for item in parts
      item = item.replace(/\s/, '')
      item = item.replace(',', '.')
      number = Number(item)
      numbers.push(number) if number

    return unless numbers.length

    sum = 0
    sum += number for number in numbers
    sum = Math.round(sum * 100) / 100

    @balanceAmountInput
      .val(sum)
      .focus()



$ ->
  new Confirm
  new HighchartsConfig
  new EntryForm
  new Tags
  new ExpenseChart
  new BalanceDiff
  new BalanceChart
  new TagEntriesChart
  new BalanceForm
