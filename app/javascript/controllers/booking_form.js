// app/javascript/controllers/booking_form.js
document.addEventListener("DOMContentLoaded", () => {

  // ===== ELEMENTS =====
  const checkIn          = document.getElementById("booking_check_in");
  const checkOut         = document.getElementById("booking_check_out");
  const roomSelect       = document.getElementById("booking_room_id");
  const roomStatus       = document.getElementById("room-status");
  const customerSearch   = document.getElementById("customer_search");
  const resultsBox       = document.getElementById("customer-results");
  const hiddenCustomerId = document.getElementById("booking_customer_id");
  const historyBox       = document.getElementById("customer-history");
  const roomNameLabel    = document.getElementById("selected-room-name");

  // Page guard — only run on booking new/edit pages
  if (!customerSearch || !roomSelect) return;

  const pageController = document.body.dataset.controller;
  const pageAction     = document.body.dataset.action;
  const isNewBooking   = pageController === "bookings" && pageAction === "new";

  // The submit button is rendered by Rails form helper — grab it by type, not a missing id
  const saveBtn = document.querySelector('input[type="submit"], button[type="submit"]');

  // ===== ROOMS =====
  function loadRooms() {
    if (!checkIn.value || !checkOut.value) return;

    roomSelect.disabled = true;
    roomSelect.innerHTML = '<option>Loading...</option>';

    fetch(`/bookings/available_rooms?check_in=${checkIn.value}&check_out=${checkOut.value}`)
      .then(res => res.json())
      .then(data => {
        roomSelect.disabled = false;
        roomSelect.innerHTML = '<option value="">Select room</option>';

        data.forEach(room => {
          const opt = document.createElement("option");
          opt.value = room.id;
          opt.text  = `${room.room_number} - ${room.room_type}`;
          roomSelect.appendChild(opt);
        });
      })
      .catch(err => console.error("Failed to load rooms:", err));
  }

  // ===== CUSTOMER PREVIEW =====
  // Renders into the "Customer Preview" card on the right panel
  function loadCustomerPreview(id) {
    if (!id) return;

    fetch(`/customers/${id}.json`)
      .then(res => res.json())
      .then(c => {
        if (!historyBox) return;
        // Prepend a small customer card above any room history already shown
        const existing = document.getElementById("customer-preview-card");
        const card = existing || document.createElement("div");
        card.id = "customer-preview-card";
        card.innerHTML = `
          <div class="card border-0 bg-light mb-3">
            <div class="card-body py-2 px-3">
              <p class="mb-1"><strong>Name:</strong> ${c.name}</p>
              <p class="mb-1"><strong>Phone:</strong> <span class="text-muted">${c.phone || "—"}</span></p>
              <p class="mb-0"><strong>Email:</strong> <span class="text-muted">${c.email || "—"}</span></p>
            </div>
          </div>
        `;
        if (!existing) {
          // Insert the preview card into the Customer Preview card body
          const previewCardBody = document.querySelector('.card:has(#customer-history) .card-body') ||
                                  historyBox.closest('.card-body');
          if (previewCardBody) {
            previewCardBody.insertBefore(card, previewCardBody.firstChild);
          }
        }
      })
      .catch(err => console.error("Failed to load customer preview:", err));
  }

  // ===== CUSTOMER AUTOCOMPLETE =====
  customerSearch.addEventListener("input", function () {
    const q = this.value.trim();

    if (q.length < 2) {
      resultsBox.innerHTML = "";
      return;
    }

    fetch(`/customers/search?q=${encodeURIComponent(q)}`)
      .then(res => res.json())
      .then(data => {
        resultsBox.innerHTML = "";

        if (data.length === 0) {
          resultsBox.innerHTML = '<div class="list-group-item text-muted">No customers found</div>';
          return;
        }

        data.forEach(c => {
          const div = document.createElement("div");
          div.className = "list-group-item list-group-item-action";
          div.style.cursor = "pointer";
          div.innerHTML = `
            <strong>${c.name}</strong>
            <br>
            <small class="text-muted">${c.phone || ""}</small>
          `;

          div.onclick = () => {
            customerSearch.value = `${c.name} (${c.phone || ""})`;
            hiddenCustomerId.value = c.id;
            resultsBox.innerHTML = "";
            loadCustomerPreview(c.id);
          };

          resultsBox.appendChild(div);
        });
      })
      .catch(err => console.error("Customer search failed:", err));
  });

  // Close autocomplete dropdown when clicking outside
  document.addEventListener("click", (e) => {
    if (!customerSearch.contains(e.target) && !resultsBox.contains(e.target)) {
      resultsBox.innerHTML = "";
    }
  });

  // ===== ROOM STATUS + NAME + HISTORY =====
  function handleRoomChange() {
    if (!roomSelect.value || !checkIn.value || !checkOut.value) return;

    const selectedText = roomSelect.options[roomSelect.selectedIndex].text;
    if (roomNameLabel) {
      roomNameLabel.innerText = selectedText;
    }

    // Room availability status badge
    fetch(`/bookings/check_room_status?room_id=${roomSelect.value}&check_in=${checkIn.value}&check_out=${checkOut.value}`)
      .then(res => res.json())
      .then(data => {
        if (!roomStatus) return;
        if (data.booked) {
          roomStatus.innerHTML = '<span class="badge bg-danger">🔴 Not Available</span>';
          if (isNewBooking && saveBtn) {
            saveBtn.disabled = true;
            saveBtn.classList.add("disabled");
            saveBtn.title = "Room is not available for selected dates";
          }
        } else {
          roomStatus.innerHTML = '<span class="badge bg-success">🟢 Available</span>';
          if (isNewBooking && saveBtn) {
            saveBtn.disabled = false;
            saveBtn.classList.remove("disabled");
            saveBtn.title = "";
          }
        }
      })
      .catch(err => console.error("Room status check failed:", err));

    // Room booking history
    fetch(`/bookings/room_history?room_id=${roomSelect.value}&check_in=${checkIn.value}&check_out=${checkOut.value}`)
      .then(res => res.json())
      .then(data => {
        if (!historyBox) return;

        if (data.length === 0) {
          historyBox.innerHTML = '<div class="alert alert-light small mb-0">No previous bookings for this room</div>';
          return;
        }

        historyBox.innerHTML = data.map(b => `
          <div class="card mb-2 border-0" style="background-color: #f8f9fa;">
            <div class="card-body py-2 px-3">
              <div class="d-flex justify-content-between align-items-start">
                <div>
                  <strong class="text-dark">${b.customer}</strong>
                  <br>
                  <small class="text-muted">
                    ${b.check_in} → ${b.check_out}
                  </small>
                </div>
                <span class="badge ${
                  b.status === "booked"      ? "bg-primary"   :
                  b.status === "checked_in"  ? "bg-success"   :
                  b.status === "checked_out" ? "bg-secondary" :
                  b.status === "cancelled"   ? "bg-danger"    :
                  b.status === "invoiced"    ? "bg-info"      : "bg-secondary"
                }">
                  ${b.status}
                </span>
              </div>
            </div>
          </div>
        `).join("");
      })
      .catch(err => console.error("Room history fetch failed:", err));
  }

  // ===== EVENT LISTENERS =====
  checkIn.addEventListener("change",  loadRooms);
  checkOut.addEventListener("change", loadRooms);

  checkIn.addEventListener("change",       handleRoomChange);
  checkOut.addEventListener("change",      handleRoomChange);
  roomSelect.addEventListener("change",    handleRoomChange);

});