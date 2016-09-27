class DatePicker

  RAILS_DATE_FORMAT = 'DD/MM/YYYY h:mm A'
  YES = true

  constructor: (element)->
    @element = element
    nowDate = new Date();
    @today = new Date(nowDate.getFullYear(), nowDate.getMonth(), nowDate.getDate(), 0, 0, 0, 0);

  datePicker: ->
    $(@element).daterangepicker
      timePicker: YES,
      timePickerIncrement: 30,
      singleDatePicker: YES,
      locale: { format: RAILS_DATE_FORMAT },
      startDate: @today

class Campaign

  EMAIL_CHANNEL = '3'
  CHECK = ':checked'

  constructor: (emojiConfig)->
    @textArea = '#jodit'
    @emojiConfig = emojiConfig
    @joEdit = new Jodit(@textArea, 'toolbar': false)
    @oneTime = '#oneTimeFrequency'; @deliverNow = '#deliverNow'; @schedule = '.scheduleOption'

  showHideEditor: (element)->
    if isEmailChecked(element)
      joEditToolbarSetting(@joEdit, true)
    else
      joEditToolbarSetting(@joEdit, false)


  isEmailChecked = (channel) ->
    $(channel).val() == EMAIL_CHANNEL

  joEditToolbarSetting = (joEdit, status)->
    if status
      joEdit.$toolbar.show()
    else
      joEdit.$toolbar.hide()

  datePicker: (campaignDate)->
    campaignDate.datePicker()

  hideShowScheduler: ->
    if deliverNowOneTime_isChecked(@oneTime, @deliverNow)
      $(@schedule).hide()
    else
      $(@schedule).show()

  deliverNowOneTime_isChecked = (oneTime, deliverNow) ->
    $(oneTime).is(CHECK) && $(deliverNow).is(CHECK)


  textAreaEmojis: ->
    $(@textArea).emojioneArea ->
      @emojiConfig

  countCharacters: ->
    debugger;
    $('.characters').html this.joEdit.$area.val().length


$( document ).on 'ready page:load', ->
  campaign = new Campaign( { pickerPosition: 'right', tonesStyle: 'bullet' })
  campaign.datePicker(new DatePicker( '.daterange' ))
  $('.jodit_workflow').hide()
  campaign.textAreaEmojis()
  $( '#campaign_channel' ).change ->
    campaign.showHideEditor(this)

  $( '#oneTimeFrequency' ).click ->
    $('#campaign_repeat_days').hide()

  $('#recurringFrequency').click ->
    $('#campaign_repeat_days').show()
    campaign.hideShowScheduler()

  $( '#oneTimeFrequency, #deliverNow' ).click ->
    campaign.hideShowScheduler()
