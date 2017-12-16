MonthRenderer = require('./MonthRenderer')

class PopupRenderer
  prefix: ''
  node: false
  monthRenderer: null
  theme: false

  render: ->
    year = @datepicker.year
    month = @datepicker.month
    node = @monthRenderer.render(
      year,
      month,
      @datepicker.isCurrentMonth,
      @datepicker.isPrevMonth,
      @datepicker.currentDay,
      @datepicker.currentYear
    )
    @nodeClassList.toggle "#{@prefix}tp-datepicker--current_month", @onlyFuture && @datepicker.isCurrentMonth

    @updateMonth "#{@datepicker.t.months[month]} #{year}"
    @datepickerContainerNode.replaceChild(node, @datepickerContainerNode.childNodes[0])


  constructor: (@datepicker, listener, prefix, @theme, visibleWeeksNum) ->
    @prefix = prefix if prefix
    @onlyFuture = @datepicker.onlyFuture
    daysNames = @datepicker.t.days
    sundayFirst = @datepicker.t.start_from_sunday
    daysNames.unshift(daysNames.pop()) if sundayFirst
    @monthRenderer = new MonthRenderer({
      daysNames
      sundayFirst
      visibleWeeksNum
      callback: listener
      @prefix
      @onlyFuture
      @theme
    })

    @node = document.createElement('div')
    @nodeClassList = @node.classList
    @nodeClassList.add "#{@prefix}tp-datepicker"
    @nodeClassList.add "#{@prefix}tp-datepicker-#{@datepicker.type}"
    if @theme then @nodeClassList.add "#{@prefix}tp-datepicker-theme--#{@theme}"


    headerNode = document.createElement('div')
    headerNode.className = "#{@prefix}tp-datepicker-header"

    prevMonthNode = document.createElement('span')
    prevMonthNode.className = "#{@prefix}tp-datepicker-prev-month-control"
    prevMonthNode.setAttribute('role', 'tp-datepicker-prev')
    headerNode.appendChild prevMonthNode

    @MonthNode = document.createElement('span')
    @MonthNode.setAttribute('role', 'tp-datepicker-month')
    headerNode.appendChild @MonthNode

    nextMonthNode = document.createElement('span')
    nextMonthNode.className = "#{@prefix}tp-datepicker-next-month-control"
    nextMonthNode.setAttribute('role', 'tp-datepicker-next')
    headerNode.appendChild nextMonthNode

    @node.appendChild headerNode
    @datepickerContainerNode = document.createElement('div')
    @datepickerContainerNode.className = "#{@prefix}tp-datepicker-container"
    @datepickerContainerNode.setAttribute('role', 'tp-datepicker-table-wrapper')

    @datepickerContainerNode.appendChild document.createElement('span')
    @node.appendChild @datepickerContainerNode

    if @datepicker.legend
      @legendNode = document.createElement('span')
      @legendNode.className = "#{@prefix}tp-datepicker-legend"
      @legendNode.setAttribute('role', 'tp-datepicker-legend')
      @node.appendChild @legendNode

    document.body.appendChild @node
    @node


  updateMonth: (text) -> @MonthNode.textContent = text

module.exports = PopupRenderer
