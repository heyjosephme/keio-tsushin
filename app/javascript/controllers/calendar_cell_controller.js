import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["details"]

  toggle() {
    this.detailsTarget.classList.toggle("hidden")
  }

  // Close when clicking outside
  close(event) {
    if (!this.element.contains(event.target)) {
      this.detailsTarget.classList.add("hidden")
    }
  }
}
