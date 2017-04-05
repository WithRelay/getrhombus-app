$(document).ready(function () {
  var file, button = $('#csv-upload-button'),
      file_picker_obj = document.getElementById('csv-file-select');

  $('#csv-file-select-btn').click(function() {
    $('#csv-file-select').click();
  });

  $('#csv-file-select').change(function() {
    file = this.files; // Get the selected files from the input.
    if (file && file.length) {
      if (file.length > 1)
        alert("Please upload one csv file");
      else {
        file = file[0];
        if (file.type.match('csv')) {
          $('#csv-file-name').text(file.name);
          return;
        } else
          alert("Can't upload file type");
      }
    }

    reset_file_picker();
  });

  function reset_file_picker() {
    file = null;
    file_picker_obj.value = "";
    $('#csv-file-name').text('No file chosen');
  }

  // http://blog.teamtreehouse.com/uploading-files-ajax
  // but modified to send just one file.
  button.click(function(e) {
    e.preventDefault();

    if (file) {
      button.text("Uploading...").prop('disabled', true);  
      var formData = new FormData(); // Create a new FormData object.
      formData.append('csv', file, file.name); // Add the file to the request.
      send_payload(formData);
    }
  });
  // end csv file upload

  function send_payload(payload) {
    var xhr = new XMLHttpRequest(); // Set up the request.
    xhr.open('POST', '/v1/merchant_customers.csv', true); // Open the connection.
    xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
    xhr.onload = function() {
      if (xhr.readyState === 4) {
        if (xhr.status === 200) {
          reset_file_picker();
        } else {
          //console.log('Something went wrong on our end.')
        }
        //console.log(JSON.parse(xhr.responseText));
        button.text("Import customers").prop('disabled', false);
      }
    };

    xhr.onerror = function(e) {
      console.log('Unable to upload csv file.');
      button.text("Import customers").prop('disabled', false);
    };
    xhr.send(payload); // Send the Data.
  };

});
