class EntryForm
  constructor: ->
    @expenseButton    = $('.js-expense')
    @incomeButton     = $('.js-income')
    @amount           = $('.js-amount')
    @accountedOnInput = $('#entry-accounted_on')
    @dateInput        = $('#entry-date')
    @copyAccountedOn  = $('.js-copy-accounted-on')
    @tagCombinations  = $('.js-tag-combination')

    @expenseButton.on('click', @_handleExpenseButtonClick)
    @incomeButton.on('click', @_handleIncomeButtonClick)
    @amount.on('input', @_handleAmountInput)
    @copyAccountedOn.on('click', @_handleCopyAccountedOn)
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

  _handleCopyAccountedOn: (e) =>
    e.preventDefault()

    @dateInput
      .val(@accountedOnInput.val())
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
    $tags    = $('.js-tags')
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
    chart = c3.generate(
      bindto: @element[0]
      data:
        type: 'bar'
        url: @element.data('url')
        mimeType: 'json'
    )



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



$ ->
  new EntryForm
  new Tags
  new ExpenseChart
  new BalanceDiff
