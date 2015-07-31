<div class="row">
	<script>
		$(document).ready(function() {
			require(['admin/settings'], function(settings) {
				settings.prepare();
			});
		});
	</script>
	<div class="col-lg-9">
		<div class="panel panel-default">
			<div class="panel-body">
				<form class="form-horizontal" id="int-steam-cpl-form">
					<fieldset>
						<!-- Form Name -->
						<legend>Steam Integration Control Panel</legend>
						<!-- Text input-->
						<div class="form-group">
							<label class="col-md-4 control-label" for="int-steam-web-key">Steam Web API Key</label>
							<div class="col-md-8">
								<input id="int-steam-web-key" data-field="int-steam-webKey" type="text" placeholder="Entry your Steam Web API Key here" class="form-control input-md" required="">
								<span class="help-block">You can get one by filling this <a target="_blank" href="http://steamcommunity.com/dev/apikey">form</a></span>
							</div>
						</div>
						<!-- Multiple Checkboxes -->
						<div class="form-group">
							<label class="col-md-4 control-label" for="int-steam-settings">Login &amp; Registration</label>
							<div class="col-md-4">
								<div class="checkbox">
									<label for="int-steam-settings-0">
										<input type="checkbox" data-field="int-steam-allowLogin" id="int-steam-settings-0">
										Allow login via steam
									</label>
								</div>
								<div class="checkbox">
									<label for="int-steam-settings-1">
										<input type="checkbox" data-field="int-steam-overrideAvatar" id="int-steam-settings-1">
										Upload avatar from steam even if custom avatars are disabled
									</label>
								</div>
							</div>
						</div>
					</fieldset>
				</form>
			</div>
		</div>
	</div>
	<div class="col-lg-3">
		<div class="panel panel-default">
			<div class="panel-heading">Actions</div>
			<div class="panel-body">
				<button class="btn btn-primary btn-md" id="save">Save Changes</button>
				<button class="btn btn-warning btn-md" id="revert">Revert Changes</button>
			</div>
		</div>
	</div>
</div>