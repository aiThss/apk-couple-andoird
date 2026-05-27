const state = {
  token: localStorage.getItem("cs_admin_token") || "",
  tab: "overview",
};

const apiBaseInput = document.querySelector("#apiBase");
const loginPanel = document.querySelector("#loginPanel");
const appPanel = document.querySelector("#appPanel");
const logoutButton = document.querySelector("#logoutButton");
const statusText = document.querySelector("#statusText");
const pageTitle = document.querySelector("#pageTitle");

apiBaseInput.value =
  localStorage.getItem("cs_api_base") ||
  new URLSearchParams(window.location.search).get("api") ||
  (window.location.hostname === "couple.babyress.games"
    ? "https://api.couple.babyress.games/api"
    : null) ||
  `${window.location.origin}/api`;

function apiBase() {
  return apiBaseInput.value.replace(/\/$/, "");
}

function saveApiBase() {
  localStorage.setItem("cs_api_base", apiBase());
}

async function request(path, options = {}) {
  saveApiBase();
  const response = await fetch(`${apiBase()}${path}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...(state.token ? { Authorization: `Bearer ${state.token}` } : {}),
      ...(options.headers || {}),
    },
  });

  const payload = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new Error(payload.error || `Request failed: ${response.status}`);
  }
  return payload;
}

function setLoggedIn(loggedIn) {
  loginPanel.classList.toggle("hidden", loggedIn);
  appPanel.classList.toggle("hidden", !loggedIn);
  logoutButton.classList.toggle("hidden", !loggedIn);
}

function formatDate(value) {
  if (!value) return "-";
  return new Date(value).toLocaleDateString("vi-VN");
}

function isoDateInput(value) {
  return new Date(value).toISOString().slice(0, 10);
}

function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

async function login() {
  const email = document.querySelector("#email").value;
  const password = document.querySelector("#password").value;
  const payload = await request("/admin/login", {
    method: "POST",
    body: JSON.stringify({ email, password }),
  });
  state.token = payload.token;
  localStorage.setItem("cs_admin_token", state.token);
  setLoggedIn(true);
  await refresh();
}

function logout() {
  state.token = "";
  localStorage.removeItem("cs_admin_token");
  setLoggedIn(false);
}

function showTab(tab) {
  state.tab = tab;
  document.querySelectorAll(".tab").forEach((button) => {
    button.classList.toggle("active", button.dataset.tab === tab);
  });
  document.querySelectorAll(".tab-page").forEach((page) => {
    page.classList.toggle("hidden", page.id !== tab);
  });
  pageTitle.textContent = tab[0].toUpperCase() + tab.slice(1);
}

async function refresh() {
  try {
    statusText.textContent = "Loading...";
    await Promise.all([
      loadSummary(),
      loadUsers(),
      loadCouples(),
      loadPhotos(),
      loadRandomEvents(),
    ]);
    statusText.textContent = `Connected to ${apiBase()}`;
  } catch (error) {
    statusText.textContent = error.message;
    if (/token|credentials|access/i.test(error.message)) {
      logout();
    }
  }
}

async function loadSummary() {
  const summary = await request("/admin/summary");
  document.querySelector("#metricUsers").textContent = summary.users;
  document.querySelector("#metricCouples").textContent = summary.couples;
  document.querySelector("#metricPhotos").textContent = summary.photos;
  document.querySelector("#metricBlocked").textContent = summary.blockedUsers;
  document.querySelector("#metricRandom").textContent = summary.randomEvents || 0;
}

async function loadUsers() {
  const { users } = await request("/admin/users");
  document.querySelector("#usersTable").innerHTML = users
    .map(
      (user) => `
        <tr>
          <td>
            <strong>${escapeHtml(user.displayName)}</strong>
            <div class="muted">${escapeHtml(user.partnerName)}</div>
          </td>
          <td>${escapeHtml(user.email || "anonymous")}</td>
          <td>${escapeHtml(user.couple?.code || "-")}</td>
          <td><span class="badge ${user.status === "blocked" ? "blocked" : ""}">${escapeHtml(user.status)}</span></td>
          <td>
            <button class="secondary" data-user-status="${user.status === "blocked" ? "active" : "blocked"}" data-user-id="${user.id}">
              ${user.status === "blocked" ? "Unblock" : "Block"}
            </button>
          </td>
        </tr>
      `,
    )
    .join("");
}

async function loadCouples() {
  const { couples } = await request("/admin/couples");
  document.querySelector("#couplesTable").innerHTML = couples
    .map(
      (couple) => `
        <tr>
          <td><strong>${escapeHtml(couple.code)}</strong></td>
          <td><input type="date" value="${isoDateInput(couple.loveStartDate)}" data-couple-date="${couple.id}" /></td>
          <td>${couple.memberIds.length}</td>
          <td><button class="secondary" data-save-couple="${couple.id}">Save</button></td>
        </tr>
      `,
    )
    .join("");
}

async function loadPhotos() {
  const { photos } = await request("/admin/photos");
  document.querySelector("#photosGrid").innerHTML = photos
    .map(
      (photo) => `
        <article class="photo-card">
          <img src="${escapeHtml(photo.imageUrl)}" alt="" loading="lazy" />
          <div class="body">
            <strong>${escapeHtml(photo.caption)}</strong>
            <span class="muted">${escapeHtml(photo.ownerName)} · ${formatDate(photo.createdAt)}</span>
            <button class="danger" data-delete-photo="${photo.id}">Delete</button>
          </div>
        </article>
      `,
    )
    .join("");
}

async function loadRandomEvents() {
  const { events } = await request("/admin/random-events");
  document.querySelector("#randomTable").innerHTML = events
    .map(
      (event) => `
        <tr>
          <td>${escapeHtml(event.category)}</td>
          <td>
            <strong>${escapeHtml(event.prompt)}</strong>
            <div class="muted">${escapeHtml(event.detail || "")}</div>
          </td>
          <td>${formatDate(event.createdAt)}</td>
        </tr>
      `,
    )
    .join("");
}

document.querySelector("#loginButton").addEventListener("click", () => {
  login().catch((error) => {
    statusText.textContent = error.message;
    alert(error.message);
  });
});

document.querySelector("#refreshButton").addEventListener("click", refresh);
logoutButton.addEventListener("click", logout);
apiBaseInput.addEventListener("change", saveApiBase);

document.querySelectorAll(".tab").forEach((button) => {
  button.addEventListener("click", () => showTab(button.dataset.tab));
});

document.body.addEventListener("click", async (event) => {
  const target = event.target;
  if (!(target instanceof HTMLElement)) return;

  const userId = target.dataset.userId;
  const userStatus = target.dataset.userStatus;
  if (userId && userStatus) {
    await request(`/admin/users/${userId}`, {
      method: "PATCH",
      body: JSON.stringify({ status: userStatus }),
    });
    await refresh();
  }

  const coupleId = target.dataset.saveCouple;
  if (coupleId) {
    const input = document.querySelector(`[data-couple-date="${coupleId}"]`);
    await request(`/admin/couples/${coupleId}`, {
      method: "PATCH",
      body: JSON.stringify({ loveStartDate: input.value }),
    });
    await refresh();
  }

  const photoId = target.dataset.deletePhoto;
  if (photoId && confirm("Delete this photo?")) {
    await request(`/admin/photos/${photoId}`, { method: "DELETE" });
    await refresh();
  }
});

setLoggedIn(Boolean(state.token));
showTab("overview");
if (state.token) refresh();
