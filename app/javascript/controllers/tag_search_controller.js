import { Controller } from "@hotwired/stimulus"

// Searches the tag list through the tags#index Turbo Frame, keeping the already ticked tags.
export default class extends Controller {
  static targets = ["input", "frame"]
  static values = { url: String }

  disconnect() { clearTimeout(this.timer) }

  search() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => {
      const url = new URL(this.urlValue, window.location.origin)
      url.searchParams.set("tag_q", this.inputTarget.value)
      this.element.querySelectorAll("input[name='tag_ids[]']:checked").forEach(i => url.searchParams.append("tag_ids[]", i.value))
      this.frameTarget.src = url.toString()
    }, 250)
  }
}
