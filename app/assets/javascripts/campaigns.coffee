class @DatePicker

  RAILS_DATE_FORMAT = 'YYYY-MM-DD h:mm A'
  YES = true

  constructor: (element, time, dateSelect)->
    @element = element
    @time = time
    date = new Date();
    @minimumDate = dateSelect.select
    dateRangeValue = $('.daterange').val()
    if dateRangeValue == undefined || dateRangeValue == ""
      @today = new Date(date.getFullYear(), date.getMonth(), date.getDate());
    else
      dateRange = dateRangeValue.split('-')
      @today = new Date(dateRange[0], dateRange[1]-1, dateRange[2].split(" ")[0]);

  datePicker: ->
    today = @today # @today is assign in local variable because of some reason coffescript thinks @today is a object
    if $(@element).length > 0
      min = @minimumDate ? today : false
      setFormat = @time ? RAILS_DATE_FORMAT : 'YYYY-MM-DD'
      $(@element).daterangepicker
        time: @time,
        timePickerIncrement: 30,
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
    @oneTime = '#oneTimeFrequency'; @deliverNow = '#deliverNow'; @schedule = '.scheduleOption'

  showHideEditor: (element)->
    if isEmailChecked(element)
      $('.emailSubject').show()
      this.showFileBrowser()
      trumbowygSetting(true, @textArea)
      removeDiv()
    else if isMmsChecked(element) || isFacebookMessengerChecked(element)
      this.showFileBrowser()
      $('.emailSubject').hide()
      trumbowygSetting(false, @textArea)
      removeDiv()
      $('.emojionearea-editor').counter({ type: 'char', append: false, target: '#textBoxCounter' })
    else
      removeDiv()
      $('.emojionearea-editor').counter({ type: 'char', append: false, target: '#textBoxCounter' })
      $('.emailSubject').hide()
      $('#select-images').val('')
      $('.images').html('')
      this.hideFileBrowser()
      trumbowygSetting(false, @textArea)

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
      txtEmoji = $(@textArea).emojioneArea ->
                   @emojiConfig

  removeDiv = ->
    $('#undefined_counter').each ->
      $(this).remove()


$( document ).on 'ready page:load', ->
  campaign = new Campaign({ pickerPosition: 'right' })
  campaign.datePicker(new DatePicker( '.daterange', true, { select: true } ))
  window.onload = ->
    $('.emojionearea-editor').counter({ type: 'char', append: false, target: '#textBoxCounter' })

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
      $('body').addClass('loading')
      getBase64FromImageUrl($('input[name=url]').val())

  if $('#campaign_channel').val() == '3'
    $('.emailSubject').show()
    new CustomTrumbowygPlugin('#trumbowyg')
    campaign.showFileBrowser()
  else if $('#campaign_channel').val() == '1'
    campaign.showFileBrowser()
    $('.emailSubject').hide()
    campaign.textAreaEmojis()
  else if $('#campaign_channel').val() == '2'
    $('.emailSubject').hide()
    campaign.showFileBrowser()
    campaign.textAreaEmojis()
  else
    campaign.textAreaEmojis()
    campaign.hideFileBrowser()
    $('.emailSubject').hide()
    $('#select-images').val('')
    $('.images').html('')

  $( '#campaign_channel' ).change ->
    campaign.showHideEditor(this)

  $( '#oneTimeFrequency' ).click ->
    $('#campaign_repeat_days').hide()

  $('#recurringFrequency').click ->
    $('#campaign_repeat_days').show()
    campaign.hideShowScheduler()

  if $("#deliverNow").is(":checked")
    $('.scheduleOption').hide()
    $('.daterange').val('')

  # Mainly for edit actions so the view shows properly
  frequency_type = if $('#oneTimeFrequency').is(':checked') then '#oneTimeFrequency' else '#recurringFrequency'
  $(frequency_type).trigger('click')

  $( '#oneTimeFrequency, #deliverNow' ).click ->
    if !$("#deliverNow").is(":checked")
      campaign.datePicker(new DatePicker( '.daterange', { time: true } ))
    campaign.hideShowScheduler()

  getBase64FromImageUrl = (url) ->
    # this function is for uploading image via direct url
    img = new Image
    img.setAttribute 'crossOrigin', 'anonymous'
    img.onload = (e)->
      $('body').addClass('loading')
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
            $('#trumbowyg').trumbowyg('html', newHtml)
            $('body').removeClass('loading')
          else
            $('body').removeClass('loading')
            splitHtml = trumbowygHtml.split('src=').pop()
            imageTag = '<img src=' + splitHtml
            newHtml = trumbowygHtml.replace(imageTag, '');
            $('#trumbowyg').trumbowyg('html', newHtml);
            alert 'sorry only jpeg and png images are supported with less than 5 mb'
    img.src = url
    return
