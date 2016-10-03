class @CustomTrumbowygPlugin

  constructor:(element) ->
    root_url = 'http://' + window.location.host
    $(element).trumbowyg
      svgPath: root_url + '/assets/icons.svg'
      btnsDef: image:
        dropdown: [
          'insertImage'
          'upload'
        ]
        ico: 'insertImage'
      btns: [
        [ 'viewHTML' ]
        [
          'undo'
          'redo'
        ]
        [ 'formatting' ]
        'btnGrp-design'
        [ 'link' ]
        [ 'image' ]
        'btnGrp-justify'
        'btnGrp-lists'
        [
          'foreColor'
          'backColor'
        ]
        [ 'preformatted' ]
        [ 'horizontalRule' ]
        [ 'fullscreen' ]
      ]
      plugins: upload:
        serverPath: root_url + '/v1/campaigns/upload_images'
        fileFieldName: 'image'
        urlPropertyName: 'data.link'
        success: (data, trumbowyg, modal)->
          if data.name
            if data.type == 'image'
              trumbowyg.execCmd 'insertImage', data.href
              $('img[src="' + data.href + '"]:not([alt])', trumbowyg.$box).attr 'alt', data.name
            else
              link = $([
                '<a href="'
                data.href
                '">'
                data.name
                '</a>'
              ].join(''))
              trumbowyg.range.insertNode link[0]
            setTimeout (->
              trumbowyg.closeModal()
              return
            ), 250
          else
            trumbowyg.addErrorOnModalField $('input[type=file]', modal), trumbowyg.lang.uploadError or data.message
