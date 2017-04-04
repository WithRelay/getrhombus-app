$(document).ready(function () {

  // http://blog.teamtreehouse.com/uploading-files-ajax
  // but modified to send just one file.
  $('#csv-upload-form').submit(function(e) {
    e.preventDefault();
    var button = $('#csv-upload-button').text("Uploading...").prop('disabled', true);

    function send_payload(payload) {
      var xhr = new XMLHttpRequest(); // Set up the request.
      xhr.open('POST', '/v1/merchant_customers.csv', true); // Open the connection.
      xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
      xhr.onload = function() {
        if (xhr.readyState === 4) {
          if (xhr.status === 200) {} else {
            console.log('Something went wrong on our end.')
          }
          console.log(JSON.parse(xhr.responseText));
          button.text("Upload").prop('disabled', false);
        }
      };

      xhr.onerror = function(e) {
        console.log(xhr.statusText);
        button.text("Upload").prop('disabled', false);
      };
      xhr.send(payload); // Send the Data.
    }

    var file = document.getElementById('csv-file-select').files; // Get the selected files from the input.
    if (file && file.length == 1) {
      file = file[0];
      if (!file.type.match('csv')) { // Check the file type.
        alert("Can't upload file type");
        button.text("Upload").prop('disabled', false);
        return;
      }

      var formData = new FormData(); // Create a new FormData object.
      formData.append('csv', file, file.name); // Add the file to the request.
      send_payload(formData);
    } else {
      button.text("Upload").prop('disabled', false);
    }
  });
  // end csv file upload

});
