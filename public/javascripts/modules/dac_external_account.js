$(document).ready(function() {
  $(".connect_dac").live("click", function() {
    $(this).hide();
    $(".dac_form").show();
    return false;
  });

  $(".cancel_dac").live("click", function() {
    $(".dac_form").hide();
    $(".connect_dac").show();
    return false;
  });

});
