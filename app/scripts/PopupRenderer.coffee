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


  constructor: (props) ->
    @datepicker = props.datepicker
    @theme = props.theme

    @prefix = props.prefix if props.prefix
    @onlyFuture = @datepicker.onlyFuture
    daysNames = @datepicker.t.days
    sundayFirst = @datepicker.t.start_from_sunday
    daysNames.unshift(daysNames.pop()) if sundayFirst
    @monthRenderer = new MonthRenderer({
      daysNames
      sundayFirst
      visibleWeeksNum: props.visibleWeeksNum
      clickableDaysInFuture: props.clickableDaysInFuture
      callback: props.listener
      prefix: @prefix
      onlyFuture: @onlyFuture
      theme: @theme
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
    prevMonthNode.innerHTML = '<svg version="1.2" baseProfile="tiny" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 30.6 24.6"><path fill="#000" d="M.6 10.8l.2-.2 9.9-10c.8-.8 2.2-.8 3 0l.3.2c.8.8.8 2.2 0 3L7.9 10h20.6c1.2 0 2.1 1 2.1 2.1v.3c0 1.2-1 2.1-2.1 2.1H7.9l6.2 6.2c.8.8.8 2.2 0 3l-.3.3c-.8.8-2.2.8-3 0L.8 14l-.2-.2c-.8-.8-.8-2.2 0-3z"/></svg>'
    headerNode.appendChild prevMonthNode

    @MonthNode = document.createElement('span')
    @MonthNode.setAttribute('role', 'tp-datepicker-month')
    headerNode.appendChild @MonthNode

    nextMonthNode = document.createElement('span')
    nextMonthNode.className = "#{@prefix}tp-datepicker-next-month-control"
    nextMonthNode.setAttribute('role', 'tp-datepicker-next')
    nextMonthNode.innerHTML = '<svg version="1.2" baseProfile="tiny" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 30.6 24.6"><path fill="#000" d="M.6 10.8l.2-.2 9.9-10c.8-.8 2.2-.8 3 0l.3.2c.8.8.8 2.2 0 3L7.9 10h20.6c1.2 0 2.1 1 2.1 2.1v.3c0 1.2-1 2.1-2.1 2.1H7.9l6.2 6.2c.8.8.8 2.2 0 3l-.3.3c-.8.8-2.2.8-3 0L.8 14l-.2-.2c-.8-.8-.8-2.2 0-3z"/></svg>'
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
