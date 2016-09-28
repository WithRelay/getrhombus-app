CKEDITOR.editorConfig = function (config) {
  config.toolbar = [
    { name: 'Insert', items: [ 'Link', 'Unlink' ] },
    { name: 'Editor toolbars', items: [ 'Image' ] },
    { name: 'basicstyles', groups: [ 'basicstyles', 'cleanup' ], items: [ 'Bold', 'Italic', 'Underline', 'Strike',] },
    { name: 'paragraph', items: ['NumberedList', 'BulletedList', '-', 'Outdent', 'Indent'] }
  ];
  config.extraPlugins = 'dragresize';
  config.filebrowserImageUploadUrl = 'http://'+ window.location.host +'/ckeditor/pictures'
}
