var exclude_list = Array();
Array.prototype.remove = function(e){
  i = this.indexOf(e);
  if(i > 1)
    this.splice(i, 1);
}

function makeBox(name, id){
  return '<div class="user" id="name_invited'+id+'"> <a class="remove" href="#" data="'+id+'">x</a> <div class="user-name"><a href="/users/'+id+'">' + name +'</a> </div></div>';
}

function initUserAutocomplete() {
  var userBox =
    new UserAutocomplete("#search-users",
                         "#search-users-results");

  var usersAlreadyFollowing = $.map( $(".user_id"), function(e, i){
    return $(e).attr("id");
  });

  userBox.actionData = function (data){
    return data;
  };

  userBox.maxRows = 7;

  userBox.filterDocs = function(docs) {
    var filteredDocs = [];

    var docsSize = docs.length;
    for (var i=0; i<docsSize; i++) {
      id = docs[i].id;
      if(id == undefined || ($("#excluded_user"+id).length == 0 &&
            $("#invited"+id).length == 0))
        filteredDocs.push(docs[i]);
    }
    if(filteredDocs.length == 0){
      filteredDocs.push({title: "User not found",
          entry_type : "NotFound"});
    }
    return filteredDocs;
  };

  // Sends to the server a request to suggest a topic named title
  // to a user named user.
  userBox.action = function (data) {
   if(data.id != undefined){
     input = $("<input>").attr({
         type: 'hidden',
         name: 'invited_ids[]',
         id : 'invited' + data.id
         }).val(data.id).appendTo(".invitation-ids");
     exclude_list[exclude_list.length] = data.id;
     $(".invite-button").removeAttr("disabled");
     $('.invited_users').html($('.invited_users').html() + makeBox(data.title, data.id));
     Utils.resizeModal();
     $("#search-users").val("");
   }
    userBox.clear();
  };

}

// Button to add the typed email to the list.
Utils.clickObject("#new_answer_request", function () {
  return {
    success: function(data) {
      Utils.showMessage(data.message, "notice");
      $.colorbox.close();
      $(".requested_users").html(data.html);
    }
  };

});

// Open the request to answer modal box
Utils.clickObject(".request-answer-button", function () {
  return {
    success: function(data) {
      Utils.modal({html : data.html});
      initUserAutocomplete();
    }
  };

});

$(".invited_users .remove").live("click", function () {
  id = $(this).attr("data");
  $("#invited"+id+"").replaceWith("");
  $("#name_invited"+id).replaceWith("");
  exclude_list.remove(id);
  return false;
});

