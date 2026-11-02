import { Controller } from "@hotwired/stimulus"

// Submits the filter form shortly after the user stops changing it. Filtering itself runs server-side.
export default class extends Controller {
  static values = { delay: { type: Number, default: 400 } }

  connect() {
    // Keep shared URLs short: drop empty fields from the query string.
    this.dropBlanks = (event) => {
      for (const [key, value] of [...event.formData]) if (value === "") event.formData.delete(key)
    }
    this.element.addEventListener("formdata", this.dropBlanks)
  }

  disconnect() {
    clearTimeout(this.timer)
    this.element.removeEventListener("formdata", this.dropBlanks)
  }

  queue() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.element.requestSubmit(), this.delayValue)
  }

  now() {
    clearTimeout(this.timer)
    this.element.requestSubmit()
  }
}
