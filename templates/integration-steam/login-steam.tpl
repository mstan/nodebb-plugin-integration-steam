<div class="row">
	<script>
	$(document).ready(function() {
		$('.panel-heading a').on('click',function(e){
		    if($(this).parents('.panel').children('.panel-collapse').hasClass('in')){
		        e.preventDefault();
		        e.stopPropagation();
		    }
		});

		require(['csrf', 'translator'], function(csrf, translator) {

			// From client/register.js
			var email = $('#reg-email'),
				username = $('#reg-username'),

				login = $('#login-email'),
				password = $('#login-password'),

				register = $('#continue'),

				agreeTerms = $('#agree-terms'),
				successIcon = '<i class="fa fa-check"></i>',
				validationError = false;

			$('#referrer').val(app.previousUrl);

			email.on('blur', function() {
				if (email.val().length) {
					validateEmail(email.val());
				}
			});

			// Update the "others can mention you via" text
			username.on('keyup', function() {
				$('#yourUsername').text(this.value.length > 0 ? utils.slugify(this.value) : 'username');
			});

			username.on('blur', function() {
				if (username.val().length) {
					validateUsername(username.val());
				}
			});

			// Check first time
			if (username.val().length) {
				validateUsername(username.val());
			}

			function validateForm(callback) {
				validationError = false;
				validateEmail(email.val(), function() {
					validateUsername(username.val(), callback);
				});
			}

			$('#form-register').submit(function(e) {
				e.preventDefault();
				submitForm($('#form-register'));
			});

			$('#form-login').submit(function(e) {
				e.preventDefault();
				submitForm($('#form-login'));
			});

			function submitForm(form) {
				form.ajaxSubmit({
					headers: {
						'x-csrf-token': csrf.get()
					},
					success: function(data, status) {
						console.log(data);
						register.removeClass('disabled');
						if (!data) {
							return;
						}
						if (data.referrer) {
							window.location.href = data.referrer;
						} else if (data.message) {
							app.alert({message: data.message, timeout: 20000});
						} else {
							window.location.href = data;
						}
					},
					error: function(data, status) {
						console.log(data);
						var errorEl = $('#register-error-notify');
						if (data.responseText) {
							translator.translate(data.responseText, config.defaultLang, function(translated) {
								errorEl.find('p').text(translated);
								errorEl.show();
								register.removeClass('disabled');
							});
						} else if (data.message) {
							translator.translate(data.message, config.defaultLang, function(translated) {
								errorEl.find('p').text(translated);
								errorEl.show();
								register.removeClass('disabled');
							});
						}
					}
				});
			}

			register.on('click', function(e) {
				var registerBtn = $(this);
				e.preventDefault();
				var form = false;
				if ($('#area-register').attr('aria-expanded') === "true") {
					form = $('#form-register');
					validateForm(function() {
						if (!validationError) {
							registerBtn.addClass('disabled');
							submitForm(form);							
						}
					});
				} else {
					form = $('#form-login');
					registerBtn.addClass('disabled');
					submitForm(form);	
				}
			});

			if (agreeTerms.length) {
				agreeTerms.on('click', function() {
					if ($(this).prop('checked')) {
						register.removeAttr('disabled');
					} else {
						register.attr('disabled', 'disabled');
					}
				});

				register.attr('disabled', 'disabled');
			}

			function validateEmail(email, callback) {
				callback = callback || function() {};
				var email_notify = $('#email-notify');

				if (!utils.isEmailValid(email)) {
					showError(email_notify, '[[error:invalid-email]]');
					return callback();
				}

				socket.emit('user.emailExists', {
					email: email
				}, function(err, exists) {
					if (err) {
						app.alertError(err.message);
						return callback();
					}

					if (exists) {
						showError(email_notify, '[[error:email-taken]]');
					} else {
						showSuccess(email_notify, successIcon);
					}

					callback();
				});
			}

			function validateUsername(username, callback) {
				callback = callback || function() {};

				var username_notify = $('#username-notify');

				if (username.length < config.minimumUsernameLength) {
					showError(username_notify, '[[error:username-too-short]]');
				} else if (username.length > config.maximumUsernameLength) {
					showError(username_notify, '[[error:username-too-long]]');
				} else if (!utils.isUserNameValid(username) || !utils.slugify(username)) {
					showError(username_notify, '[[error:invalid-username]]');
				} else {
					socket.emit('user.exists', {
						username: username
					}, function(err, exists) {
						if(err) {
							return app.alertError(err.message);
						}

						if (exists) {
							showError(username_notify, '[[error:username-taken]]');
						} else {
							showSuccess(username_notify, successIcon);
						}

						callback();
					});
				}
			}

			function showError(element, msg) {
				translator.translate(msg, function(msg) {
					element.html(msg);
					element.parent()
						.removeClass('alert-success')
						.addClass('alert-danger');
					element.show();
				});
				validationError = true;
			}

			function showSuccess(element, msg) {
				translator.translate(msg, function(msg) {
					element.html(msg);
					element.parent()
						.removeClass('alert-danger')
						.addClass('alert-success');
					element.show();
				});
			}
		});
	});
	</script>
	<div class="{register_window:spansize}">
		<div class="well well-lg">
			<div class="row">
				<div class="alert alert-danger" id="register-error-notify" <!-- IF error -->style="display:block"<!-- ELSE -->style="display: none;"<!-- ENDIF error -->>
					<button type="button" class="close" data-dismiss="alert">&times;</button>
					<strong>[[error:registration-error]]</strong>
					<p>{error}</p>
				</div>
				<div class="alert alert-danger" id="register-error-notify" <!-- IF warn -->style="display:block"<!-- ELSE -->style="display: none;"<!-- ENDIF warn -->>
					<button type="button" class="close" data-dismiss="alert">&times;</button>
					<strong>[[error:registration-error]]</strong>
					<p>{warn}</p>
				</div>
			</div>
			<div class="row" <!-- IF error -->style="display:none"<!-- ELSE -->style="display: block;"<!-- ENDIF error -->>
				<div class="col-lg-12">
					<div class="panel-group" id="select-type">
						<div class="panel panel-default" <!-- IF allowRegistration -->style="display:block"<!-- ELSE -->style="display: none;"<!-- ENDIF allowRegistration -->>
							<div class="panel-heading">
								<a class="panel-title collapsed" data-toggle="collapse" data-parent="#select-type" href="#ints-register" id="area-register" aria-expanded="true">[[steamint:fill]]</a>
							</div>
							<div id="ints-register" class="panel-collapse collapse in">
								<div class="panel-body">
									<div class="col-md-8">
										<form class="form-horizontal" id="form-register" role="form" action="{config.relative_path}/login-steam" method="post">
											<div class="form-group">
												<label for="email" class="col-lg-2 control-label">[[register:email_address]]</label>
												<div class="col-lg-10">
													<div class="input-group">
														<input class="form-control" type="text" placeholder="[[register:email_address_placeholder]]" name="reg-email" id="reg-email" autocorrect="off" autocapitalize="off" />
														<span class="input-group-addon">
															<span id="email-notify"><i class="fa fa-circle-o"></i></span>
														</span>
													</div>
													<span class="help-block">[[register:help.email]]</span>
												</div>
											</div>
											<div class="form-group">
												<label for="username" class="col-lg-2 control-label">[[register:username]]</label>
												<div class="col-lg-10">
													<div class="input-group">
														<input class="form-control" type="text" placeholder="[[register:username_placeholder]]" name="reg-username" id="reg-username" autocorrect="off" autocapitalize="off" autocomplete="off" value="{displayName}" />
														<span class="input-group-addon">
															<span id="username-notify"><i class="fa fa-circle-o"></i></span>
														</span>
													</div>
													<span class="help-block">[[register:help.username_restrictions, {minimumUsernameLength}, {maximumUsernameLength}]]</span>
												</div>
											</div>
											<!-- BEGIN regFormEntry -->
											<div class="form-group">
												<label for="register-{regFormEntry.styleName}" class="col-lg-2 control-label">{regFormEntry.label}</label>
												<div id="register-{regFormEntry.styleName}" class="col-lg-10">
													{{regFormEntry.html}}
												</div>
											</div>
											<!-- END regFormEntry -->
											<!-- IF termsOfUse -->
											<div class="form-group">
												<label class="col-lg-2 control-label">&nbsp;</label>
												<div class="col-lg-10">
													<hr />
													<strong>[[register:terms_of_use]]</strong>
													<textarea readonly class="form-control" rows=6>{termsOfUse}</textarea>
													<div class="checkbox">
														<label>
															<input type="checkbox" name="agree-terms" id="agree-terms"> [[register:agree_to_terms_of_use]]
														</label>
													</div>
												</div>
											</div>
											<!-- ENDIF termsOfUse -->
											<input type="hidden" name="action" value="register">
										</form>
									</div>
									<div class="col-md-2 col-md-offset-1" style="text-align: center; margin-bottom:20px;">
										<div class="account-picture-block text-center">
											<img id="user-current-picture" class="user-profile-picture img-thumbnail" src="{avatarfull}"><br>
											<span>[[steamint:avanote]]</span>
										</div>
									</div>
								</div>
							</div>
						</div>
						<div class="panel panel-default" <!-- IF allowLocalLogin -->style="display:block"<!-- ELSE -->style="display: none;"<!-- ENDIF allowLocalLogin -->>
							<div class="panel-heading">
								<a class="panel-title" data-toggle="collapse" data-parent="#select-type" href="#ints-login" id="area-login" aria-expanded="false">[[steamint:existing]]</a>
							</div>
							<div id="ints-login" class="panel-collapse collapse">
								<div class="panel-body">
									<form class="form-horizontal" id="form-login" role="form" action="{config.relative_path}/login-steam" method="post">
										<div class="form-group">
											<label for="email" class="col-lg-2 control-label">{allowLoginWith}</label>
											<div class="col-lg-10">
												<div class="input-group">
													<input class="form-control" type="text" placeholder="{allowLoginWith}" name="username" id="login-email" autocorrect="off" autocapitalize="off" />
													<span class="input-group-addon">
														<span id="email-notify"><i class="fa fa-circle-o"></i></span>
													</span>
												</div>
											</div>
										</div>
										<div class="form-group">
											<label for="username" class="col-lg-2 control-label">[[user:password]]</label>
											<div class="col-lg-10">
												<div class="input-group">
													<input class="form-control" type="password" placeholder="[[user:password]]" name="password" id="login-password" autocorrect="off" autocapitalize="off" autocomplete="off" />
													<span class="input-group-addon">
														<span id="username-notify"><i class="fa fa-circle-o"></i></span>
													</span>
												</div>
											</div>
										</div>
										<input type="hidden" name="action" value="login">
									</form>
								</div>
							</div>
						</div>
					</div>
					<div class="row">
						<div class="col-lg-4 col-lg-offset-4">
							<button class="btn btn-primary btn-lg btn-block" id="continue" type="submit">[[steamint:continue]]</button>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>
</div>