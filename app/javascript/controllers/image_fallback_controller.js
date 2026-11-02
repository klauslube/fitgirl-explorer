import { Controller } from "@hotwired/stimulus"

// External cover hosts go down or block hotlinking; show the title placeholder instead of a broken image.
export default class extends Controller {
  static targets = ["img", "placeholder"]

  show() {
    this.imgTarget.classList.add("hidden")
    this.placeholderTarget.classList.remove("hidden")
  }

  connect() {
    if (this.hasImgTarget && this.imgTarget.complete && this.imgTarget.naturalWidth === 0) this.show()
  }
}
