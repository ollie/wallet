class BalanceForm {
  #balanceAmountInput
  #noteArea
  #sumButton

  constructor() {
    this.#balanceAmountInput = $("#balance-amount")

    if (!this.#balanceAmountInput.length) {
      return
    }

    this.#noteArea  = $("#balance-note")
    this.#sumButton = $(".js-bilances-sum")

    this.#sumButton.on("click", this.#handleSumButtonClick.bind(this))
  }

  #handleSumButtonClick(e) {
    e.preventDefault()

    const text  = this.#noteArea.val()
    const lines = text.split(/\s*\n\s*/)
    let numbers = []

    lines.forEach(line => {
      line  = line.replace(/\s/g, "")
      const match = line.match(/\b\d+([,\.]\d+)?\b/)

      if (!match) {
        console.warn(`Cannot find number in line: ${line}`)
        return
      }

      let numberAsString = match[0]
      numberAsString = numberAsString.replace(",", ".")
      const number = Number(numberAsString)

      if (isNaN(number)) {
        console.warn(`Could not convert to number: ${numberAsString} (line: ${line})`)
        return
      }

      numbers.push(number)
    })

    let sum = 0
    numbers.forEach(number => sum += number)
    sum = Math.round(sum * 100) / 100

    this.#balanceAmountInput
      .val(sum)
      .focus()
  }
}

window.BalanceForm = BalanceForm
