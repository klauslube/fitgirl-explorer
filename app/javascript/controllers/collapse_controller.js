import { Controller } from "@hotwired/stimulus"

// Mobile: the filter sidebar collapses behind a button.
export default class extends Controller {
  static targets = ["panel"]

  toggle() { this.panelTarget.classList.toggle("hidden") }
}
