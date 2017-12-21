ruTranslation = require('./localizations/ru')
enTranslation = require('./localizations/en')
PopupRenderer = require('./PopupRenderer')
SwipeDetector = require('./modules/SwipeDetector')
positionManager = require('./modules/positionManager')
isTouchDevice = require('./modules/isTouchDevice')


class Datepicker
  prefix: ''
  roles: []
  role: null
  wrapper: false
  popupRenderer: false
  today: new Date()
  isCurrentMonth: false
  t: ruTranslation
  isTouchDevice: null
  settedRoles: false
  legend: false
  type: 'simple'
  onlyFuture: true
  offsets:
    top: 0
    left: 0
  theme: false

  onSelect: (date, role) -> console.log "#{role} selected date #{date}"

  constructor: (options = {}) ->
    @options = options
    @isTouchDevice = isTouchDevice()

    @nodes = []
    @datepickerWrapper = options.wrapper || document.body
    @roles = (options.role && [options.role]) || options.roles || ['tp-datepicker']
    @role = @roles[0]
    @onSelect = options.callback if options.callback
    @prefix = options.prefix if options.prefix
    @offsets = options.offsets if options.offsets
    @theme = options.theme if options.theme

    for role in @roles
      node = @nodes[role] = @datepickerWrapper.querySelector("[role=\"#{role}\"]")
      node.classList.add "#{@prefix}tp-datepicker-trigger"

      @[role] = @_parseDate(node.getAttribute('data-date'))
      node.setAttribute('readonly', true)
      node.addEventListener 'focus', @_listenerFor(role)
      node.addEventListener 'keydown', (event) => @_processKey(event.keyCode)

    @_initPopup()

  _initPopup: ->
    @currentMonth = @today.getMonth() + 1
    @currentYear = @today.getFullYear()
    @currentDay = @today.getDate()

    listener = (event_name, element) => @_callback_proxy(event_name, element)
    @popupRenderer = new PopupRenderer({
      listener
      datepicker: @
      prefix: @prefix
      theme: @theme
      visibleWeeksNum: @options.visibleWeeksNum
      clickableDaysInFuture: @options.clickableDaysInFuture
    })


    new SwipeDetector @popupRenderer.node,
      left: => @nextMonth()
      right: => @prevMonth()
      down: => @popupRenderer.node.classList.remove("#{@prefix}tp-datepicker--active")
      up: => @popupRenderer.node.classList.remove("#{@prefix}tp-datepicker--active")


    @popupRenderer.node.querySelector('[role="tp-datepicker-prev"]').addEventListener 'click', => @prevMonth()
    @popupRenderer.node.querySelector('[role="tp-datepicker-next"]').addEventListener 'click', => @nextMonth()


    document.addEventListener 'click', (event) =>
      return unless node = event.target

      if node.tagName != 'BODY' && node.tagName != 'HTML'
        return if @roles.indexOf(node.getAttribute('role')) >= 0
        while node = node.parentNode
          break if node.tagName == 'BODY'
          return if !node.parentNode || node.classList.contains("#{@prefix}tp-datepicker") ||
            @roles.indexOf(node.getAttribute('role')) >= 0

      @nodes[@role].classList.remove("#{@prefix}tp-datepicker-trigger--active")
      @popupRenderer.node.classList.remove("#{@prefix}tp-datepicker--active")

  _processKey: (code) ->
    switch code
      when 27, 9
        @popupRenderer.node.classList.remove("#{@prefix}tp-datepicker--active")
        @nodes[@role].classList.remove("#{@prefix}tp-datepicker-trigger--active")
      when 8
        @nodes[@role].setAttribute('value', '')

  prevMonth: ->
    return if @onlyFuture && @isCurrentMonth
    if @month == 1
      @year--
      @month = 12
    else
      @month--

    @_renderDatepicker()

  nextMonth: ->
    if @month == 12
      @year++
      @month = 1
    else
      @month++

    @_renderDatepicker()

  show: (@role, @callback) ->
    @date = @_parseDate(@[@role]) || @today
    @month = @date.getMonth() + 1
    @year = @date.getFullYear()
    @_renderDatepicker()
    for role, node of @nodes
      node.classList.toggle("#{@prefix}tp-datepicker-trigger--active", role == @role) if @roles.indexOf(role) > -1
    positionManager.positionAround @nodes[@role], @popupRenderer.node, false, @offsets


  _callback_proxy: (event_name, element) ->
    switch event_name
      when 'click'
        @callback(element.getAttribute('data-date'))
        return true
      else
        return false

  _listenerFor: (role) ->
    return (event) =>
      @show role, (date) => @_showCallback(date, role)
      if @isTouchDevice
        event.preventDefault()
        event.target.blur()

  _showCallback: (date, role) ->
    if date then @[role] = date
    @_setupDate(role, @[role])
    unless @settedRoles
      @nodes[@role].classList.remove("#{@prefix}tp-datepicker-trigger--active")
      @popupRenderer.node.classList.remove("#{@prefix}tp-datepicker--active")
      @onSelect(date, role)

  _setupDate: (role, date) ->
    @nodes[role].setAttribute('data-date', date)
    @nodes[role].setAttribute('value', @_formatDate(date))

  _renderDatepicker:  ->
    @isCurrentMonth = @currentYear == @year && @currentMonth == @month
    @isPrevMonth = @currentYear > @year || (@currentYear == @year && @currentMonth > @month)
    @popupRenderer.render @

    @popupRenderer.node.classList.add("#{@prefix}tp-datepicker--active")


  _parseDate: (string) ->
    unless string?
      return
    if Object.prototype.toString.call(string) is '[object Date]'
      return string

    array = string.split('-')
    return new Date(array[0], parseInt(array[1], 10) - 1, array[2])

  _stringifyDate: (date) ->
    "#{date.getFullYear()}-#{date.getMonth() + 1}-#{date.getDate()}"

  _formatDate: (string) ->
    return unless string
    dateArray = string.split('-')
    "#{dateArray[2]} #{@t.short_months[parseInt(dateArray[1], 10)].toLowerCase()} #{dateArray[0]}"

  _setScale: (value, element = @popupRenderer.node) ->
    element.style.webkitTransform = element.style.transform = "scale(#{value})"

module.exports = Datepicker
