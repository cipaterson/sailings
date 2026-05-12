import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const firstBlock = this.element.querySelector(".cal-sailing-block")
    if (firstBlock) {
      const top = parseInt(firstBlock.style.top) || 0
      this.element.scrollTop = Math.max(0, top - 30)
    }
  }
}
