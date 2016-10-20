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
  TRUMBOWYG = false
  MAXIMUM_VALUE = 1500

  constructor: (emojiConfig)->
    @textArea = '#trumbowyg'
    @emojiConfig = emojiConfig
    @oneTime = '#oneTimeFrequency'; @deliverNow = '#deliverNow'; @schedule = '.scheduleOption'

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
      $(emojiArea).hide()
    else
      $(area).trumbowyg('destroy');
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
    divText = this.textArea
    if $(@textArea).length > 1
      txtEmoji = $(@textArea).emojioneArea ->
                  @emojiConfig
      txtEmoji[0].emojioneArea.on 'keyUp', (btn, event) ->
        $('#undefined_counter').html('')
        $('.emojionearea-editor').counter({ count: 'up', goal: MAXIMUM_VALUE })

$( document ).on 'ready page:load', ->
  campaign = new Campaign({ pickerPosition: 'right' })
  campaign.datePicker(new DatePicker( '.daterange' ))

  $(document).on 'change', 'input[name=file]', ->
    uploadedImage = new ImageValidator
    uploadedImage.imageObj = this.files[0]
    if !uploadedImage.validateImage()
      alert 'Only image file formats with extension: jpg, jpeg, png, PNG, JPG, JPEG are allowed.'
      window.invalid_image = true
    else if !uploadedImage.validateSize()
      alert 'invalid upload size. Please upload image of size less then 4 MB'
      window.invalid_image = true
    else
      reader = new FileReader
      reader.onload = (e) ->
        img = new Image();
        img.onload = (e)->
          canvas = document.createElement("canvas");
          canvas.width = this.width
          canvas.height = this.height
          ctx = canvas.getContext('2d')
          ctx.drawImage this, 0, 0
          if e.target.src.split(';')[0]=="data:image/jpeg"
            window.target_result = e.target.src
          else
            canvas.toDataURL("image/jpeg");
          window.invalid_image = false
        img.src = this.result;
      reader.readAsDataURL this.files[0]

  $(document).on 'click', 'form .trumbowyg-modal-submit',(e) ->
    if window.invalid_image
      alert 'Please upload image format with jpg/jpef/png less than 4.5 mb'
      e.preventDefault()
    else
      getBase64FromImageUrl($('input[name=url]').val())

  if $('#campaign_channel').val() == '3'
    new CustomTrumbowygPlugin('#trumbowyg')
  else
    campaign.textAreaEmojis()

  $( '#campaign_channel' ).change ->
    campaign.showHideEditor(this)

  $( '#oneTimeFrequency' ).click ->
    $('#campaign_repeat_days').hide()

  $('#recurringFrequency').click ->
    $('#campaign_repeat_days').show()
    campaign.hideShowScheduler()

  # Mainly for edit actions so the view shows properly
  frequency_type = if $('#oneTimeFrequency').is(':checked') then '#oneTimeFrequency' else '#recurringFrequency'
  $(frequency_type).trigger('click')

  $( '#oneTimeFrequency, #deliverNow' ).click ->
    campaign.hideShowScheduler()

  getBase64FromImageUrl = (url) ->
    img = new Image
    img.setAttribute 'crossOrigin', 'anonymous'
    img.onload = (e)->
      $.ajax(
        url: 'http://' + window.location.host + '/v1/campaigns/upload_from_url'
        type: 'POST'
        data: img_url: e.target.src
        dataType: 'json').done (data) ->
          trumbowygHtml = $('#trumbowyg').trumbowyg('html')
          dataUrl = 'data:image/jpeg;base64,' + data.encoded_image
          lastSrc = $('#trumbowyg').trumbowyg('html').split('src="').pop()
          newHtml = trumbowygHtml.replace(lastSrc, dataUrl + '">');
          $('#trumbowyg').trumbowyg('html', newHtml)
    img.src = url
    return
