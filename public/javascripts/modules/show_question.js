$(document).ready(function() {
  initTopicAutocompleteForReclassifying();
  $("#close_question_form").hide();
  $('input#question_title').focus();

  Utils.clickObject(".comment .comment-votes form.vote-up-comment-form", function () {
    var form = $(this);
    var btn = $(this).find("input[name=vote_up]");
    btn.hide();

    return {
      success: function (data) {
        if(data.vote_state == "deleted") {
          btn.attr("src", "/images/dialog-ok.png" );
        } else {
          btn.attr("src", "/images/dialog-ok-apply.png" );
        }
        btn.parents(".comment-votes").children(".votes_average").html(data.average);
      },

      complete: function () { btn.show(); }
    };
  });

  Utils.clickObject("form.mainAnswerForm", function () {
    var form = $(this);
    var answers = $("#answers .hentry");
    var button = $(this).find(".button");

    return {
      success: function (data) {
        window.onbeforeunload = null;
        var answer = $(data.html);
        var content = answer.find(".entry-content");
        answers.append(answer);
        highlightEffect(answer);
        $('#new-answer-wrapper').html(data.form_message);
        MathJax.Hub.Queue(['Typeset', MathJax.Hub, answer[0]]);
      },

      error: function (data) {
        if(data.status == "unauthenticate") {
          Utils.redirectToSignIn();
        }
      }
    };
  });

  // Send new comment.
  Utils.clickObject("form.commentForm", function () {
    var form = $(this);
    var comments = $(this).closest(".commentable").find(".comments");
    var button = $(this).find(".button");

    return {
      success: function (data) {
        // TODO: center screen on new comment.
        var textarea = form.find("textarea");
        window.onbeforeunload = null;
        var comment = $(data.html);
        comments.append(comment);
        comments.closest(".commentable").find(".ccontrol").replaceWith(data.count);
        highlightEffect(comment);
        textarea.val("");
        MathJax.Hub.Queue(['Typeset', MathJax.Hub, comment[0]]);
      },

      error: function (data) {
        if(data.status == "unauthenticate") {
          Utils.redirectToSignIn();
        }
      }
    };
  });

  $(".edit_comment").live("click", function() {
    var comment = $(this).parents(".comment");
    var link = $(this);
    link.hide();
    $.ajax({
      url: $(this).attr("href"),
      dataType: "json",
      type: "GET",
      data: {format: 'js'},
      success: function(data) {
        comment = comment.append(data.html);
        link.hide();
        var form = comment.find("form.form");
        form.find(".cancel_edit_comment").click(function() {
          form.remove();
          link.show();
          return false;
        });

        var button = form.find("input[type=submit]");
        var textarea = form.find('textarea');
        form.submit(function() {
          button.attr('disabled', true);
          $.ajax({url: form.attr("action"),
                  dataType: "json",
                  type: "PUT",
                  data: form.serialize()+"&format=js",
                  success: function(data, textStatus) {
                              if(data.success) {
                                comment.find(".markdown").html('<p>'+data.body+'</p>');
                                form.remove();
                                link.show();
                                highlightEffect(comment);
                                showMessage(data.message, "notice");
                                window.onbeforeunload = null;
                              } else {
                                showMessage(data.message, "error");
                                if(data.status == "unauthenticate") {
                                  Utils.redirectToSignIn();
                                }
                              }
                            },
                  error: manageAjaxError,
                  complete: function(XMLHttpRequest, textStatus) {
                    button.attr('disabled', false);
                  }
           });
           return false;
        });
      },
      error: manageAjaxError,
      complete: function(XMLHttpRequest, textStatus) {
        link.show();
      }
    });
    return false;
  });

  $(".flag_form .cancel").live("click", function() {
    $("#question_flag_div").html('');
    return false;
  });

  $(".answer .flag-link").live("click", function() {
    var link = $(this);
    var controls = link.parents(".controls");
    $.ajax({
      url: $(this).attr("href"),
      dataType: "json",
      type: "GET",
      success: function(data) {
        controls.parents(".answer").find("#answer_flag_div").html(data.html);
        return false;
      }
    });

    return false;
  });

  $("#question_flag_link.flag-link").click(function() {
    $.ajax({
      url: $(this).attr("href"),
      dataType: "json",
      type: "GET",
      success: function(data) {
        $("#question_flag_div").html(data.html);
        $("#request_close_question_form").slideUp();
        $("#close_question_form").slideUp();
        return false;
      }
    });
    return false;
  });

  // TODO: see if this is still necessary.
  $(".question-action").live("click", function(event) {
    var link = $(this);
    if(!link.hasClass('busy')){
      link.addClass('busy');
      var href = link.attr("href");
      var dataUndo = link.attr("data-undo");
      var title = link.attr("title");
      var dataTitle = link.attr("data-title");
      var img = link.children('img');
      var counter = $(link.attr('data-counter'));
      $.getJSON(href+'.js', function(data){
        if(data.success){
          link.attr({href: dataUndo, 'data-undo': href, title: dataTitle, 'data-title': title });
          img.attr({src: img.attr('data-src'), 'data-src': img.attr('src')});
          if(typeof(data.increment)!='undefined'){
            counter.text(parseFloat($.trim(counter.text()))+data.increment);
          }
          showMessage(data.message, "notice");
        } else {
          showMessage(data.message, "error");

          if(data.status == "unauthenticate") {
            Utils.redirectToSignIn();
          }
        }
        link.removeClass('busy');
        }, "json");
      }
    return false;
  });

  // Display comments and new comment form.
  $(".ccontrol-link").live("click", function () {
    $(this).closest(".commentable").find(".comments_wrapper").slideToggle("slow");
    return false;
  });
});
