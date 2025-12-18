class TagsSort {
  constructor() {
    const $tags = $(".js-tags-sort")

    if (!$tags.length) {
      return
    }

    let tagsHtml = $tags.html()

    $tags.sortable({
      axis: "y",
      containment: "parent",
      handle: ".js-sortable-handle",
      tolerance: "pointer",
      update: () => {
        const changes = {}

        $tags.find("li").each((i, item) => {
          const newPosition = i + 1
          const $tag = $(item)
          const oldPosition = $tag.data("position")

          if (newPosition === oldPosition) {
            return
          }

          $tag.attr("data-position", newPosition)
          changes[$tag.data("id")] = newPosition
        })

        if ($.isEmptyObject(changes)) {
          return
        }

        $.ajax(
          $tags.data("path"),
          {
            method: "POST",
            data: {
              positions: changes
            },
            error: () => {
              $tags.html(tagsHtml)
            },
            success: () => {
              tagsHtml = $tags.html()
            }
          }
        )
      }
    })
  }
}

window.TagsSort = TagsSort
