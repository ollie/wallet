class @BalanceDiff
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
