class RecurringEntryForm {
  #nameInput
  #noteArea

  constructor() {
    this.#nameInput = $("#recurring-entry-name")
    this.#noteArea = $("#recurring-entry-note")

    if (!this.#nameInput.length) {
      return
    }

    this.#nameInput.on("input", this.#handleInput.bind(this))
  }

  #handleInput(e) {
    this.#noteArea.text(this.#nameInput.val())
  }
}

window.RecurringEntryForm = RecurringEntryForm
