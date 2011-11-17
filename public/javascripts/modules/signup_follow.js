$(document).ready(function () {
  if ($("#wait-notice").length > 0) {
    $.getJSON("/signup/find.js", function (data) {
      if (data.success) {
        var content = $("#interaction #content");
        var suggestions = $(data.html);
        $("#wait-notice").slideUp("slow", function () {
          $(this).remove();
          suggestions.css("display", "none");
          content.append(suggestions);
          suggestions.slideDown("slow");
          Utils.poshytipfy();
        });
      }
    });
  }

  $("#finish-classify").click( function() {
    $.ajax({
      url: "/topics/classify.js",
      type: "POST",
      data: $(document).find("form").serialize(),
      success: function(data) {
        window.location.href = "/signup/finish";
        return false;
      }
    });
    return false;
  });

});
