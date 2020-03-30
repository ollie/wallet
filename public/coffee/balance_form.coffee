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
    lines = text.split(/\s*\n\s*/)
    numbers = []

    lines.forEach (line) ->
      line  = line.replace(/\s/g, '')
      match = line.match(/\b\d+([,\.]\d+)?\b/)

      unless match
        console.warn("Cannot find number in line: #{line}")
        return

      numberAsString = match[0]
      numberAsString = numberAsString.replace(',', '.')
      number = Number(numberAsString)

      if isNaN(number)
        console.warn("Could not convert to number: #{numberAsString} (line: #{line})")
        return

      numbers.push(number)

    sum = 0
    sum += number for number in numbers
    sum = Math.round(sum * 100) / 100

    @balanceAmountInput
      .val(sum)
      .focus()
