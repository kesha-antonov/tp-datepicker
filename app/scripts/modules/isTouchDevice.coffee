isTouchDevice = ->
  return window.ontouchstart or navigator.MaxTouchPoints > 0 or navigator.msMaxTouchPoints > 0

module.exports = isTouchDevice
