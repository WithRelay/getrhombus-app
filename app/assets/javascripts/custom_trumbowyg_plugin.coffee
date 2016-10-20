class @CustomTrumbowygPlugin

  constructor:(element) ->
    root_url = 'http://' + window.location.host
    $(element).trumbowyg
      svgPath: root_url + '/assets/icons.svg'
      autogrow: true
      btnsDef: image:
        dropdown: [ 'insertImage', 'upload' ]
        ico: 'insertImage'
      btns: [ [ 'viewHTML' ], [ 'undo', 'redo'], [ 'formatting' ], 'btnGrp-design', [ 'link' ]
        [ 'image' ], 'btnGrp-justify', 'btnGrp-lists', [ 'foreColor', 'backColor']
        [ 'preformatted' ]
        [ 'emoji' ]
        [ 'horizontalRule' ]
        [ 'fullscreen' ]
      ]
      plugins: upload:
        serverPath: root_url + '/v1/campaigns/upload_images'
        fileFieldName: 'image'
        urlPropertyName: 'data.link'
        success: (data, trumbowyg, modal)->
          if data.status == 200
            if data.message == 'success'
              url = data.image_url
              trumbowyg.execCmd('insertImage', url)
              $('img', trumbowyg.$box).attr('src', url)
              $('img', trumbowyg.$box).attr('alt', 'image')
              $('img', trumbowyg.$box).attr('text', 'image')
              imageIdHtml = '<input type="hidden" name="campaign[image_id][]" value="'+data.image_id+'">'
              $('.newMessage').append(imageIdHtml)
            setTimeout (->
              trumbowyg.closeModal()
              return
            ), 250
          else
            trumbowyg.addErrorOnModalField $('input[type=file]', modal), trumbowyg.lang.uploadError or data.message
