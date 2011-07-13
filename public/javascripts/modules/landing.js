function signUpAjaxRequest() {
    var form = $(this).parents("form");
    $("#affiliation_submit").attr("readonly", "readonly");
    $("#ajax-loader").removeClass('hidden');
    $("input#affiliation_email").attr("readonly", "readonly");

    return {
      success: function (data) {
        if (data.url) {
          window.location.href = data.url;
        }
      },

      complete: function () {
	$("#ajax-loader").addClass('hidden');
	$("#affiliation_submit").removeAttr("readonly");
	$("input#affiliation_email").removeAttr("readonly");
      }
    };
 }

 function emailtooltip(){
    $("#email-help").hover( function(e){
      $("#help-box").css({'left': e.pageX - 290, 'top': e.pageY - 50});
      $("#help-box").show();
    },
    function(){
      $("#help-box").hide();
    }
  );
 }
