class HideShow

  constructor: (element)->
    @element = element

  hide: ->
    $(@element).hide()

  display: ->
    $(@element).show()

class DatePicker

  RAILS_DATE_FORMAT = 'DD/MM/YYYY'

  constructor: (element)->
    @element = element
    nowDate = new Date();
    @today = new Date(nowDate.getFullYear(), nowDate.getMonth(), nowDate.getDate(), 0, 0, 0, 0);

  datePicker: ->
    $(@element).daterangepicker
      singleDatePicker: true,
      locale: { format: RAILS_DATE_FORMAT },
      startDate: @today

class Campaign

  CHECK = ':checked'

  constructor: (element) ->
    @element = element

  hideShowScheduler: ->
    if $('#deliverNow').is(CHECK)
      @element.hide()
    else if $('#deliverLater').is(CHECK)
      @element.display()

  datePicker: (campaignDate)->
    campaignDate.datePicker()

$(document).on 'ready page:load', ->
  campaign = new Campaign(new HideShow('.scheduleOption'))
  campaign.datePicker(new DatePicker('.daterange'))
  $('#deliverNow, #deliverLater').click ->
    campaign.hideShowScheduler()
