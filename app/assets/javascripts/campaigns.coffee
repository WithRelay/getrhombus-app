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
      emojify.setConfig( { emojify_tag_type:'div' } );
      emojify.run();
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
    txtEmoji = $(@textArea).emojioneArea ->
                 @emojiConfig
    txtEmoji[0].emojioneArea.on 'keyUp', (btn, event) ->
      $('#undefined_counter').html('')
      $('.emojionearea-editor').counter({ count: 'up', goal: MAXIMUM_VALUE })

$( document ).on 'ready page:load', ->
  campaign = new Campaign({ pickerPosition: 'right' })
  campaign.datePicker(new DatePicker( '.daterange' ))

  $(document).on 'change', 'input[name=file]', ->
    # this is for client side validation of locally uploaded images
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
        img.onload = (g)->
          window.invalid_image = false
        img.src = this.result;
      reader.readAsDataURL this.files[0]

  $(document).on 'click', 'form .trumbowyg-modal-submit',(e) ->
    if window.invalid_image
      alert 'Please upload image format with jpg/jpeg/png less than 4.5 mb'
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
    # this function is for uploading image via direct url
    img = new Image
    img.setAttribute 'crossOrigin', 'anonymous'
    img.onload = (e)->
      trumbowygHtml = $('#trumbowyg').trumbowyg('html')
      $.ajax(
        url: 'http://'+window.location.host+'/v1/campaigns/upload_images'
        type: 'POST'
        data: img_url: e.target.src
        dataType: 'json').done (data) ->
          if data.status == 200
            lastSrc = $('#trumbowyg').trumbowyg('html').split('src="').pop()
            newHtml = trumbowygHtml.replace(lastSrc, data.image_url + '">');
            imageIdHtml = '<input type="hidden" name="campaign[image_id][]" value="'+data.image_id+'">'
            $('.newMessage').append(imageIdHtml)
            $('#trumbowyg').trumbowyg('html', newHtml)
          else
            splitHtml = trumbowygHtml.split('src=').pop()
            imageTag = '<img src=' + splitHtml
            newHtml = trumbowygHtml.replace(imageTag, '');
            $('#trumbowyg').trumbowyg('html', newHtml);
            alert 'sorry only jpeg and png images are supported with less than 5 mb'
    img.src = url
    return
