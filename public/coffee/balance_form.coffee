class @BalanceForm
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
