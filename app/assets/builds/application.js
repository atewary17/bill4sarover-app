// app/javascript/controllers/booking_form.js
document.addEventListener("DOMContentLoaded", () => {
  const checkIn = document.getElementById("booking_check_in");
  const checkOut = document.getElementById("booking_check_out");
  const roomSelect = document.getElementById("booking_room_id");
  const customerSelect = document.getElementById("booking_customer_id");
  const customerPreview = document.getElementById("customer-preview");
  const roomStatus = document.getElementById("room-status");
  const customerSearch = document.getElementById("customer_search");
  const resultsBox = document.getElementById("customer-results");
  const hiddenCustomerId = document.getElementById("booking_customer_id");
  const historyBox = document.getElementById("customer-history");
  const roomNameLabel = document.getElementById("selected-room-name");
  if (!customerSearch || !roomSelect) return;
  function loadRooms() {
    if (!checkIn.value || !checkOut.value) return;
    roomSelect.disabled = true;
    roomSelect.innerHTML = "<option>Loading...</option>";
    fetch(`/bookings/available_rooms?check_in=${checkIn.value}&check_out=${checkOut.value}`).then((res) => res.json()).then((data) => {
      roomSelect.disabled = false;
      roomSelect.innerHTML = '<option value="">Select room</option>';
      data.forEach((room) => {
        const opt = document.createElement("option");
        opt.value = room.id;
        opt.text = `${room.room_number} - ${room.room_type}`;
        roomSelect.appendChild(opt);
      });
    });
  }
  function loadCustomerPreview(id) {
    fetch(`/customers/${id}.json`).then((res) => res.json()).then((c) => {
      customerPreview.innerHTML = `
          <p><strong>Name:</strong> ${c.name}</p>
          <p><strong>Phone:</strong> ${c.phone || "-"}</p>
          <p><strong>Email:</strong> ${c.email || "-"}</p>
        `;
    });
  }
  customerSearch.addEventListener("input", function() {
    const q = this.value.trim();
    if (q.length < 2) {
      resultsBox.innerHTML = "";
      return;
    }
    fetch(`/customers/search?q=${q}`).then((res) => res.json()).then((data) => {
      resultsBox.innerHTML = "";
      data.forEach((c) => {
        const div = document.createElement("div");
        div.className = "autocomplete-item";
        div.innerHTML = `<strong>${c.name}</strong> (${c.phone})`;
        div.onclick = () => {
          customerSearch.value = `${c.name} (${c.phone})`;
          hiddenCustomerId.value = c.id;
          resultsBox.innerHTML = "";
          loadCustomerPreview(c.id);
        };
        resultsBox.appendChild(div);
      });
    });
  });
  function handleRoomChange() {
    if (!roomSelect.value || !checkIn.value || !checkOut.value) return;
    const selectedText = roomSelect.options[roomSelect.selectedIndex].text;
    roomNameLabel.innerText = selectedText;
    fetch(`/bookings/check_room_status?room_id=${roomSelect.value}&check_in=${checkIn.value}&check_out=${checkOut.value}`).then((res) => res.json()).then((data) => {
      if (data.booked) {
        roomStatus.innerHTML = "\u{1F534}";
        roomStatus.style.color = "red";
      } else {
        roomStatus.innerHTML = "\u{1F7E2} ";
        roomStatus.style.color = "green";
      }
    });
    fetch(`/bookings/room_history?room_id=${roomSelect.value}&check_in=${checkIn.value}&check_out=${checkOut.value}`).then((res) => res.json()).then((data) => {
      if (data.length === 0) {
        historyBox.innerHTML = "<p>No previous bookings</p>";
        return;
      }
      historyBox.innerHTML = data.map((b) => `
          <div class="history-item">
            <strong>${b.customer}</strong><br>
            ${b.check_in} \u2192 ${b.check_out}<br>
            Status: <span class="status ${b.status}">${b.status}</span>
          </div>
        `).join("");
    });
  }
  checkIn.addEventListener("change", loadRooms);
  checkOut.addEventListener("change", loadRooms);
  checkIn.addEventListener("change", handleRoomChange);
  checkOut.addEventListener("change", handleRoomChange);
  roomSelect.addEventListener("change", handleRoomChange);
  customerSelect.addEventListener(
    "change",
    () => loadCustomerPreview(customerSelect.value)
  );
});
//# sourceMappingURL=/assets/application.js.map
