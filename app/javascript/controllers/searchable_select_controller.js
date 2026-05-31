import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

export default class extends Controller {
  connect() {
    this.ts = new TomSelect(this.element, {
      create: false,
      maxOptions: null,
    })
  }

  disconnect() {
    this.ts.destroy()
  }
}
