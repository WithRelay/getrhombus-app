class @ImageValidator
  constructor: ->
   @maxSizeKb = 4000
   @maxTotalSizeKb = 25000
   @allowedExtension = ['jpeg', 'png', 'PNG', 'JPEG', 'jpg', 'JPG' ]
   @imageObj

  validateImage: ->
   imageName = @imageObj.name.split('.').pop()
   imageName in @allowedExtension

  validateSize: ->
   imgSize = @imageObj.size
   imgSizeKb = Math.round(imgSize / 1024)
   return imgSizeKb < @maxSizeKb

  validateTotalSize: ->
   imgSize = @imageObj.size
   imgSizeKb = Math.round(imgSize / 1024)
   total_size = parseInt(imgSizeKb);
   $('#new-image-previews .images img').each ->
     total_size = total_size + parseInt($(this).attr('size'))
   return total_size < @maxTotalSizeKb
