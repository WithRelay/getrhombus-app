$(document).ready(function () {  

  // this is actyally for campaigns not lists but uses lists
  // http://selectize.github.io/selectize.js/
  var campaign_lists = $('#campaign-select-lists').selectize({
    valueField: 'id',
    labelField: 'name',
    searchField: 'name',
    openOnFocus: false,
    maxOptions: 5,
    closeAfterSelect: true,
    render: {
        item: function(item, escape) {
          return '<div> <span class="name">' + escape(item.name) + '</span></div>';
        },
        option: function(item, escape) {
          return '<div><span class="label">' + escape(item.name) + '</span></div>';
        }
    },
    load: function(query, callback) {
      if (query.length < 3) return callback();
      $.ajax({
        url: window.location.protocol + "//" + window.location.host + "/v1/lists.json?query=" + encodeURIComponent(query),
        error: function() { callback(); },
        success: function(res) { callback(res['lists']); }
      });
    }
  });

  $( "#click-me" ).click(function() {
    alert(campaign_lists[0].selectize.getValue())
  });
  
});