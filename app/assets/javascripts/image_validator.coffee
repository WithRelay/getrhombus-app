class @ImageValidator
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
