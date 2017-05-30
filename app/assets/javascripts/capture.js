$(document).ready(function () {
  // References to all the element we will need.
  var video = document.querySelector('#camera-stream'),
      image = document.querySelector('#snap'),
      start_camera = document.querySelector('#webcam-capture'),
      stop_camera = document.querySelector('#webcam-close'),
      controls = document.querySelector('.controls'),
      take_photo_btn = document.querySelector('#take-photo'),
      delete_photo_btn = document.querySelector('#delete-photo'),
      download_photo_btn = document.querySelector('#download-photo'),

      error_message = document.querySelector('#error-message'),
      MediaStream;


  // The getUserMedia interface is used for handling camera input.
  // Some browsers need a prefix so here we're covering all the options
  navigator.getMedia = ( navigator.getUserMedia ||
                        navigator.webkitGetUserMedia ||
                        navigator.mozGetUserMedia ||
                        navigator.msGetUserMedia);


  // Mobile browsers cannot play video without user input,
  // so here we're using a button to start it manually.
  if (start_camera) {
    start_camera.addEventListener("click", function(e){
      if(!navigator.getMedia){
        displayErrorMessage("Your browser doesn't have support for the navigator.getUserMedia interface.");
      }
      else{
        // Request the camera.
        navigator.getMedia(
          {
            video: true
          },
          // Success Callback
          function(stream){

            // Create an object URL for the video stream and
            // set it as src of our HTLM video element.
            MediaStream = stream.getTracks()[0];
            video.src = window.URL.createObjectURL(stream);

            // Play the video element to start the stream.
            video.play();
            video.onplay = function() {
              showVideo();
            };

          },
          // Error Callback
          function(err){
            displayErrorMessage("There was an error with accessing the camera stream: " + err.name, err);
          }
        );

      }
    });

    stop_camera.addEventListener("click", function(e){
      MediaStream.stop();
      // $('#select-capture-image').attr('class', 'button w-button hide');
    });

    $("#webcam-close").visibilityChanged({
      callback: function(element, visible) {
        if (!visible && MediaStream) {
          MediaStream.stop();
          // $('#select-capture-image').attr('class', 'button w-button hide');
        }
      }
    });

    take_photo_btn.addEventListener("click", function(e){

      e.preventDefault();

      var snap = takeSnapshot();

      // Show image.
      image.setAttribute('src', snap);
      image.classList.add("visible");

      // Enable delete and save buttons
      delete_photo_btn.classList.remove("disabled");
      download_photo_btn.classList.remove("disabled");
      $('#select-capture-image').attr('class', 'button w-button');
      $('#select-capture-image').attr('img-data', snap);
      // Set the href attribute of the download button to the snap url.
      download_photo_btn.href = snap;

      // Pause video playback of stream.
      video.pause();

    });


    delete_photo_btn.addEventListener("click", function(e){

      e.preventDefault();

      // Hide image.
      image.setAttribute('src', "");
      image.classList.remove("visible");

      // Disable delete and save buttons
      delete_photo_btn.classList.add("disabled");
      download_photo_btn.classList.add("disabled");
      $('#select-capture-image').attr('class', 'button w-button hide');

      // Resume playback of stream.
      video.play();
    });

    $('#select-capture-image').on("click", function(e){
      e.preventDefault();
      imgUri = $('#select-capture-image').attr('img-data');
      read_webcam_img_picker(imgUri)
      stop_camera.click();
    });
  }

  function showVideo(){
    // Display the video stream and the controls.

    hideUI();
    video.classList.add("visible");
    controls.classList.add("visible");
  }


  function takeSnapshot(){
    // Here we're using a trick that involves a hidden canvas element.

    var hidden_canvas = document.querySelector('canvas'),
        context = hidden_canvas.getContext('2d');

    var width = video.videoWidth,
        height = video.videoHeight;

    if (width && height) {

      // Setup a canvas with the same dimensions as the video.
      hidden_canvas.width = width;
      hidden_canvas.height = height;

      // Make a copy of the current frame in the video on the canvas.
      context.drawImage(video, 0, 0, width, height);

      // Turn the canvas image into a dataURL that can be used as a src for our photo.
      debugger
      return hidden_canvas.toDataURL('image/png');
    }
  }


  function displayErrorMessage(error_msg, error){
    error = error || "";
    if(error){
      console.log(error);
    }

    error_message.innerText = error_msg;

    hideUI();
    error_message.classList.add("visible");
  }


  function hideUI(){
    // Helper function for clearing the app UI.

    controls.classList.remove("visible");
    start_camera.classList.remove("visible");
    video.classList.remove("visible");
    snap.classList.remove("visible");
    error_message.classList.remove("visible");
  }

  function read_webcam_img_picker(img_uri) {
    $('#select-images').val('');
    new_image_previews = $('#new-image-previews').html("");
    div = "<div class='images'>" +
            "<div href='#' class='deleteImagePreview' title='Profile Picture'>x</div>" +
            "<img class='editor-thumbnail' src='" + img_uri + "'" + "title='Profile Picture' />" +
            '<div class="editor-file-name shrink-text">Profile.png</div>' +
          "</div>";
    new_image_previews.prepend(div);
  }
})
