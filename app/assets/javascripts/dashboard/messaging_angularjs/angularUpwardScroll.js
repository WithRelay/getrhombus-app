!function(){"use strict";function l(l){
  function o(o,r,c){
    var n=r[0];
    r.bind("scroll",function(){
      var originalHeight = $(n)[0].scrollHeight
      if(n.scrollTop<=0){
        var i=n.scrollHeight;
        o.$apply(c.upwardsScoll)
        // This code is added later
        if ($('.messageStatus').html().trim() == ""){
          r.scrollTop(208);
        }
        // This is a plugin code commented which was not working.
        // ,l(function(){
        //   r.animate({scrollTop:n.scrollHeight-i},500)},0)
        }

        }),l(function(){
            o.$apply(function(){r.scrollTop(n.scrollHeight)})},0)}
            var r={link:o,restrict:"A"};return r
          }
          angular.module("upwards-scroll",[]),angular.module("upwards-scroll").directive("upwardsScoll",l),l.$inject=["$timeout"]}();
