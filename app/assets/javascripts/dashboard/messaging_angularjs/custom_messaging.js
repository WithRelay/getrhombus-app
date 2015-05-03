$(document).ready(function () {  

    // highlight chat box
    var chat_list = $('.user-list .item');
    $(chat_list).click(function() {
        $('.user-list .item.chat_highlight').removeClass('chat_highlight'); 
        $(this).addClass('chat_highlight');   
    });


});
