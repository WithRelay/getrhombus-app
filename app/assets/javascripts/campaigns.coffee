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
    @textArea = '#trumbowyg'
    @emojiConfig = emojiConfig
    @oneTime = '#oneTimeFrequency'; @deliverNow = '#deliverNow'; @schedule = '.scheduleOption'
    @emojiHtml

  showHideEditor: (element)->
    if isEmailChecked(element)
      trumbowygSetting(true, @textArea)
    else
      trumbowygSetting(false, @textArea)

  isEmailChecked = (channel) ->
    $(channel).val() == EMAIL_CHANNEL

  trumbowygSetting = (status, area)->
    emojiArea = '.emojionearea'
    if status
      new CustomTrumbowygPlugin(area)
      countCharacters()
      $(emojiArea).hide()
    else
      $(area).trumbowyg('destroy');
      $(area).emojioneArea({pickerPosition:'right',tonesStyle:'bullet'})
      $(emojiArea).show()
      $(area).hide()

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

  countCharacters = ->
    $('.trumbowyg-editor').counter
      append: true

$( document ).on 'ready page:load', ->
  campaign = new Campaign( { pickerPosition: 'right', tonesStyle: 'bullet' })
  campaign.datePicker(new DatePicker( '.daterange' ))

  if $('#campaign_channel').val()=='3'
    new CustomTrumbowygPlugin('#trumbowyg')
    $('.trumbowyg-editor').counter
      append: true
  else
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
