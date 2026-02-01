import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["search", "tab", "card", "input", "selectedDisplay"]
  static values = { field: { type: String, default: "all" } }

  connect() {
    this.filter()
  }

  search() {
    this.filter()
  }

  selectField(event) {
    event.preventDefault()
    this.fieldValue = event.currentTarget.dataset.field
    this.updateTabs()
    this.filter()
  }

  selectCourse(event) {
    const card = event.currentTarget
    const courseKey = card.dataset.courseKey
    const courseName = card.dataset.courseName

    // Update hidden input
    this.inputTarget.value = courseKey

    // Update visual selection
    this.cardTargets.forEach(c => {
      c.classList.remove("ring-2", "ring-indigo-500", "bg-indigo-50")
      c.classList.add("bg-white")
    })
    card.classList.remove("bg-white")
    card.classList.add("ring-2", "ring-indigo-500", "bg-indigo-50")

    // Update selected display
    if (this.hasSelectedDisplayTarget) {
      this.selectedDisplayTarget.textContent = courseName
      this.selectedDisplayTarget.classList.remove("hidden")
    }
  }

  filter() {
    const query = this.hasSearchTarget ? this.searchTarget.value.toLowerCase() : ""
    const field = this.fieldValue

    this.cardTargets.forEach(card => {
      const name = card.dataset.name.toLowerCase()
      const nameJa = card.dataset.nameJa.toLowerCase()
      const cardField = card.dataset.field

      const matchesSearch = query === "" || name.includes(query) || nameJa.includes(query)
      const matchesField = field === "all" || cardField === field

      if (matchesSearch && matchesField) {
        card.classList.remove("hidden")
      } else {
        card.classList.add("hidden")
      }
    })
  }

  updateTabs() {
    this.tabTargets.forEach(tab => {
      if (tab.dataset.field === this.fieldValue) {
        tab.classList.remove("bg-white", "text-gray-600")
        tab.classList.add("bg-indigo-600", "text-white")
      } else {
        tab.classList.remove("bg-indigo-600", "text-white")
        tab.classList.add("bg-white", "text-gray-600")
      }
    })
  }
}
