class EntryForm {
  #expenseButton
  #incomeButton
  #amount
  #tagsSearchInput

  constructor() {
    this.#expenseButton = $(".js-expense")

    if (!this.#expenseButton.length) {
      return
    }

    this.#incomeButton = $(".js-income")
    this.#amount = $(".js-amount")
    const $todayDate = $(".js-today-date")
    const $tagCombinations = $(".js-tag-combination")
    this.#tagsSearchInput = $(".js-tags-search-input")

    this.#expenseButton.on("click", this.#handleExpenseButtonClick.bind(this))
    this.#incomeButton.on("click", this.#handleIncomeButtonClick.bind(this))
    this.#amount.on("input", this.#handleAmountInput.bind(this))
    $todayDate.on("click", this.#handleTodayDateClick.bind(this))
    $tagCombinations.on("click", this.#handleTagCombinationClick.bind(this))
  }

  #handleExpenseButtonClick() {
    const value = Number(this.#amount.val())

    if (value > 0) {
      this.#amount.val(-value)
    }

    this.#amount
      .data("type", "expense")
      .focus()

    this.#expenseButton
      .addClass("btn-danger active")
      .removeClass("btn-default")

    this.#incomeButton
      .removeClass("btn-success active")
      .addClass("btn-default")
  }

  #handleIncomeButtonClick() {
    const value = Number(this.#amount.val())

    if (value < 0) {
      this.#amount.val(-value)
    }

    this.#amount
      .data("type", "income")
      .focus()

    this.#incomeButton
      .addClass("btn-success active")
      .removeClass("btn-default")

    this.#expenseButton
      .removeClass("btn-danger active")
      .addClass("btn-default")
  }

  #handleAmountInput() {
    const value = this.#amount.val()

    if (value === "") {
      return
    }

    const number = Number(value)

    if ((this.#amount.data("type") === "expense" && number > 0) ||
        (this.#amount.data("type") === "income" && number < 0)) {
      this.#amount.val(-value)
    }
  }

  #handleTodayDateClick(e) {
    let today = new Date()
    today = today.toISOString().substr(0, 10)

    const $button = $(e.currentTarget)
    const $input = $button.parents(".row:first").find("input")
    $input.val(today)
  }

  #handleTagCombinationClick(e) {
    e.preventDefault()

    const $link = $(e.currentTarget)

    $link.find("[data-tag-name]").each((_, tag) => {
      const tagName = $(tag).data("tag-name")
      this.#tagsSearchInput.val(tagName).trigger("change")
    })
  }
}

window.EntryForm = EntryForm
