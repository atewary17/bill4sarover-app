// import { Controller } from "@hotwired/stimulus"

// export default class extends Controller {
//   static targets = ["input", "hidden", "results"]

//   connect() {
//     console.log("Payer autocomplete controller connected!")
//   }

//   search() {
//     const query = this.inputTarget.value
//     console.log("Searching for:", query)
    
//     if (query.length < 2) {
//       this.resultsTarget.innerHTML = ""
//       return
//     }

//     fetch(`/customers/search?q=${encodeURIComponent(query)}`)
//       .then(response => response.json())
//       .then(data => {
//         console.log("Search results:", data)
//         this.displayResults(data)
//       })
//       .catch(error => {
//         console.error("Search error:", error)
//       })
//   }

//   displayResults(customers) {
//     if (customers.length === 0) {
//       this.resultsTarget.innerHTML = '<li style="list-style: none; padding: 8px; border: 1px solid #ddd;">No customers found</li>'
//       return
//     }

//     this.resultsTarget.innerHTML = customers.map(customer => `
//       <li style="list-style: none; padding: 8px; border: 1px solid #ddd; cursor: pointer; background: white;"
//           onmouseover="this.style.background='#f0f0f0'"
//           onmouseout="this.style.background='white'"
//           data-action="click->payer-autocomplete#select"
//           data-id="${customer.id}"
//           data-name="${customer.name}"
//           data-phone="${customer.phone}">
//         <strong>${customer.name}</strong><br>
//         <small>${customer.phone}</small>
//       </li>
//     `).join('')
//   }

//   select(event) {
//     const id = event.currentTarget.dataset.id
//     const name = event.currentTarget.dataset.name
//     const phone = event.currentTarget.dataset.phone
    
//     console.log("Selected customer:", { id, name, phone })
    
//     this.hiddenTarget.value = id
//     this.inputTarget.value = `${name} (${phone})`
//     this.resultsTarget.innerHTML = ""
//   }
// }