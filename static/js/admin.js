"use strict";

/* globals document, require, app, settings, socket */

$(document).ready(function() {
	require(['settings'], function(settings) {
		settings.load('integration-steam', $('#int-steam-cpl-form'), function(err, settings) {
			var defaults = {
				'int-steam-login': true,
				'int-steam-override-avatar': true
			};
			for(var setting in defaults) {
				if (!settings.hasOwnProperty(setting)) {
					if (typeof defaults[setting] === 'boolean') {
						$('#' + setting).prop('checked', defaults[setting]);
					} else {
						$('#' + setting).val(defaults[setting]);
					}
				}
			}
		});
	});
	$('#int-steam-save').on('click', function() {
		settings.save('integration-steam', $('#int-steam-cpl-form'), function() {
			app.alert({
				type: 'success',
				alert_id: 'int-steam-saved',
				title: 'Reload Required',
				message: 'Please reload your NodeBB to have your changes take effect',
				clickfn: function() {
					socket.emit('admin.reload');
				}
			})
		});
	});
});