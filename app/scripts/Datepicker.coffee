ruTranslation = require('./localizations/ru')
enTranslation = require('./localizations/en')
PopupRenderer = require('./PopupRenderer')
SwipeDetector = require('./modules/SwipeDetector')
positionManager = require('./modules/positionManager')
isTouchDevice = require('./modules/isTouchDevice')


TRANSLATIONS =
  ru: ruTranslation
  en: enTranslation

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
  lang: 'ru'
  max: null
  maxYear: null
  maxMonth: null

  onSelect: (date, role) -> console.log "#{role} selected date #{date}"

  constructor: (options) ->
    @options = options or {}
    @isTouchDevice = isTouchDevice()

    @nodes = []
    @datepickerWrapper = @options.wrapper or document.body
    @roles = (options.role and [options.role]) or @options.roles or ['tp-datepicker']
    @role = @roles[0]
    @onSelect = @options.callback if @options.callback
    @prefix = @options.prefix if @options.prefix
    @offsets = @options.offsets if @options.offsets
    @theme = @options.theme if @options.theme

    if @options.max?
      @max = @_getDateFromString(@options.max)
      @maxYear = @max.getFullYear()
      @maxMonth = @max.getMonth() + 1

    if ['en', 'ru'].indexOf( @options.lang ) > -1
      @lang = @options.lang
    @t = @options.locale or TRANSLATIONS[@lang]

    for role in @roles
      node = @nodes[role] = @datepickerWrapper.querySelector("[role=\"#{role}\"]")
      node.classList.add "#{@prefix}tp-datepicker-trigger"

      @[role] = @_parseDate(node.getAttribute('data-date'))
      node.setAttribute('readonly', true)
      node.addEventListener 'focus', @_listenerFor(role)
      node.addEventListener 'keydown', (event) => @_processKey(event.keyCode)

    @_initPopup()
    if @options.id?
      @popupRenderer.node.id = @options.id

  _forceTwoDigits: (n) ->
    return n if n > 9
    return "0#{n}"

  _getDateFromString: (strDate) ->
    return strDate if typeof strDate isnt 'string'
    regex=/(\d{4})\-(\d{1,2})\-(\d{1,2})/
    match = regex.exec(strDate)
    return new Date("#{match[1]}-#{@_forceTwoDigits(+match[2])}-#{@_forceTwoDigits(+match[3])}")

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
      min: @options.min
      max: @max
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

      if node.tagName != 'BODY' and node.tagName != 'HTML'
        return if @roles.indexOf(node.getAttribute('role')) >= 0
        while node = node.parentNode
          break if node.tagName == 'BODY'
          return if !node.parentNode or node.classList.contains("#{@prefix}tp-datepicker") ||
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
    @popupRenderer.node.querySelector(".#{@prefix}tp-datepicker-next-month-control").style.opacity = 1

    if @onlyFuture and @isCurrentMonth
      return

    if @month == 1
      @year--
      @month = 12
    else
      @month--

    @_renderDatepicker()

  nextMonth: ->
    if @maxYear and @maxMonth
      isNextMonth = false
      if @year == @maxYear and @month == @maxMonth - 1
        @popupRenderer.node.querySelector(".#{@prefix}tp-datepicker-next-month-control").style.opacity = 0.3
      else
        @popupRenderer.node.querySelector(".#{@prefix}tp-datepicker-next-month-control").style.opacity = 1
      if @year > @maxYear
        isNextMonth = false
      else if @year < @maxYear
        isNextMonth = true
      else if @month < @maxMonth
        isNextMonth = true
      else
        isNextMonth = false
      if isNextMonth
        if @month == 12
          @year++
          @month = 1
        else
          @month++
      else
        @popupRenderer.node.querySelector(".#{@prefix}tp-datepicker-next-month-control").style.opacity = 0.3
    else
      if @month == 12
        @year++
        @month = 1
      else
        @month++

    @_renderDatepicker()

  show: (@role, @callback) ->
    @date = @_parseDate(@[@role]) or @today
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
    if typeof date is 'object'
      date = @_stringifyDate(date)

    @nodes[role].setAttribute('data-date', date)
    @nodes[role].setAttribute('value', @_formatDate(date))

  _renderDatepicker: ->
    @isCurrentMonth = @currentYear == @year and @currentMonth == @month
    @isPrevMonth = @currentYear > @year or (@currentYear == @year and @currentMonth > @month)
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
    "#{dateArray[2]} #{@t.short_months[parseInt(dateArray[1], 10)]} #{dateArray[0]}"

  _setScale: (value, element) ->
    # NOTE: IOS 8 SAFARI COMPATIBILIYY
    unless element?
      element = @popupRenderer.node

    element.style.webkitTransform = element.style.transform = "scale(#{value})"

module.exports = Datepicker
