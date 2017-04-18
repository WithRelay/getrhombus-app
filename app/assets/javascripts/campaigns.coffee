class @DatePicker

  RAILS_DATE_FORMAT = 'YYYY-MM-DD h:mm A'
  YES = true

  constructor: (element, time, dateSelect)->
    @element = element
    @time = time
    date = new Date();
    @minimumDate = dateSelect.select
    dateRangeValue = $('.daterange').val()
    # if dateRangeValue == undefined || dateRangeValue == ""
    @today = new Date(date.getFullYear(), date.getMonth(), date.getDate());
    # # else
    #   dateRange = dateRangeValue.split('-')
    #   @today = new Date(dateRange[0], dateRange[1]-1, dateRange[2].split(" ")[0]);

  datePicker: ->
    today = @today
    time = @time
    if @minimumDate
      min = today
    else
      min = false
    if $(@element).length > 0
      if time
        setFormat = RAILS_DATE_FORMAT
      else
        setFormat = 'YYYY-MM-DD'
      $(this.element).daterangepicker
        timePicker: time,
        timePickerIncrement: 60,
        drops: "up",
        singleDatePicker: YES,
        locale: { format: setFormat },
        minDate: min

class Campaign

  EMAIL_CHANNEL = '3'; MMS_CHANNEL = '1'; MESSENGER_CHANNEL = '2'
  CHECK = ':checked'
  TRUMBOWYG = false
  MAXIMUM_VALUE = 1500

  constructor: (emojiConfig)->
    @textArea = '#trumbowyg'
    @emojiConfig = emojiConfig
    @oneTime = '#oneTimeFrequency'; @deliverNow = '#Deliver-now'; @schedule = '.scheduleOption'

  showHideEditor: (element)->
    if isEmailChecked(element)
      $('.emailSubject').show()
      $('#sendTestCampaign').show()
      this.showFileBrowser()
      trumbowygSetting(true, @textArea)
      removeDiv()
      $('.welcome-dash-content-container-header').show()
      $('#textBoxCounter').html('upload an image')
    else if isMmsChecked(element) || isFacebookMessengerChecked(element)
      this.showFileBrowser()
      $('.emailSubject').hide()
      trumbowygSetting(false, @textArea)
      removeDiv()
      $('#sendTestCampaign').hide()
      $('#textBoxCounter').html($('#textBoxCounter').html().replace('upload an image', ''))
      $('.welcome-dash-content-container-header').hide()
      $('.newMessage .emojionearea-editor').counter({ type: 'char', append: false, target: '#textBoxCounter', goal: 1600, msg: 'characters' })
    else
      removeDiv()
      $('.emailSubject').hide()
      $('#select-images').val('')
      $('#new-image-previews').html('')
      $('#sendTestCampaign').hide()
      this.hideFileBrowser()
      $('#textBoxCounter').html($('#textBoxCounter').html().replace('upload an image', ''))
      $('.welcome-dash-content-container-header').hide()
      trumbowygSetting(false, @textArea)
      $('.newMessage .emojionearea-editor').counter({ type: 'char', append: false, target: '#textBoxCounter', goal: 1600, msg: 'characters' })

  isEmailChecked = (channel) ->
    $(channel).val() == EMAIL_CHANNEL

  isFacebookMessengerChecked = (channel) ->
    $(channel).val() == MESSENGER_CHANNEL

  isMmsChecked = (channel) ->
    $(channel).val() == MMS_CHANNEL

  trumbowygSetting = (status, area)->
    emojiArea = '.emojionearea'
    if status
      new CustomTrumbowygPlugin(area)
      emojify.setConfig( { emojify_tag_type:'div' } );
      emojify.run();
      $(emojiArea).hide()
      $('#textBoxCounter').html('')
    else
      $(area).trumbowyg('destroy');
      $(emojiArea).show()
      $(area).hide()

  datePicker: (campaignDate)->
    campaignDate.datePicker()

  hideShowScheduler: ->
    if deliverNowOneTime_isChecked(@oneTime, @deliverNow)
      $(@schedule).hide()
      $('.daterange').val('')
    else
      $(@schedule).show()

  deliverNowOneTime_isChecked = (oneTime, deliverNow) ->
    $(oneTime).is(CHECK) && $(deliverNow).is(CHECK)

  showFileBrowser: ->
    $(".upload_image").show()

  hideFileBrowser: ->
    $(".upload_image").hide()

  textAreaEmojis: ->
    if $(@textArea).length > 0
      txtEmoji = $(@textArea).emojioneArea(@emojiConfig)

  removeDiv = ->
    $('#undefined_counter').each ->
      $(this).remove()

