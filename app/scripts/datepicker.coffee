class @TpDatepicker
  roles: []
  role: null
  wrapper: false
  popupRenderer: false
  today: new Date()
  isCirrentMonth: false
  t: window.translations.datepicker
  isTouchDevice: window.isTouchDevice
  nodes: []
  settedRoles: false
  legend: false
  type: 'simple'

  onDateSelect: (date, role) -> console.log "#{role} selected date #{date}"

  constructor: (options = {}) ->
    @datepickerWrapper = options.wrapper || document.body
    @roles = (options.role && [options.role]) || options.roles || ['tp-datepicker']
    @role = @roles[0]

    for role in @roles
      node = @nodes[role] = @datepickerWrapper.querySelector("[role=\"#{role}\"]")
      node.classList.add 'tp-datepicker-trigger'
      @[role] = @_parseDate(node.getAttribute('data-date'))
      if @isTouchDevice
        node.addEventListener 'touchstart', @_listenerFor(role)
      else
        node.addEventListener 'click', @_listenerFor(role)

      node.addEventListener 'focus', (event) -> event.preventDefault(); event.target.blur()

    @_initPopup()


  _initPopup: ->
    @currentMonth = @today.getMonth() + 1
    @currentYear = @today.getFullYear()
    @currentDay = @today.getDate()


    listener = (event_name, element) => @_callback_proxy(event_name, element)
    @popupRenderer = new TpDatepickerPopupRenderer(this, listener)


    if window.SwipeDetector
      new SwipeDetector @popupRenderer.node,
        left: => @nextMonth()
        right: => @prevMonth()
        down: => @_setScale(0)
        up: => @_setScale(0)


    @popupRenderer.node.querySelector('[role="tp-datepicker-prev"]').addEventListener 'click', => @prevMonth()
    @popupRenderer.node.querySelector('[role="tp-datepicker-next"]').addEventListener 'click', => @nextMonth()


    document.addEventListener 'click', (event) =>
      return unless node = event.target

      if node.tagName != 'BODY' && node.tagName != 'HTML'
        if @roles.indexOf(node.getAttribute('role')) > -1
          window.sendMetric("datepickerinputs_touch") if window.sendMetric
          return
        while node = node.parentNode
          break if node.tagName == 'BODY'
          return if !node.parentNode || node.classList.contains('tp-datepicker') ||
            @roles.indexOf(node.getAttribute('role')) >= 0

      @nodes[@role].classList.remove('tp-datepicker-trigger--active')
      @_setScale(0)

  prevMonth: ->
    return if @isCirrentMonth
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
    node.classList.toggle('tp-datepicker-trigger--active', role == @role) for role, node of @nodes
    window.positionManager.positionAround @nodes[@role], @popupRenderer.node if window.positionManager


  _callback_proxy: (event_name, element) ->
    switch event_name
      when 'click'
        @callback(element.getAttribute('data-date'))
        return true
      else
        return false

  _listenerFor: (role) ->
    return =>
      @show role, (date) => @_showCallback(date, role)

  _showCallback: (date, role) ->
    if date then @[role] = date
    @_setupDate(role, @[role])
    unless @settedRoles
      @_setScale(0)
      @onDateSelect(date, role)

  _setupDate: (role, date) ->
    @nodes[role].setAttribute('data-date', date)
    @nodes[role].setAttribute('value', @_formatDate(date))

  _renderDatepicker:  ->
    @isCirrentMonth = @currentYear == @year && @currentMonth == @month
    @popupRenderer.render this

    @_setScale(1)


  _parseDate: (string) ->
    return unless string
    array = string.split('-')
    new Date(array[0], parseInt(array[1], 10) - 1, array[2])

  _stringifyDate: (date) ->
    "#{date.getFullYear()}-#{date.getMonth() + 1}-#{date.getDate()}"

  _formatDate: (string) ->
    return unless string
    dateArray = string.split('-')
    "#{dateArray[2]} #{@t.short_months[parseInt(dateArray[1], 10)]} #{dateArray[0]}"

  _setScale: (value, element = @popupRenderer.node) ->
    element.style.webkitTransform = element.style.transform = "scale(#{value})"