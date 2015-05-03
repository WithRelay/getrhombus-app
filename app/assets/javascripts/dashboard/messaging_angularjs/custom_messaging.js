$(document).ready(function () {  

    // highlight chat box
    $('.user-list .item').click(function() {
        $('.user-list .item.chat_highlight').removeClass('chat_highlight'); 
        $(this).addClass('chat_highlight');   
        alert('ads');
    });


});
