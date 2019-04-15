$(document).ready(function() {

    $('.action-delete').click(function(element) {
        $.ajax({
            type: 'DELETE',
            url: element.target,
            contentType: 'text/html',
        }).done(function(data, status, jqxhr) {
            $('body').html(data);
        }).fail(function(jqxhr, status, error) {
            $('body').html(jqxhr.responseText);
        });
    });

    $('.action-update').click(function(element) {
        $.ajax({
            type: 'POST',
            url: element.target,
            contentType: 'application/x-www-form-urlencoded',
            data: { action: 'update' }
        }).done(function(data, status, jqxhr) {
            $('body').html(data);
        }).fail(function(jqxhr, status, error) {
            $('body').html(jqxhr.responseText);
        });
    });

});

