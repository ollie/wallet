class @EntryForm
  constructor: ->
    @expenseButton = $('.js-expense')

    return unless @expenseButton.length

    @incomeButton     = $('.js-income')
    @amount           = $('.js-amount')
    @todayDate        = $('.js-today-date')
    @tagCombinations  = $('.js-tag-combination')
    @tagsSearchInput  = $('.js-tags-search-input')

    @expenseButton.on('click', @_handleExpenseButtonClick)
    @incomeButton.on('click', @_handleIncomeButtonClick)
    @amount.on('input', @_handleAmountInput)
    @todayDate.on('click', @_handleTodayDateClick)
    @tagCombinations.on('click', @_handleTagCombinationClick)

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

  _handleTodayDateClick: (e) =>
    today = new Date
    today = today.toISOString().substr(0, 10)

    $button = $(e.currentTarget)
    $input = $button.parents('.row:first').find('input')
    $input.val(today)

  _handleTagCombinationClick: (e) =>
    e.preventDefault()

    $link  = $(e.currentTarget)

    $link.find('[data-tag-name]').each (_, tag) =>
      tagName = $(tag).data('tag-name')
      @tagsSearchInput.val(tagName).trigger('change')
