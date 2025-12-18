class TagSelect {
  #select
  #searchInput
  #datalist
  #tagsList
  #template

  constructor() {
    this.#select = $(".js-tags-select")
    this.#searchInput = $(".js-tags-search-input")
    this.#datalist = $(".js-tags-datalist")
    this.#tagsList = $(".js-tags-list")
    this.#template = $(".js-tags-select-template")

    this.#searchInput.on("change", this.#handleChange.bind(this))
    this.#tagsList.on("click", ".js-tag-remove", this.#handleTagRemove.bind(this))
  }

  #handleChange(e) {
    const tagName = this.#searchInput.val()
    if (!tagName) {
      return
    }

    const $option = this.#datalist.find(`option[value="${tagName}"]`)
    const id = $option.data("id")

    if (!id) {
      return
    }

    const $option2 = this.#select.find(`option[value="${id}"]`)

    if (!$option2) {
      return
    }

    $option2.attr("selected", true)

    let html = this.#template.html()
    html = html.replace("#name#", tagName)
    html = html.replace("#id#", id)

    this.#tagsList.append(html)

    this.#searchInput.val("")
  }

  #handleTagRemove(e){
    const $button = $(e.currentTarget)
    const $listItem = $button.parents(".js-tag-list-item")
    const id = $button.data("id")

    const $option = this.#select.find(`option[value="${id}"]`)
    $option.attr("selected", false)

    $listItem.remove()
  }
}

window.TagSelect = TagSelect
