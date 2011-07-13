// Follow/unfollow buttons
$(document).ready(function() {
  // Only selects '.follow_link's that may not have been selected
  Utils.clickObject(".follow_link:not(#topic-suggestions a):not(#users-topic-suggestions a)", function () {
    var link = $(this);

    // The type of what's being followed
    var entryType = link.attr("data-entry-type");

    return {
      success: function (data) {
        var followers =
          $("#sidebar .followers[data-entry-type=" + entryType + "]");
        if (followers.size() > 0) {
          if (data.follower && followers.find(".friend_list span").size() < 21) {
            element = $(data.follower);
            element.hide();
            followers.find(".friend_list").append(element);
            element.fadeIn("slow");
          }
          if (data.followers_count) {
            var oldCount = followers.find(".count");
            if (oldCount.size() == 0) {
              followers.find(".title").
                prepend("<span class=\"count\">" + data.followers_count +
                        "</span>");
            } else {
              followers.find(".count").html(data.followers_count);
            }
          }
        }
        Utils.toggleFollowLink(link);

        // Toggle email subscription option's visibility
        $("#email-subscription").removeClass('hidden');
      },

      error: function (data) {
        if (data.status == "unauthenticate") {
          Utils.redirectToSignIn();
        }
      },

      type: "POST"
    };
  });

  Utils.clickObject(".unfollow_link", function () {
    var link = $(this);

    // The type of what's being followed
    var entryType = link.attr("data-entry-type");

    return {
      success: function (data) {
        var followers =
          $("#sidebar .followers[data-entry-type=" + entryType + "]");
        if (followers.size() > 0) {
          if (data.user_id) {
            var element = followers.
              find("[data-user-id=" + data.user_id + "]");
            element.fadeOut("slow", function () { element.remove(); });
          }
          if (data.followers_count) {
            var countContainer = followers.find(".count");
            var newCount = $(data.followers_count);
            if (newCount.attr("data-count") == "0") {
              // Topic has no followers now
              countContainer.remove();
            } else {
              countContainer.html(newCount);
            }
          }
        }
        Utils.toggleFollowLink(link);

        // On unfollow, if email subscription is enabled, should be disabled.
        var subscriptionLink = $("#toggle_email_subscription_link");
        if (subscriptionLink.attr("status-switch") == "on") {
          Utils.toggleEmailSubscriptionLink(subscriptionLink);
        }
        // Toggle email subscription option's visibility
        $("#email-subscription").addClass('hidden');
      },

      error: function (data) {
        if (data.status == "unauthenticate") {
          Utils.redirectToSignIn();
        }
      }
    };
  });

});
