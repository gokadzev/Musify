const checkApiUrl =
  'https://raw.githubusercontent.com/gokadzev/Musify/update/check.json'
const changelogApiUrl =
  'https://raw.githubusercontent.com/gokadzev/Musify/update/changelog.json'
let versionElement = document.getElementById('version')
let downloadElement = document.getElementById('download')
let changelogElement = document.getElementById('changelogContent')

function getUpdateInfo(callback) {
  var xmlHttp = new XMLHttpRequest()
  xmlHttp.onreadystatechange = function () {
    if (xmlHttp.readyState == 4 && xmlHttp.status == 200)
      callback(xmlHttp.responseText)
  }
  xmlHttp.open('GET', checkApiUrl, true)
  xmlHttp.send(null)
}

function getUpdateChangelog(callback) {
  var xmlHttp = new XMLHttpRequest()
  xmlHttp.onreadystatechange = function () {
    if (xmlHttp.readyState == 4 && xmlHttp.status == 200)
      callback(xmlHttp.responseText)
  }
  xmlHttp.open('GET', changelogApiUrl, true)
  xmlHttp.send(null)
}

document.addEventListener('DOMContentLoaded', () => {
  'use strict'

  const preloader = document.querySelector('#preloader')
  if (preloader) {
    window.addEventListener('load', () => {
      preloader.remove()
    })
  }

  const selectHeader = document.querySelector('#header')
  if (selectHeader) {
    let headerOffset = selectHeader.offsetTop
    let nextElement = selectHeader.nextElementSibling

    const headerFixed = () => {
      if (headerOffset - window.scrollY <= 0) {
        selectHeader.classList.add('sticked')
        if (nextElement) nextElement.classList.add('sticked-header-offset')
      } else {
        selectHeader.classList.remove('sticked')
        if (nextElement) nextElement.classList.remove('sticked-header-offset')
      }
    }
    window.addEventListener('load', headerFixed)
    document.addEventListener('scroll', headerFixed)
  }

  let navbarlinks = document.querySelectorAll('#navbar a')

  function navbarlinksActive() {
    navbarlinks.forEach((navbarlink) => {
      if (!navbarlink.hash) return

      let section = document.querySelector(navbarlink.hash)
      if (!section) return

      let position = window.scrollY + 200

      if (
        position >= section.offsetTop &&
        position <= section.offsetTop + section.offsetHeight
      ) {
        navbarlink.classList.add('active')
      } else {
        navbarlink.classList.remove('active')
      }
    })
  }
  window.addEventListener('load', navbarlinksActive)
  document.addEventListener('scroll', navbarlinksActive)

  const mobileNavShow = document.querySelector('.mobile-nav-show')
  const mobileNavHide = document.querySelector('.mobile-nav-hide')

  document.querySelectorAll('.mobile-nav-toggle').forEach((el) => {
    el.addEventListener('click', function (event) {
      event.preventDefault()
      mobileNavToogle()
    })
  })

  function mobileNavToogle() {
    document.querySelector('body').classList.toggle('mobile-nav-active')
    mobileNavShow.classList.toggle('d-none')
    mobileNavHide.classList.toggle('d-none')
  }

  document.querySelectorAll('#navbar a').forEach((navbarlink) => {
    if (!navbarlink.hash) return

    let section = document.querySelector(navbarlink.hash)
    if (!section) return

    navbarlink.addEventListener('click', () => {
      if (document.querySelector('.mobile-nav-active')) {
        mobileNavToogle()
      }
    })
  })

  const navDropdowns = document.querySelectorAll('.navbar .dropdown > a')

  navDropdowns.forEach((el) => {
    el.addEventListener('click', function (event) {
      if (document.querySelector('.mobile-nav-active')) {
        event.preventDefault()
        this.classList.toggle('active')
        this.nextElementSibling.classList.toggle('dropdown-active')

        let dropDownIndicator = this.querySelector('.dropdown-indicator')
        dropDownIndicator.classList.toggle('bi-chevron-up')
        dropDownIndicator.classList.toggle('bi-chevron-down')
      }
    })
  })

  const scrollTop = document.querySelector('.scroll-top')
  if (scrollTop) {
    const togglescrollTop = function () {
      window.scrollY > 100
        ? scrollTop.classList.add('active')
        : scrollTop.classList.remove('active')
    }
    window.addEventListener('load', togglescrollTop)
    document.addEventListener('scroll', togglescrollTop)
    scrollTop.addEventListener(
      'click',
      window.scrollTo({
        top: 0,
        behavior: 'smooth',
      })
    )
  }

  function aos_init() {
    AOS.init({
      duration: 1000,
      easing: 'ease-in-out',
      once: true,
      mirror: false,
    })
  }
  window.addEventListener('load', () => {
    aos_init()
  })
})

window.onload = function () {
  getUpdateInfo((res) => {
    const response = JSON.parse(res)
    versionElement.textContent += 'Current Version: ' + response['version']
    downloadElement.setAttribute('href', response['url'])
  })
  getUpdateChangelog((res) => {
    const response = JSON.parse(res)
    changelogElement.innerHTML = response['changelog']
  })
}
