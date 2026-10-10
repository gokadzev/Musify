const checkApiUrl =
  "https://api.github.com/repos/gokadzev/Musify/releases/latest";
const versionElement = document.getElementById("version");
const downloadElement = document.getElementById("download");
const changelogElement = document.getElementById("changelog_element");

function makeHttpRequest(url, callback) {
  const xmlHttp = new XMLHttpRequest();
  xmlHttp.onreadystatechange = function () {
    if (xmlHttp.readyState === 4 && xmlHttp.status === 200) {
      callback(xmlHttp.responseText);
    }
  };
  xmlHttp.open("GET", url, true);
  xmlHttp.send(null);
}
document.addEventListener("DOMContentLoaded", function () {
  const year = document.getElementById("year");
  if (year) year.textContent = new Date().getFullYear();

  initGallery();
  initReveal();
  initScrollSpy();
  if (versionElement) fetchAppMetadata(checkApiUrl);
});

function initGallery() {
  const gallery = document.getElementById("gallery");
  if (!gallery) return;
  const items = Array.from(gallery.children);
  const dots = document.getElementById("gallery-dots");
  const step = () => items[0].offsetWidth + 24;
  const center = (i) =>
    items[i].offsetLeft - (gallery.clientWidth - items[i].offsetWidth) / 2;

  items.forEach((_, i) => {
    const dot = document.createElement("span");
    dots.appendChild(dot);
  });

  const update = () => {
    const mid0 = gallery.scrollLeft + gallery.clientWidth / 2;
    let active = 0;
    let best = Infinity;
    items.forEach((item, i) => {
      const mid = item.offsetLeft + item.offsetWidth / 2;
      const dist = Math.abs(mid0 - mid);
      const t = Math.min(dist / (item.offsetWidth + 24), 1);
      item.style.setProperty("--t", t.toFixed(3));
      if (dist < best) {
        best = dist;
        active = i;
      }
    });
    items.forEach((item, i) => item.classList.toggle("is-active", i === active));
    Array.from(dots.children).forEach((d, i) =>
      d.classList.toggle("is-active", i === active),
    );
  };

  let ticking = false;
  gallery.addEventListener("scroll", () => {
    if (ticking) return;
    ticking = true;
    requestAnimationFrame(() => {
      update();
      ticking = false;
    });
  });
  window.addEventListener("resize", update);
  document
    .getElementById("gallery-prev")
    .addEventListener("click", () =>
      gallery.scrollBy({ left: -step(), behavior: "smooth" }),
    );
  document
    .getElementById("gallery-next")
    .addEventListener("click", () =>
      gallery.scrollBy({ left: step(), behavior: "smooth" }),
    );
  gallery.addEventListener("keydown", (e) => {
    if (e.key === "ArrowRight") gallery.scrollBy({ left: step(), behavior: "smooth" });
    if (e.key === "ArrowLeft") gallery.scrollBy({ left: -step(), behavior: "smooth" });
  });

  // Start centered on the second screenshot
  gallery.scrollLeft = center(1);
  update();
  window.addEventListener("load", () => {
    gallery.scrollLeft = center(1);
    update();
  });
}

function initReveal() {
  const els = document.querySelectorAll(".reveal");
  if (!("IntersectionObserver" in window)) {
    els.forEach((el) => el.classList.add("in"));
    return;
  }
  const io = new IntersectionObserver(
    (entries) =>
      entries.forEach((e) => {
        if (e.isIntersecting) {
          e.target.classList.add("in");
          io.unobserve(e.target);
        }
      }),
    { threshold: 0.12 },
  );
  els.forEach((el) => io.observe(el));
}

function initScrollSpy() {
  const links = document.querySelectorAll('#navigation-bar a[href^="#"]');
  if (!links.length || !("IntersectionObserver" in window)) return;
  const byId = new Map();
  links.forEach((link) => {
    const section = document.getElementById(link.getAttribute("href").slice(1));
    if (section) byId.set(section, link);
  });
  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;
        links.forEach((l) => l.removeAttribute("aria-current"));
        byId.get(entry.target).setAttribute("aria-current", "true");
      });
    },
    { rootMargin: "-40% 0px -55% 0px" },
  );
  byId.forEach((_, section) => observer.observe(section));
}

function fetchAppMetadata(apiUrl) {
  makeHttpRequest(apiUrl, (res) => {
    try {
      const response = JSON.parse(res);

      const appUrl = response.assets.find(
        (asset) => asset.name === "Musify.apk",
      )?.browser_download_url;
      const appVersion = response.tag_name;

      if (appUrl && appVersion) {
        versionElement.textContent += `V${appVersion}`;
        downloadElement.setAttribute("href", appUrl);
        parseChangelog(response.body);
      } else {
        console.error("App URL or version not found in the response.");
      }
    } catch (error) {
      console.error("Error parsing app metadata:", error);
    }
  });
}

function parseChangelog(text) {
  const lines = text.split(/\r?\n/).filter((line) => line.trim() !== "");

  lines.forEach((line) => {
    const itemMatch = line.match(/^\*\s+(.+)$/);
    if (itemMatch) {
      const processedText = itemMatch[1].replace(/\*\*(.+?)\*\*/g, "<b>$1</b>");

      const listItem = document.createElement("p");
      listItem.innerHTML = `• ${processedText}`;
      changelogElement.appendChild(listItem);
    }
  });
}
