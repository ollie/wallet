class @TagSelect
  constructor: ->
    @select = $('.js-tags-select')
    @searchInput = $('.js-tags-search-input')
    @datalist = $('.js-tags-datalist')
    @tagsList = $('.js-tags-list')
    @template = $('.js-tags-select-template')

    @searchInput.on('change', this._handleChange)
    @tagsList.on('click', '.js-tag-remove', this._handleTagRemove)

  _handleChange: (e) =>
    tagName = @searchInput.val()
    return unless tagName

    $option = @datalist.find("option[value=\"#{tagName}\"]")

    id = $option.data('id')
    return unless id

    $option = @select.find("option[value=\"#{id}\"]")
    return unless $option

    $option.attr('selected', true)

    html = @template.html()
    html = html.replace('#name#', tagName)
    html = html.replace('#id#', id)

    @tagsList.append(html)

    @searchInput.val('')

  _handleTagRemove: (e) =>
    $button = $(e.currentTarget)
    $listItem = $button.parents('.js-tag-list-item')
    id = $button.data('id')

    $option = @select.find("option[value=\"#{id}\"]")
    $option.attr('selected', false)

    $listItem.remove()
