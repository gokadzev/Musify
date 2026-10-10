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
  if (!document.getElementById("screenshot-carousel") || !window.Splide) return;
  new Splide("#screenshot-carousel", {
    type: "loop",
    perPage: 3,
    gap: "2rem",
    pagination: true,
    arrows: false,
    breakpoints: {
      1200: { perPage: 3, gap: "2rem" },
      699: { perPage: 2, gap: "1.5rem" },
      560: { perPage: 1, gap: "1rem" },
    },
  }).mount();
});

window.onload = function () {
  assignNavClass();
  window.addEventListener("resize", assignNavClass);

  if (versionElement) fetchAppMetadata(checkApiUrl);
};

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

function assignNavClass() {
  const nav = document.getElementById("navigation-bar");
  if (!nav) return;
  if (window.innerWidth > 760) {
    nav.classList.remove("bottom");
    nav.classList.add("left");
  } else {
    nav.classList.remove("left");
    nav.classList.add("bottom");
  }
}
