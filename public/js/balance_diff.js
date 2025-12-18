class BalanceDiff {
  #elements
  #diff
  #items = []

  constructor() {
    this.#elements = $(".js-balance-diff")

    if (!this.#elements.length) {
      return
    }

    this.#diff = $("#balance-diff")

    this.#elements.on("click", this.#handleClick.bind(this))
  }

  #handleClick(e) {
    const $input = $(e.currentTarget)

    if (!$input.is(":checked")) {
      this.#removeItem($input)
      return
    }

    const date = Date.parse($input.data("date"))
    const amount = Number($input.val())

    const item = {
      input: $input,
      amount: amount,
      date: date
    }

    this.#addItem(item)
    this.#calculate()
  }

  #addItem(item) {
    switch (this.#items.length) {
      case 0:
        this.#items.push(item)
        break
      case 1:
        if (item.date > this.#items[0].date) {
          this.#items.unshift(item)
        } else {
          this.#items.push(item)
        }
        break
      default:
        this.#items.forEach(item => item.input.prop("checked", false))
        this.#items = []
        this.#items.push(item)
    }
  }

  #removeItem($input) {
    this.#items.forEach(item => item.input.prop("checked", false))
    this.#items = []
    $input.trigger("click")
  }

  #calculate() {
    if (this.#items.length < 2) {
      this.#diff.text("")
      return
    }

    const diff = this.#items[0].amount - this.#items[1].amount
    let parts = parseFloat(diff).toFixed(2).split(".")

    parts[0] = parts[0].replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1 ")
    let textDiff = `${parts.join(",")} Kč`

    if (diff >= 0) {
      textDiff = `+${textDiff}`
    }

    this.#diff.text(textDiff)
  }
}

window.BalanceDiff = BalanceDiff
