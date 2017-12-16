class DatepickerRange extends Datepicker
  isEndDate: false
  settedRoles: {}
  prevRole: false
  readyToDraw: true
  legend: false
  type: 'range'

  onSelect: (startDate, endDate, role) -> console.log "#{role} selected range from #{startDate} to #{endDate}"

  constructor: (options = {}) ->
    options.role = null
    options.roles ||= ['startDate', 'endDate']
    @legend = options.legend if options.legend

    super options

    [@startDateRole, @endDateRole] = @roles
    @settedRoles[@startDateRole] = @settedRoles[@endDateRole] = false

  show: (@role, @callback) ->
    @isEndDate = (@role == @endDateRole)
    super(@role, @callback)
    @prevRole = @role

  _callback_proxy: (event_name, element) ->
    return true if super(event_name, element)
    switch event_name
      when 'mouseout'
        @readyToDraw = true
        return true
      when 'mouseover'
        return unless @readyToDraw
        if @isEndDate
          @_drawSausage @startDate, element.getAttribute('data-date')
        else
          @_drawSausage element.getAttribute('data-date'), @endDate
        @readyToDraw = false
        return true
      else
        return false

  _currentDateType: -> if @isEndDate then 'endDate' else 'startDate'

  _showCallback: (date, role) ->
    super(date, role)
    @[@_currentDateType()] = date if date
    @settedRoles[role] = true
    @_checkDates(role)

    oppositeRole = @_oppositeRole(role)
    if @settedRoles[oppositeRole]
      @nodes[@role].classList.remove("#{@prefix}tp-datepicker-trigger--active")
      @popupRenderer.node.classList.remove("#{@prefix}tp-datepicker--active")
    else
      @_setupDate(oppositeRole, @[oppositeRole])
      @_listenerFor(oppositeRole)()

    @onSelect(@startDateObj, @endDateObj, role)

  _oppositeRole: -> if @isEndDate then @startDateRole else @endDateRole

  _checkDates: (role) ->
    @startDateObj = @_parseDate(@startDate) || (@endDateObj && @_changeDate(@endDateObj, - 1)) || @today
    @endDateObj = @_parseDate(@endDate) || (@startDateObj && @_changeDate(@startDateObj, 1))
    oppositeRole = @_oppositeRole(role)
    if @startDateObj >= @endDateObj || !@settedRoles[oppositeRole] || @endDateObj == @today
      @settedRoles[oppositeRole] = false
      if @isEndDate
        @endDateObj = @_changeDate(@today, 1) if @endDateObj == @today
        @startDateObj = @_changeDate(@endDateObj, - 1)
      else
        @endDateObj = @_changeDate(@startDateObj, 1)

    @startDate = @[@startDateRole] = @_stringifyDate(@startDateObj)
    @endDate = @[@endDateRole] = @_stringifyDate(@endDateObj)

  _renderDatepicker: ->
    super()
    @_drawSausage(@startDate, @endDate)
    @_updateLegend(@t.legend[@_currentDateType()]) if @legend && @prevRole != @role

  _updateLegend: (text) ->
    node = @popupRenderer.legendNode
    node.textContent = text
    node.classList.toggle "#{@prefix}tp-datepicker-legend--start-date", !@isEndDate
    node.classList.toggle "#{@prefix}tp-datepicker-legend--end-date", @isEndDate

    @_setScale(1.1, node)
    setTimeout (=> @_setScale(1, node)), 200

  _drawSausage: (sausageStart, sausageEnd) ->
    return unless sausageStart || sausageEnd
    sausageStart ||= sausageEnd
    sausageEnd ||= sausageStart
    arrayStart = sausageStart.split('-')
    arrayEnd = sausageEnd.split('-')

    started = parseInt(arrayStart[1], 10) < @month && parseInt(arrayEnd[1], 10) >= @month
    ended = parseInt(arrayEnd[1], 10) < @month && parseInt(arrayStart[1], 10) >= @month
    sausageStart = "#{@prefix}tp-datepicker-#{sausageStart}"
    sausageEnd = "#{@prefix}tp-datepicker-#{sausageEnd}"
    samePoints = sausageStart == sausageEnd
    for date, node of @popupRenderer.monthRenderer.days
      classList = node.classList
      unless @onlyFuture && classList.contains("#{@prefix}tp-datepicker-prev-date")
        isStarting = sausageStart == date
        isEnding = sausageEnd == date
        if isStarting && !((samePoints || ended) && @isEndDate)
          classList.add "#{@prefix}tp-datepicker-start-sausage"
          classList.remove "#{@prefix}tp-datepicker-range"
          classList.remove "#{@prefix}tp-datepicker-end-sausage"
          classList.remove "#{@prefix}tp-datepicker-end-sausage--invisible"
          classList.remove "#{@prefix}tp-datepicker-start-sausage--invisible"
          started = !samePoints
          classList.add "#{@prefix}tp-datepicker-range" if started && !ended
        else if isEnding && (started || @isEndDate)
          classList.add "#{@prefix}tp-datepicker-end-sausage"
          classList.remove "#{@prefix}tp-datepicker-range"
          classList.remove "#{@prefix}tp-datepicker-start-sausage"
          classList.remove "#{@prefix}tp-datepicker-end-sausage--invisible"
          classList.remove "#{@prefix}tp-datepicker-start-sausage--invisible"
          classList.add "#{@prefix}tp-datepicker-range" if started
          started = samePoints
          ended = true
        else if started && !ended
          classList.add "#{@prefix}tp-datepicker-range"
          classList.remove "#{@prefix}tp-datepicker-start-sausage"
          classList.remove "#{@prefix}tp-datepicker-end-sausage"
        else
          if isEnding
            ended = true
            classList.add "#{@prefix}tp-datepicker-end-sausage--invisible"
            classList.remove "#{@prefix}tp-datepicker-start-sausage--invisible"
          else if isStarting
            classList.add "#{@prefix}tp-datepicker-start-sausage--invisible"
            classList.remove "#{@prefix}tp-datepicker-end-sausage--invisible"
          else
            classList.remove "#{@prefix}tp-datepicker-start-sausage--invisible"
            classList.remove "#{@prefix}tp-datepicker-end-sausage--invisible"
          classList.remove "#{@prefix}tp-datepicker-range"
          classList.remove "#{@prefix}tp-datepicker-start-sausage"
          classList.remove "#{@prefix}tp-datepicker-end-sausage"

  _changeDate: (date, step = 1) ->
    new Date((new Date(date)).setDate(date.getDate() + step))

module.exports = DatepickerRange
