/* Sidebar Menu*/
$(document).ready(function () {
  $('.nav > li > a').click(function(){
    if ($(this).attr('class') != 'active'){
      $('.nav li ul').slideUp();
      $(this).next().slideToggle();
      $('.nav li a').removeClass('active');
      $(this).addClass('active');
    }
  });

  /* Top Stats Show Hide */
  $("#topstats").click(function(){
        $(".topstats").slideToggle(100);
    });

  /* Sidepanel Show-Hide */
  $(".sidepanel-open-button").click(function(){
        $(".sidepanel").toggle(100);
    });

  
    $(".sidebar-open-button-mobile").click(function(){
        $(".sidebar").toggle(150);
    });

    /* Sidebar Show-Hide */
  $('.sidebar-open-button').on('click', function(){
        if($('.sidebar').hasClass('hidden')){
            $('.sidebar').removeClass('hidden');
            $('.content').css({
                'marginLeft' : 250
            });  
        }else{
            $('.sidebar').addClass('hidden');
            $('.content').css({
                'marginLeft' : 0
            });    
        }
    });

  /* expand */
  $('.panel-tools .expand-tool').on('click', function(){
        if($(this).parents(".panel").hasClass('panel-fullsize'))
        {
            $(this).parents(".panel").removeClass('panel-fullsize');
        }
        else
        {
            $(this).parents(".panel").addClass('panel-fullsize');
 
        }
    });


});





/* Page Loading */
$(window).load(function() {
  $(".loading").fadeOut(750);
})