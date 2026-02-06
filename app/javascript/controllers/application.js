import { Application } from "@hotwired/stimulus"
import "./booking/form"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

export { application }
