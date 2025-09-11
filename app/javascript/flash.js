document.addEventListener("turbo:load", () => {
  const alerts = document.querySelectorAll(".alert");

  alerts.forEach((alert) => {
    if (alert.classList.contains("alert-success")) {
      setTimeout(() => {
        alert.classList.remove("show"); // triggers Bootstrap fade
        alert.classList.add("hide");

        setTimeout(() => alert.remove(), 500);
      }, 5000);
    }
  });
});