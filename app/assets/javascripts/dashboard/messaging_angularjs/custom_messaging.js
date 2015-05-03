$(document).ready(function () {  

    // highlight chat box
    $('.user-list').click(function() {
        $('.user-list .item.chat_highlight').removeClass('chat_highlight'); 
        $(this).addClass('chat_highlight');   
    });


});
