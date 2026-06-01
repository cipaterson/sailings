import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this._dirty = false
    this._onBeforeUnload = this._beforeUnload.bind(this)
    this._onBeforeVisit = this._beforeVisit.bind(this)

    this.element.addEventListener("change", () => { this._dirty = true })
    this.element.addEventListener("submit", () => { this._dirty = false })
    window.addEventListener("beforeunload", this._onBeforeUnload)
    document.addEventListener("turbo:before-visit", this._onBeforeVisit)
  }

  disconnect() {
    window.removeEventListener("beforeunload", this._onBeforeUnload)
    document.removeEventListener("turbo:before-visit", this._onBeforeVisit)
  }

  _beforeUnload(event) {
    if (!this._dirty) return
    event.preventDefault()
    event.returnValue = ""
  }

  _beforeVisit(event) {
    if (this._dirty && !confirm("You have unsaved changes. Leave anyway?")) {
      event.preventDefault()
    }
  }
}
