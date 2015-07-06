// globals
var _SE_BASE 	= 	"http://streeteasy.com/nyc/api/rentals/search";
var _SE_PARAMS 	= 	{
	criteria: "&criteria=rental_type:frbo,brokernofee,brokerfee|price:1750-2152|area:115,158,116,108,162,107,157,306,322,323,305|beds:=1|sort_by:listed_desc|",
	limit: 50,
	format: "json",
	key: "0523e568930021b573ca6e1e1089327b61ad56e9"
}
var _USER_EXISTING_LISTINGS = [];
var _USER_DESTROY_LISTINGS = [];
var _SAVE_OBJS = [];
var LISTINGS_VALID_TTL = 604800000;
// testing data (overridden when the function is called via the job)
var userId = "mattrestivo";
var inquiryId = "JGn1ubwaff";

// helpers
var indexOf=function(n){return indexOf="function"==typeof Array.prototype.indexOf?Array.prototype.indexOf:function(n){var r=-1,t=-1;for(r=0;r<this.length;r++)if(this[r]===n){t=r;break}return t},indexOf.call(this,n)};
var _ = require('underscore.js');
var Mailgun = require('mailgun');
Mailgun.initialize('mg.mattrestivo.com', 'key-ef6f2ffb1718bfeb99f84a0dbb6b71e6');

// main function, fetch listings for specified user and criteria
var fetchListingsForUserQuery = function(request, response){

	var saveObjects = [];
	var promise = new Parse.Promise();
	
	// change the parameters here based on userInquiry
	if ( request ){
		if ( request.criteria ){
			_SE_PARAMS.criteria = request.criteria;
		}
		if ( request.userId ){
			userId = request.userId;
		}
		if ( request.inquiryId ){
			inquiryId = request.inquiryId;
		}
	}
	
	console.log('>> fetchListingsForUserQuery >>>');
	console.log(userId + ', ' + inquiryId);
	
	// first let's figure out what listings the user has already seen
	var query = new Parse.Query("UserInquiryListing");
	query.equalTo("userId", userId);
	query.limit(1000);
	query.find().then(function(results){
			
			if (results.length > 0){
				_USER_EXISTING_LISTINGS = [];
				_USER_DESTROY_LISTINGS = [];
				for ( var i=0; i<results.length; i++){
					if ( results[i] ){
						obj = results[i];
						tempListingId = obj.get("listingId");
						
						now = new Date();
						diff = new Date(obj.get('created'));
						diff = now - diff;
						if ( diff > LISTINGS_VALID_TTL ){
							//console.log('found a listing that falls outside the window we want');
							_USER_DESTROY_LISTINGS[_USER_DESTROY_LISTINGS.length] = obj;
						}
						
						_USER_EXISTING_LISTINGS[_USER_EXISTING_LISTINGS.length] = tempListingId;
					}
				}
				//console.log('ok, temp stored all of user listings');
			}                 
			else    
			{                 
				//console.log('note this user does not yet have any listings stored');
			}
			return Parse.Promise.as();
		}
		
	// with this list, now let's get the new listings.
	).then(
		function(){
			var promise = Parse.Promise.as();
			_.each(_USER_DESTROY_LISTINGS, function(obj) {
				// For each item, extend the promise with a function to delete it.
				promise = promise.then(function() {
					// Return a promise that will be resolved when the delete is finished.
					console.log('destroying ->');
					console.log(obj);
					return obj.destroy();
				});
			});
			return promise;
		}
	).then(
		function(){
			//console.log('making http request');
			return Parse.Cloud.httpRequest({
				url: _SE_BASE,
				params: _SE_PARAMS,
				method: "GET"
			});
			
		}
	// we finally sorted this out, now let's save
	).then(
		function(httpResponse){
			//console.log('into http success handler');
			jResponse = JSON.parse(httpResponse.text);
			
			if ( jResponse ){
				// we can easily exclude records we already got, and write them to parse
				if ( jResponse.listings ){
					listingsArray = jResponse.listings;
					if ( listingsArray.length > 0 ){
						_SAVE_OBJS = [];
						for (var i=0; i<listingsArray.length; i++){
							if ( listingsArray[i] ){
								obj = listingsArray[i];
								now = new Date();
								diff = new Date(obj.created_at);
								diff = now - diff;
								if ( indexOf.call(_USER_EXISTING_LISTINGS, obj.id+"") == -1 && diff < LISTINGS_VALID_TTL ){ 
									var newListing = new Parse.Object("UserInquiryListing");			
										listingId = obj.id+'';
										listingPrice = obj.price+'';
										listingTitle = obj.clean_title;
										listingUrl = obj.url+'';
										listingCreated = obj.created_at;
										
										newListing.set("title", listingTitle);
										newListing.set("price", listingPrice);
										newListing.set("userId", userId);
										newListing.set("listingId", listingId);
										newListing.set("inquiryId", inquiryId);
										newListing.set("url", listingUrl);
										newListing.set("created", listingCreated);
										
										_SAVE_OBJS[_SAVE_OBJS.length] = newListing;

								} else {
									//console.log('found a duplicate listing: ' + obj.id);
								}
							}
						}
							
						console.log('saving ' + _SAVE_OBJS.length + ' new listings for user.');
						return Parse.Object.saveAll(_SAVE_OBJS);
						
					}						
				}
			}
			
		}).then(
			function(savedObjects){
				
				var notificationPromise = new Parse.Promise();
				
				// extract email building @todo
				subject = "";
				text = "";
				
				if ( savedObjects.length > 0 ){
					
					if ( savedObjects.length > 1 ){
						subject = savedObjects.length + " New Listings!";
						for ( var k=0; k<savedObjects.length; k++){
							obj = savedObjects[k];
							text = text + "$" + obj.get("price") + " <a href='" + obj.get("url") + "'>" + obj.get("title") + "</a><br/>";
						}
					} else {
						obj = savedObjects[0];
						subject = "New: $" + obj.get("price") + " " + obj.get("title");
						text = "$" + obj.get("price") + " <a href='" + obj.get("url") + "'>" + obj.get("title") + "</a>";
					}
		
					// get user email
					var query = new Parse.Query("User");
					query.equalTo("userId", userId);
					query.find().then(function(results){
					
						if ( results && results.length == 1 ){
							userObj = results[0];
							if ( userObj ){
								// extract this into a function!! @todo
								email = userObj.get("email");
								isEnabled = userObj.get("enabled");
								if ( email && isEnabled ){
									Mailgun.sendEmail({
										to: email,
										from: "maillist@mattrestivo.com",
										subject: subject,
										html: text
									}, {
										success: function(httpResponse) {
											//console.log(httpResponse);
											notificationPromise.resolve(savedObjects);
										},
										error: function(httpResponse) {
											//console.error(httpResponse);
											notificationPromise.reject(httpResponse);
										}
									});
								} else {
									notificationPromise.resolve(savedObjects); // move along, no valid email
								}
							}
						} else {
							notificationPromise.resolve(savedObjects); // move along, no user registered.
						}
					});
					
				} else {
					notificationPromise.resolve(savedObjects); // move along, nothing to save here.
				}
				
				return notificationPromise;
				
			}
		).then(
			function(savedObjects){
				
				console.log('<<< fetchListingsForUserQuery complete <<');
				//response.success(a);
				promise.resolve(savedObjects);
			
			}, function(error) {

				console.log('<<< fetchListingsForUserQuery errored <<');
				console.log(error);
				//response.error(error);
				promise.reject(error);

			}
		);
	
	return promise;	// note that we get here immediately when the function is called.
	
};

