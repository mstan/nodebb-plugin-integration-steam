(function(module) {
	"use strict";

	var winston = require('winston'),
		meta = module.parent.require('./meta'),
		passport = require('passport'),
		SteamStrategy = require('passport-steam').Strategy,
		nconf = module.parent.require('nconf'),
		db = module.parent.require('./database'),
		user = module.parent.require('./user'),
		plugins = module.parent.require('./plugins'),
		controllers = module.parent.require('./controllers'),
		async = require('async');

	module.exports.extendAuth = function(strategies, next) {
		meta.configs.getFields(['int-steam-webKey', 'int-steam-allowLogin'], function(err, data) {
			if (data) {
				if (data['int-steam-webKey'] && data['int-steam-webKey'].length > 0 && data['int-steam-allowLogin'] === '1') {
					passport.use(new SteamStrategy({
							returnURL: nconf.get('url') + '/auth/steam/return',
							realm: nconf.get('url'),
							apiKey: data['int-steam-webKey'],
							passReqToCallback: true
						},
						function(req, identifier, profile, done) {
							db.getObjectField('int-steamid:uid', profile.id, function(err, uid) {
								if (err !== null || uid === null) {
									// No user yet. Add data to cache
									req.session.authSteam = {
										identifier: identifier,
										profile: profile
									};
									// Return fail, we'll use this data later in failureUrl root controller
									return done(null);
								}
								// We have id, no need to show fill form, proceed to default login
								done(null, { uid: uid });
							});
						}
					));
					strategies.push({
						name: 'steam',
						url: '/auth/steam',
						callbackURL: '/auth/steam/return',
						icon: 'steam-auth-button',
						scope: 'user:username',
						failureUrl: '/login-steam' // We only need failure url, it'll indicate there is no such steam user in db
					});
				}
			}
			next(null);
		});
	}

	// Remove information when deleting user
	module.exports.cleanup = function(uid, next) {
		db.getObjectField('int-uid:steamid', uid, function(err, steamId) {
			if (err !== null || steamId === null) {
				winston.error("Cleanup halted. Cannot find int-uid:steamid value for uid: " + uid);
			} else {
				db.deleteObjectField('int-steamid:uid', steamId);
				db.deleteObjectField('int-uid:steamid', uid);
			}
		});
	}

 	// From /routes/helpers.js
	function setUpPageRoute(router, name, middleware, middlewares, controller) {
		middlewares = middlewares.concat([middleware.pageView]);
		router.get(name, middleware.buildHeader, middlewares, controller);
		router.post(name, middleware.buildHeader, middlewares, controller);
		router.get('/api' + name, middlewares, controller);
	};

	// POST handler (create new user & login it)
	function steamCreateNewUser(req, res, next) {
		async.waterfall([
			function(next) { // Get settings
				meta.configs.getFields(['int-steam-overrideAvatar', 'int-steam-allowLogin', 'allowProfileImageUploads', 'registrationType'], next);
			},
			function(data, next) {
				if (data.registrationType === 'disabled' || data.registrationType === 'invite-only') {
					next("Wrong registration type", data.registrationType);
				} else next(null, data);
			},
			function(data, next) { // Get cache
				if (req.session.authSteam === undefined) {
					next("No data cached for this sessionID");
				} else {
					data.cache = req.session.authSteam;
					next(null, data);
				}
			},
			function(data, next) { // Create user
				if (req.body['reg-email'] && req.body['reg-username']) {
					user.create({
						username: req.body['reg-username'],
						email: req.body['reg-email']
					}, function(err, uid) {
						data.uid = uid;
						next(err, data);
					});
				} else next("Parameters are not valid");
			},
			function(data, next) { // Steam linking
				// Steam linking
				user.setUserField(data.uid, 'int-steam-id', data.cache.profile.id);
	            user.setUserField(data.uid, 'int-steam-url', data.cache.profile._json.profileurl);
	            // Not sure if there is no other way, but we need double-link between steam id and user id
	            db.setObjectField('int-steamid:uid', data.cache.profile.id, data.uid);
            	db.setObjectField('int-uid:steamid', data.uid, data.cache.profile.id);

            	next(null, data);
			},
			function(data, next) { // Override allowProfileImageUploads setting if needed
				if (data.allowProfileImageUploads !== '1' && data['int-steam-overrideAvatar'] === '1') {
					data.allowProfileImageUploadsOld = data.allowProfileImageUploads;
					meta.configs.set('allowProfileImageUploads', '1', function(err) {
						next(err, data);
					})
				} else next(null, data);
			},
			function(data, next) { // Upload avatar from steam
				user.uploadFromUrl(data.uid, data.cache.profile._json.avatarfull, function(err, image) {
		    		if (err !== null) { // This error is not critical
		    			winston.warn("Cannot load avatar for uid " + data.uid, err);
		    		}
		    		next(null, data);
		    	});
			},
			function(data, next) { // Restore allowProfileImageUploads setting
				if (data.allowProfileImageUploadsOld !== undefined) {
					meta.configs.set('allowProfileImageUploads', data.allowProfileImageUploadsOld, function(err) {
						next(err, data);
					});
				} else next(null, data);
			},
			function(data, next) { // Login
				if (data['int-steam-allowLogin'] === '1') {
					req.login({ uid: data.uid }, function() {
		    			next(null, data);
		    		});
				} else next(null, data);
			},
			function(data, next) { // Cleanup
				delete req.session.authSteam;
				next(null, data);
			}
		], function(err, data) { // Render
			if (err !== null) {
				winston.error("[SteamCreateNewUser]", err);
				return res.status(400).send('[[steamint:register_error]]')
			} else {
				return res.json({ referrer: nconf.get('url') + '/' });
			}
		});
	};

	function steamLoginController(req, res, next) {
		if (req.session.authSteam && req.body.action === 'register') { // Register new user after steam auth
			steamCreateNewUser(req, res, next);
		} else if (req.session.authSteam && req.body.action === 'login') { // Login to existing user after steam auth
			if (req.session.authSteam !== undefined) {
				req.session.authSteam.isLoggingIn = true;
				req.session.returnTo = nconf.get('url') + "/login-steam";
				controllers.authentication.login(req, res, function() { });
			}
		} else if (req.session.authSteam && req.session.authSteam.isLoggingIn) { // Successfully logged into existing account
			var uid = req.session.passport.user;
			// Steam linking
			user.setUserField(uid, 'int-steam-id', req.session.authSteam.profile.id);
            user.setUserField(uid, 'int-steam-url', req.session.authSteam.profile._json.profileurl);
            // Not sure if there is no other way, but we need double-link between steam id and user id
            db.setObjectField('int-steamid:uid', req.session.authSteam.profile.id, uid);
        	db.setObjectField('int-uid:steamid', uid, req.session.authSteam.profile.id);
        	// Cleanup
        	delete req.session.authSteam;
        	return res.redirect(nconf.get('url'));
		} else {
			async.waterfall([
				function(next) {
					meta.configs.getFields(['registrationType', 'allowLocalLogin', 'allowLoginWith', 'termsOfUse', 'minimumUsernameLength', 'maximumUsernameLength'], next);
				},
				function(data, next) { // Registration & login configs
					data.allowRegistration = data.registrationType === 'normal' || data.registrationType === 'admin-approval';
					data.allowLocalLogin = parseInt(data.allowLocalLogin, 10) === 1 || parseInt(req.query.local, 10) === 1;
					data.allowLoginWith = '[[login:' + (data.allowLoginWith || 'username-email') + ']]';
					next(null, data);
				},
				function(data, next) { // Cache
					if (req.session.authSteam) {
						data.displayName = req.session.authSteam.profile.displayName;
						data.avatarfull = req.session.authSteam.profile._json.avatarfull;
						next(null, data);
					} else {
						data.error = "[[error:int-steam-unexpected-error]]";
						next("Sesssion ID not found in cache", data);
					}
				},
				function(data, next) { // Regform entries
					// data.regFormEntry = [];
					//plugins.fireHook('filter:register.build', {req: req, res: res, templateData: data}, next);
					next(null, data);
				}
			], function(err, data) {
				if (err !== null) {
					winston.warn('[SteamLoginController]', err);
				}
				
				return res.render('integration-steam/login-steam', data);
			});
		}
	};

	function adminPanelController(req, res, next) {
		res.render('integration-steam/admin-steam', { });
	}

	module.exports.load = function(app, next) {
		// Bind failureUrl so we can show fill form
		setUpPageRoute(app.router, '/login-steam', app.middleware, [ ], steamLoginController);
		// Bind admin panel url
		app.router.get('/admin/plugins/integration-steam', app.middleware.admin.buildHeader, adminPanelController);
		app.router.get('/api/admin/plugins/integration-steam', adminPanelController);
		next(null);
	};

	module.exports.extendAdminMenu = function(header, next) {
		header.plugins.push({
			"route": '/plugins/integration-steam',
			"icon": 'fa-steam',
			"name": 'Steam'
		});
		next(null, header);
	};

	// Show additional fields in the user profile
	module.exports.extendUserAccount = function(data, next) {
		next(null, data);
	};
}(module));