(function ($) {

function shorten_request() {
  var params = {
    url: $('#long_url').val()
  }

  $.ajax({
    type: 'POST',
    url: '/shorten',
    contentType: 'application/json; charset=utf-8',
    data: JSON.stringify(params),
    dataType: 'json',
    processData: false,
    success: function (data) {
      if (data.success) {
        $('#short_url').val(data.short);
      }
      else {
        alert("Operation failed!");
      }
    },
    error: function() {
      alert('Operation error. Please try again later.');
    },
  });
}

$(document).ready(function() {
  $('#shorten_smt').click(function() {
    try {
      shorten_request();
    } finally {
      /* Prevent browser to send POST request, since we already did it */
       return false;
    }
  });

  $(':text').each(function() {
    if ($(this).val()) {
      return;
    }
    else {
      $(this).val($(this).attr('title'));
      $('#shorten_smt').attr('disabled', true);
    }
  });

  $(':text').focus(function() {
    if ($(this).val() == $(this).attr('title')) {
      $(this).val('');
      $('#shorten_smt').attr('disabled', false);
    }
  }).blur(function() {
    if ($(this).val() == '') {
      $(this).val($(this).attr('title'));
      $('#shorten_smt').attr('disabled', true);
    }
  });
});

})(jQuery)