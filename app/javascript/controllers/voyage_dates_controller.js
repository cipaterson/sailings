import { Controller } from "@hotwired/stimulus"

// Fills the return date with the departure date when the user picks a departure
// date and the return date is still empty — a convenience for same-day voyages.
export default class extends Controller {
  static targets = ["departsDate", "returnsDate"]

  fillReturn() {
    if (this.returnsDateTarget.value === "") {
      this.returnsDateTarget.value = this.departsDateTarget.value
    }
  }
}
