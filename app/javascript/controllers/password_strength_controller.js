import { Controller } from "@hotwired/stimulus"

const RULES = {
  length:    { test: v => v.length >= 8,           label: "At least 8 characters" },
  uppercase: { test: v => /[A-Z]/.test(v),         label: "At least one uppercase letter" },
  lowercase: { test: v => /[a-z]/.test(v),         label: "At least one lowercase letter" },
  digit:     { test: v => /\d/.test(v),            label: "At least one number" },
  special:   { test: v => /[^A-Za-z0-9]/.test(v), label: "At least one special character" }
}

export default class extends Controller {
  static targets = ["password", "confirmation", "rule", "matchMessage", "submit"]
  static values  = { optional: { type: Boolean, default: false } }

  check() {
    const password = this.passwordTarget.value
    const confirmation = this.confirmationTarget.value

    // Optional mode (user edit): if password is blank, rules don't apply
    if (this.optionalValue && password.length === 0) {
      this.ruleTargets.forEach(rule => rule.classList.remove("passing", "failing"))
      this.matchMessageTarget.textContent = ""
      this.matchMessageTarget.classList.remove("passing", "failing")
      this.submitTarget.disabled = false
      return
    }

    let allPassing = true

    this.ruleTargets.forEach(rule => {
      const key = rule.dataset.rule
      const passes = RULES[key]?.test(password)
      rule.textContent = `${passes ? "✓" : "✗"} ${RULES[key]?.label}`
      rule.classList.toggle("passing", !!passes)
      rule.classList.toggle("failing", !passes)
      if (!passes) allPassing = false
    })

    const matches = password.length > 0 && password === confirmation
    const matchMsg = this.matchMessageTarget

    if (confirmation.length > 0) {
      matchMsg.textContent = matches ? "✓ Passwords match" : "✗ Passwords do not match"
      matchMsg.classList.toggle("passing", matches)
      matchMsg.classList.toggle("failing", !matches)
    } else {
      matchMsg.textContent = ""
      matchMsg.classList.remove("passing", "failing")
    }

    this.submitTarget.disabled = !(allPassing && matches)
  }
}
