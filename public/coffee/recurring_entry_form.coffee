class @RecurringEntryForm
  constructor: ->
    @nameInput = $('#recurring-entry-name')
    @noteArea  = $('#recurring-entry-note')

    return unless @nameInput.length

    @nameInput.on('input', @_handleInput)

  _handleInput: =>
    @noteArea.text(@nameInput.val())
