function removeSplashFromWeb() {
  const elem = document.getElementById("splash");
  if (elem) {
    elem.remove();
  }
  const elem2 = document.getElementById("splash-branding");
  if (elem2) {
    elem2.remove();
  }
  document.body.style.background = "transparent";
}