// fetchApartmentsForQuery. 
Parse.Cloud.define("fetchListingsForUserQuery", function(request, response){
	return fetchListingsForUserQuery(request,response);
});

// setup job to run that finds listings for all queries
Parse.Cloud.job("fetchListingsForAllUsers", function(request, status) {
  // Set up to modify user data
  var counter = 0;
  console.log('*********************');
  console.log('STARTING FETCH JOB');
  console.log('*********************');
  
  // Query for all inquiries
  var query = new Parse.Query("UserInquiry");
  
  query.find().then(function(results){
  	
	  var promise = Parse.Promise.as();
	  _.each(results, function(result){
		  promise = promise.then(function(){
			  r = {};
			  enabled = false; // true;// = false;
			  if ( result ){
				  r.userId = result.get("userId");
				  r.criteria = result.get("InquiryParameters");
				  r.inquiryId = result.id;
				  enabled = result.get("enabled");
			  }
			  if ( enabled ){
				  return fetchListingsForUserQuery(r,null);
			  } else {
				  return promise.resolve();
			  }
		  });
	  });
	  
	  return promise;
	
  }).then(function(request) {
	
	console.log('*********************');
	console.log('COMPLETED FETCH JOB');
	console.log('*********************');
    status.success("Successfully looped through all users, and called listing fetch");
	
  }, function(error) {
    // Set the job's error status
	console.log('*********************');
	console.log('FETCH JOB ERRORED');
	console.log('*********************');
    status.error("Uh oh, something went wrong with the query.");
  });
  
});