$( document ).on 'ready page:load', ->
  $('.scheduleOption').hide()
  campaign = new Campaign({ pickerPosition: "bottom", tonesStyle: "bullet" })
  campaign.datePicker(new DatePicker( '.daterange', true, { time: true, select: true } ))
  window.onload = ->
    $('.newMessage .emojionearea-editor').counter({ type: 'char', append: false, target: '#textBoxCounter', goal: 1600, msg: 'characters' })

  $(document).on 'change', 'input[name=file]', ->
    # this is for client side validation of locally uploaded images
    uploadedImage = new ImageValidator
    uploadedImage.imageObj = this.files[0]
    if !uploadedImage.validateImage()
      alert 'Only image file formats with extension: jpg, jpeg, png, PNG, JPG, JPEG are allowed.'
      window.invalid_image = true
    else if !uploadedImage.validateSize()
      alert 'invalid upload size. upload image should be less than 4 mb'
      window.invalid_image = true
    else if !uploadedImage.validateTotalSize()
      alert 'invalid upload size. Total upload image should be less than 25 mb'
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
      $('.loading').css({'position': 'absolute', 'z-index': 3, 'margin': '0px'});
      $('.loading').show();
      getBase64FromImageUrl($('input[name=url]').val())

  if $('#Channel').val() == '3'
    $('.emailSubject').show()
    $('.welcome-dash-content-container-header').show()
    $('#sendTestCampaign').show();
    new CustomTrumbowygPlugin('#trumbowyg')
    campaign.showFileBrowser()
  else if $('#Channel').val() == '1'
    $('#sendTestCampaign').hide();
    campaign.showFileBrowser()
    $('.emailSubject').hide()
    campaign.textAreaEmojis()
  else if $('#Channel').val() == '2'
    $('#sendTestCampaign').hide();
    $('.emailSubject').hide()
    campaign.showFileBrowser()
    campaign.textAreaEmojis()
  else
    $('#sendTestCampaign').hide();
    campaign.textAreaEmojis()
    campaign.hideFileBrowser()
    $('.emailSubject').hide()
    $('#select-images').val('')
    $('#new-image-previews').html('')

  $( '#Channel' ).change ->
    campaign.showHideEditor(this)

  $( '#oneTimeFrequency' ).click ->
    $('#campaign_repeat_days').hide()

  $('#recurringFrequency').click ->
    $('#campaign_repeat_days').show()
    campaign.hideShowScheduler()

  if $("#Deliver-now").is(":checked")
    $('.scheduleOption').hide()
    $('.daterange').val('')
  else
    $('.scheduleOption').show();

  # Mainly for edit actions so the view shows properly
  frequency_type = if $('#oneTimeFrequency').is(':checked') then '#oneTimeFrequency' else '#recurringFrequency'
  $(frequency_type).trigger('click')

  $( '#oneTimeFrequency, #Deliver-now' ).click ->
    if !$("#Deliver-now").is(":checked")
      campaign.datePicker(new DatePicker( '.daterange', true, { time: true, select: true } ))
    campaign.hideShowScheduler()

  getBase64FromImageUrl = (url) ->
    # this function is for uploading image via direct url
    img = new Image
    img.setAttribute 'crossOrigin', 'anonymous'
    img.onload = (e)->
      $('.loading').css({'position': 'absolute', 'z-index': 3, 'margin': '0px'});
      $('.loading').show();
      trumbowygHtml = $('#trumbowyg').trumbowyg('html')
      $.ajax(
        url: window.location.protocol + '//'+window.location.host+'/v1/campaigns/upload_images'
        type: 'POST'
        data: img_url: e.target.src
        dataType: 'json').done (data) ->
          if data.status == 200
            lastSrc = $('#trumbowyg').trumbowyg('html').split('src="').pop()
            newHtml = trumbowygHtml.replace(lastSrc, data.image_url + '">');
            imageIdHtml = '<input type="hidden" name="campaign[image_id][]" value="'+data.image_id+'">'
            $('.newMessage').append(imageIdHtml)
            $('#trumbowyg').trumbowyg('html', newHtml);
            $('.loading').css({'position': '', 'z-index': '', 'margin': ''});
            $('.loading').hide();
          else
            $('.loading').css({'position': '', 'z-index': '', 'margin': ''});
            $('.loading').hide();
            splitHtml = trumbowygHtml.split('src=').pop()
            imageTag = '<img src=' + splitHtml
            newHtml = trumbowygHtml.replace(imageTag, '');
            $('#trumbowyg').trumbowyg('html', newHtml);
            alert 'sorry only jpeg and png images are supported with less than 5 mb'
    img.src = url
    return
