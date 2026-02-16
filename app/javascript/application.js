// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "./controllers/booking_form"

import { Application } from "@hotwired/stimulus"

const application = Application.start()
export { application }
