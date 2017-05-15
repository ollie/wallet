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

$ ->
  new EntryForm
  new Tags
  new ExpenseChart
