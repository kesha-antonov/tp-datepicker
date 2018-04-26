isTouchDevice = require('./modules/isTouchDevice')


class MonthRenderer
  _activeDays: 60
  prefix: ''
  marks: ['prev', 'current-date', 'next']
  isTouchDevice: null
  theme: false
  visibleWeeksNum: 6
  clickableDaysInFuture: 45

  constructor: (props) ->
    @callback = props.callback
    @daysNames = props.daysNames
    @sundayFirst = props.sundayFirst

    if props.max? and not props.clickableDaysInFuture?
      props.clickableDaysInFuture = @_getDiffDays(props.max)

    for x in ['visibleWeeksNum', 'prefix', 'clickableDaysInFuture']
      @[x] = props[x] if props[x]?

    @onlyFuture = props.onlyFuture
    @theme = props.theme

    [@marksPrev, @marksCurrent, @marksNext] = @marks
    @isTouchDevice = isTouchDevice()

  render: (year, month, isCurrentMonth, isPrevMonth, currentDay, currentYear) ->
    @_buildTable(@_monthDaysArray(year, month), isCurrentMonth, isPrevMonth, currentDay, month, currentYear)

  _getDiffDays: (max) ->
    now = new Date()
    timeDiff = Math.abs(max.getTime() - now.getTime())
    return Math.ceil(timeDiff / (1000 * 3600 * 24))

  _firstDay: (year, month) -> (new Date(year, month - 1, 1)).getDay()

  # Add ten hours to 32th day to avoid winter time adjustment
  _monthLength: (year, month) -> 32 - new Date(year, month - 1, 32, 10).getDate()

  _diffDate: (ds, de, abs) ->
    # NOTE: IOS 8 SAFARI COMPATIBILIYY
    unless abs?
      abs = true

    timeDiff = de.getTime() - ds.getTime()
    if abs
      timeDiff = Math.abs(timeDiff)
    Math.ceil (timeDiff / (1000 * 3600 * 24))


  _monthDaysArray: (year, month) ->
    nextYear = prevYear = year
    days = []
    needShift = true

    if month == 1
      prevYear--
      prevMonth = 12
      nextMonth = month + 1
    else if month == 12
      nextYear++
      nextMonth = 1
      prevMonth = month - 1
    else
      nextMonth = month + 1
      prevMonth = month - 1

    prevMonthLength = @_monthLength(prevYear, prevMonth)
    prevMonthStart = prevMonthLength - @_firstDay(year, month) + 1 - @sundayFirst
    prevMonthEnd = prevMonthLength + 1

    if prevMonthStart == prevMonthEnd
      prevMonthStart = prevMonthStart - 6
      needShift = false

    `

    var rDate = new Date();
    var realMonth = rDate.getMonth() + 1;
    var realDay = rDate.getDate() + 1;
    var realYear = rDate.getFullYear() + 1;

    if (month === realMonth && realYear){
        for (var day = prevMonthStart, fin = prevMonthEnd; day < fin; days.push([prevYear, prevMonth, day++, this.marksPrev, true]));

        for (var day = 1, fin = this._monthLength(year, month) + 1; day < fin; days.push([year, month, day++, this.marksCurrent, true]));
        for (var day = 1; day < (this.visibleWeeksNum - 4) * 7; days.push([nextYear, nextMonth, day++, this.marksNext, true]));
    }
    else {
        var currentDay;
        var futureEndDate = new Date()
        futureEndDate.setDate(futureEndDate.getDate() + this.clickableDaysInFuture)

        // NOTE: PREV MONTH
        for (var day = prevMonthStart; day < prevMonthEnd; day++)
        {
          if ( month >= 2 )
            currentDay = new Date(year, (month - 2), day);
          else
            currentDay = new Date(year-1, (month - 2 + 12), day);

          var active = ( this._diffDate(currentDay, rDate) > 0 && this._diffDate(currentDay, futureEndDate, false) > 0 );
          days.push([prevYear, prevMonth, day, this.marksPrev, active]);
        }

        // NOTE: CUR MONTH
        for (var day = 1; day < this._monthLength(year, month) + 1; day++)
        {
            var active = false;
            var dd = new Date(year, month - 1 , day);
            var d = this._diffDate(dd, rDate);

            currentDay = new Date(year, month - 1 , day)
            if( this._diffDate(currentDay, rDate) > 0 && this._diffDate(currentDay, futureEndDate, false) > 0 ) {
                active = true;
            }

            days.push([year, month, day, this.marksCurrent, active]);
        }
        // NOTE: NEXT MONTH
        for (var day = 1; day <= (this.visibleWeeksNum * 7 + 1) - this._monthLength(year, month - 1); day++)
        {
            currentDay = new Date(year, month, day)
            var active = this._diffDate(currentDay, futureEndDate, false) > 0;
            days.push([nextYear, nextMonth, day, this.marksNext, active]);
        }
    }

    `
    days.shift() if needShift
    days

  _callbackProxy: (event) ->
    target = event.target
    target = target.parentNode if target.tagName == 'DIV'
    unless target.classList.contains("#{@prefix}tp-datepicker-prev-date") && @onlyFuture
      target.hasAttribute('id') && @callback(event.type, target)

  _buildTable: (days, isCurrentMonth, isPrevMonth, currentDay, currentMonth, currentYear) ->
    table = document.createElement 'table'
    table.classList.add "#{@prefix}tp-datepicker-table"

    table.classList.add "#{@prefix}tp-datepicker-table--#{if @sundayFirst then 'sunday-first' else 'normal-weekdays'}"

    callbackProxy = (event) => @_callbackProxy(event)

    table.addEventListener 'click', callbackProxy
    table.addEventListener 'mouseout', callbackProxy
    table.addEventListener 'mouseover', callbackProxy
    if isTouchDevice
      table.addEventListener 'touchstart', callbackProxy
      table.addEventListener 'touchend', callbackProxy
      table.addEventListener 'touchmove', callbackProxy

    th = table.appendChild(document.createElement('tr'))
    for i in [0..@visibleWeeksNum]
      el = th.appendChild(document.createElement('td'))
      el.classList.add("#{@prefix}tp-datepicker-day_name")
      el.textContent = @daysNames[i]

    daysHash = {}
    for i in [0...@visibleWeeksNum * 7]
      cd = days[i]
      el = table.appendChild(document.createElement('tr')) if i % 7 == 0
      date = "#{cd[0]}-#{cd[1]}-#{cd[2]}"
      id = "#{@prefix}tp-datepicker-#{date}"
      day = daysHash[id] = el.appendChild(document.createElement('td'))
      innerEl = day.appendChild(document.createElement('div'))
      day.setAttribute('id', id)
      day.setAttribute('data-date', date)
      innerEl.textContent = cd[2]
      active = cd[4]
      if not active
        day.className += "#{@prefix}tp-datepicker-current-date #{@prefix}tp-datepicker-prev-date"
      else
        day.className = "#{@prefix}tp-datepicker-#{cd[3]}"
        if isPrevMonth or (
          isCurrentMonth and (
            ( currentDay > cd[2] and currentMonth >= cd[1] and currentYear >= cd[0] ) or
            cd[3] is @marksPrev
          )
        )
            day.className += " #{@prefix}tp-datepicker-prev-date"
        else
          day.className += " #{@prefix}tp-datepicker-current"
        # if @theme then day.className += " #{@prefix}tp-datepicker-current#{ '--' + @theme}"

    @days = daysHash

    table

module.exports = MonthRenderer
