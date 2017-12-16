isTouchDevice = require('./modules/isTouchDevice')


class MonthRenderer
  _activeDays: 45
  prefix: ''
  marks: ['prev', 'current-date', 'next']
  isTouchDevice: null
  theme: false
  visibleWeeksNum: 6

  constructor: (props) ->
    @callback = props.callback
    @daysNames = props.daysNames
    @sundayFirst = props.sundayFirst
    if props.visibleWeeksNum?
      @visibleWeeksNum = props.visibleWeeksNum

    if props.prefix?
      @prefix = props.prefix

    @onlyFuture = props.onlyFuture
    @theme = props.theme

    [@marksPrev, @marksCurrent, @marksNext] = @marks
    @isTouchDevice = isTouchDevice()

  render: (year, month, isCurrentMonth, isPrevMonth, currentDay) ->
    @_buildTable(@_monthDaysArray(year, month), isCurrentMonth, isPrevMonth, currentDay, month)

  _firstDay: (year, month) -> (new Date(year, month - 1, 1)).getDay()

  # Add ten hours to 32th day to avoid winter time adjustment
  _monthLength: (year, month) -> 32 - new Date(year, month - 1, 32, 10).getDate()

  _diffDate: (ds, de) ->
    timeDiff = Math.abs(de.getTime() - ds.getTime())
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
        for (var day = 1; day < 14; days.push([nextYear, nextMonth, day++, this.marksNext, true]));
    }
    else {

        //prew month
        for (var day = prevMonthStart; day < prevMonthEnd; day++)
        {
            var active = false;
            if( this._activeDays - this._diffDate(new Date(prevYear, prevMonth-1, day), rDate) > 0 ) active = true;
            days.push([prevYear, prevMonth, day, this.marksPrev, active]);
            //console.log(new Date(prevYear, prevMonth - 1, day) );
        }

        //cur month
        for (var day = 1; day < this._monthLength(year, month) + 1; day++)
        {
            var active = false;
            var dd = new Date(year, month - 1 , day);
            var d = this._diffDate(dd, rDate);
         //   console.log(new Date(year, month  , day) );

            if( this._activeDays - this._diffDate(new Date(year, month - 1 , day), rDate) > 0 ) {
                active = true;
            }

            days.push([year, month, day, this.marksCurrent, active]);
        }
        // console.log(43 - (prevMonthEnd - prevMonthStart + this._monthLength(year, month - 1)))
        //next month
        for (var day = 1; day <= 43 - this._monthLength(year, month - 1); day++)
        {
            var active = false;
            if( this._activeDays - this._diffDate(new Date(year, month, day), rDate) > 0 ) active = true;

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

  _buildTable: (days, isCurrentMonth, isPrevMonth, currentDay, currentMonth) ->
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
    for i in [0...42]
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
      if !active
        day.className += "#{@prefix}tp-datepicker-current-date #{@prefix}tp-datepicker-prev-date"
      else
        day.className = "#{@prefix}tp-datepicker-#{cd[3]}"
        if isPrevMonth || (isCurrentMonth && ((currentDay > cd[2] && currentMonth >= cd[1]) || cd[3] == @marksPrev))
            day.className += " #{@prefix}tp-datepicker-prev-date"
        else
             day.className += " #{@prefix}tp-datepicker-current
#            if @theme then day.className += " #{@prefix}tp-datepicker-current#{ '--' + @theme}"

    @days = daysHash

    table

module.exports = MonthRenderer
