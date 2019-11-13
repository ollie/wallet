class @TagsSort
  constructor: ->
    $tags = $('.js-tags-sort')

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
