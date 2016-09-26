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

  constructor: (element) ->
    @joEdit = new Jodit('#jodit', 'toolbar': false)
    @element = element
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

class ImageValidater
  constructor: ->
   @maxSizeKb = 4000
   @allowedExtension = [ 'jpg', 'jpeg', 'png', 'PNG', 'JPG', 'JPEG' ]
   @imageObj

  validateImage: ->
   imageName = @imageObj.name.split('.').pop()
   if imageName in @allowedExtension
    return true
   else
    return false

  validateSize: ->
   imgSize = @imageObj.size
   imgSizeKb = Math.round(imgSize / 1024)
   if imgSizeKb < @maxSizeKb
    return true
   else
    return false

  previewImage: (element) ->
    if element.files && element.files[0]
      reader = new FileReader()
      reader.onload = (e)->
        $('#imagePreview').attr('src', e.target.result)
      reader.readAsDataURL(element.files[0]);



$( document ).on 'ready page:load', ->
  campaign = new Campaign()
  campaign.datePicker(new DatePicker( '.daterange' ))
  $( '#campaign_channel' ).change ->
    campaign.showHideEditor(this)
  $( '#oneTimeFrequency, #deliverNow' ).click ->
    campaign.hideShowScheduler()
  $('#campaignMessageAttachment').change ->
    uploadedImage = new ImageValidater
    uploadedImage.imageObj = this.files[0]
    if !uploadedImage.validateImage()
      alert 'Only image file formats with extension: jpg, jpeg, png, PNG, JPG, JPEG are allowed.'
    else if !uploadedImage.validateSize()
      alert 'invalid upload size. Please upload image of size less then 4 MB'
    else
      uploadedImage.previewImage(this)
