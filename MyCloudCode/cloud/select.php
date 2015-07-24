<?php

require 'parse-php-sdk-master/autoload.php';
use Parse\ParseObject; // for sure
use Parse\ParseQuery; // for sure
use Parse\ParsePush;
use Parse\ParseUser;
use Parse\ParseException;
use Parse\ParseCloud;
use Parse\ParseClient;

$app_id = "qaxPUYOQKh2qoynbAJpC41UWEU3AHJCLZCI2TJ9t";
$master_key = "p7INvQ03y55rHQucjzx4dc9jNgdW4HdNMRBu5dnJ";
$rest_key = "HhbpsJAcdVhMy2Q5i8l1rs59QikGAKb7wjv9Q7UR";
ParseClient::initialize( $app_id, $rest_key, $master_key );

$enableWrite = 1; // flip this bit to enable changing the user's UserInquiry object
$user = null;
$userInquiryObj = null;
$userObjectId = null;
$message = "";
$subMessage = "";

if ( isset($_GET['user_session']) ){

	// -------
	// USER - become the session user
	// -------
	$user_session = $_GET['user_session'];
	try {
		$user = ParseUser::become($user_session);
		$userObjectId = $user->getObjectId();
	} catch (ParseException $ex) {
		$message = "Error";
		$subMessage = "Try logging out and logging back in.";
	}
	
	if ( $user ){
	
		// -------
		// QUERY for the user's stored UserInquiry, create one if there isn't one.
		// -------
		$userInquiryObj = null;
		$query = new ParseQuery("UserInquiry");
		$query->equalTo("user", $userObjectId);
		$query->limit(1);
		$userInquiry = $query->find();
		if ( count($userInquiry) == 0 ){
			$userInquiryObj = new ParseObject("UserInquiry");
			$userInquiryObj->set("user", $userObjectId);
			try {
				$userInquiryObj->save();
			} catch (ParseException $ex2) {  
				// Execute any logic that should take place if the save fails.
				// error is a ParseException object with an error code and message.
				echo $ex2->getMessage();
			}
		}
		try {
			$userInquiry = $query->find();
			$userInquiryObj = $userInquiry[0];
		
			// parse out existing info here.
			if ( isset($userInquiryObj) ){
				$userInquiryObjectCriteria = $userInquiryObj->get("InquiryParameters");
				$existingCriteria = explode("|", $userInquiryObjectCriteria);
				for ($i=0; $i < count($existingCriteria); $i++){
					$c = $existingCriteria[$i];
					if ( strstr($c,"price:") !== false ){
						$numberArray = explode("-",explode(":",$c)[1]);
						$price_min = $numberArray[0];
						$price_max = $numberArray[1];
						
					} else if ( strstr($c,"beds:") !== false ){
						$beds = substr($c, -1);
						
					} else if ( strstr($c,"area:") !== false ){
						$areas = explode(",",explode(":", $c)[1]);
						
					} else if ( strstr($c,"amenities:") !== false ){
						$amenities = explode(",", explode(":", $c)[1]);
						
					}
				}
			}					
		
		} catch (ParseException $ex) {
			echo "failed to find obj";
		}
		//echo "<!-- sucesfully retrieved " . $userInquiryObj->get('InquiryParameters') . ' -->';
		
	}
	// --
	
}

if ( $_POST && $_POST['priceLow'] ){
	
	// -----
	// PARSE THE FORM
	// -----
	$price_min = $_POST['priceLow'];
	$price_max = $_POST['priceHigh'];
	$replaceArray = array("$",".00");
	$withArray = array("","");
	$price_min = str_replace($replaceArray,$withArray,$price_min);
	$price_max = str_replace($replaceArray,$withArray,$price_max);
	
	$beds = "";
	if( $_POST['beds'] ) {
		$beds = $_POST['beds'];
	}	 

	$area = "";
	if( $_POST['area'] ) {
		foreach ($_POST['area'] as $selectedOption){
			if ( $area == "" ){
				$area = $selectedOption;
			} else {
				$area = $area . "," . $selectedOption;
			}
		}
	}	 

	$amenities = "";
	if( $_POST['amenities'] ) {
		foreach ($_POST['amenities'] as $currentOption){
			if ( $amenities == "" ){
				$amenities = $currentOption;
			} else {
				$amenities = $amenities . "," . $currentOption;
			}
		}
		//	echo "<!-- amenities[]: " . $amenities . " -->"; // to validate
	}
	// --

	if ( isset($user) ){

		// Build the new inquiryParameter String for the user
		$inquiryParameterString = "criteria=rental_type:frbo,brokernofee,brokerfee|";
		$inquiryParameterString = $inquiryParameterString . "price:" . $price_min . "-" . $price_max . "|";
		if ( $area != "" ){
			$inquiryParameterString = $inquiryParameterString . "area:" . $area . "|";
		}
		if ( $beds != "" ){
			$inquiryParameterString = $inquiryParameterString . "beds:" . $beds . "|";
		}
		if ( $amenities != "" ){
			$inquiryParameterString = $inquiryParameterString . "amenities:" . $amenities;	
		}
		// echo '<!-- ready to write new prefs - ' . $inquiryParameterString . ' -->';
		
		// Actually go ahead and set the new preferences	
		if ( $enableWrite == 1 ){
			$userInquiryObj->set('InquiryParameters', $inquiryParameterString);
			$userInquiryObj->set("enabled", true);
			try {
				$userInquiryObj->save();
				$message = "Updated!";
				$subMessage = "You will now recieve apartment listings the minute they are listed directly to your phone.";
			} catch (ParseException $ex) {  
				// Execute any logic that should take place if the save fails.
				// error is a ParseException object with an error code and message.
				$message = 'Oops, something went wrong. <!-- ' . $ex->getMessage() . ' -->';
			}
		}
	
	}
	
}
// -- fyi last session - r:bXVHgUKj25SHwK62plqUICSM3.


?><!DOCTYPE html>
<html class="no-js">
	<head>
		<meta charset="utf-8">
		<meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
		<title></title>
		<meta name="description" content="">
		<meta name="viewport" content="width=device-width">
		<link rel="stylesheet" href="css2/normalize.css">
		<link rel="stylesheet" href="css2/foundation.min.css">

	</head>
	<body>
		<?
		if ( $message != "" ){
			echo '<div class="row" style="margin-top: 10px;"><div class="panel callout radius">';
			  echo '<h5>'.$message.'</h5>';
			  if ( $subMessage != "" ){
				  echo '<p>'.$subMessage.'</p>';
			  }
			echo '</div></div>';
		}
		?>
		<form id="mainForm" action="" method="post">
			<div class="row">
				<div class="large-6 columns">
					<label>Price</label>
					<div class="row collapse prefix-radius">
						<div class="small-3 columns">
					    	<span class="prefix">Min ($)</span>
					    </div>
					    <div class="small-9 columns">
					        <input type="text" name="priceLow" pattern="[0-9]*" id="priceLow" <? 
								if ( isset($price_min) ){
									echo 'value="'.$price_min.'"';
								} else { 
									echo 'placeholder="$"'; 
								}
							?> required>
						</div>
					</div>
				</div>
				<div class="large-6 columns">
					<label>&nbsp;</label>
					<div class="row collapse postfix-radius">
					    <div class="small-9 columns">
					        <input type="text" name="priceHigh" pattern="[0-9]*" id="priceHigh" <? 
								if ( isset($price_max) ){
									echo 'value="'.$price_max.'"';
								} else { 
									echo 'placeholder="$"'; 
								}
							?> required>
						</div>
						<div class="small-3 columns">
					    	<span class="postfix">Max ($)</span>
					    </div>
					</div>
				</div>
			</div>

			<div class="row">
				<div class="large-12 columns">
					<label for="beds">Bedrooms
						<select id="beds" name="beds"><?
							
							$bedOptions = array("Studio", "1 Bedroom", "2 Bedroom", "3 Bedroom", "4 Bedroom");
							$bedOptionValues = array("0","1","2","3","4");
							
							for ($i = 0; $i < count($bedOptions); $i++) {
								echo '<option';
								if ( $beds == $i ){
									echo ' selected';
								}
								echo ' value="' . $bedOptionValues[$i] . '">' . $bedOptions[$i] . '</option>';
							}
							
						?></select>
					</label>
				</div>
			</div>
			
			<div class="row">
				<div class="large-12 columns">
					<label for="area">Neighborhoods
						<select multiple id="area" name="area[]"><?
							
							$areaOptions = array(	"- Downtown -",
													"Battery Park",
													"Chelsea",
													"West Chelsea",
													"Chinatown",
													"Two Bridges",
													"Civic Center",
													"East Village",
													"Financial District",
													"Fulton / Seaport",
													"Flatiron",
													"Gramercy",
													"Greenwhich Village",
													"Little Italy",
													"Lower East Side",
													"Noho",
													"NoMad",
													"NoLita",
													"Soho",
													"Stuy-town",
													"Tribeca",
													"West Village",
													"",
													"- Brooklyn -",
													"Boerum Hill",
													"Brooklyn Heights",
													"Caroll Gardens",
													"Clinton Hill",
													"Cobble Hill",
													"Crown Heights",
													"Dumbo",
													"Downtown Brooklyn",
													"Fort Greene",
													"Park Slope",
													"Prospect Heights",
													"Red Hook",
													"Williamsburg",
													"",
													"- Queens -",
													"Astoria",
													"Bayside",
													"Forest Hills",
													"Little Neck",
													"Long Island City",
													"Woodside"
												);
							$areaIds = array(
								102,
								112,
								103,
								163,
								110,
								111,
								103,
								117,
								104,
								114,
								158,
								113,
								116,
								108,
								109,
								118,
								159,
								162,
								107,
								106,
								105,
								157,
								"",
								300,
								306,
								305,
								321,
								364,
								322,
								325,
								307,
								303,
								304,
								319,
								326,
								318,
								302,
								"",
								400,
								401,
								428,
								415,
								430,
								402,
								404
							);
							
							for ($i = 0; $i < count($areaOptions); $i++) {
								$thisAreaId = $areaIds[$i];
								$thisAreaName = $areaOptions[$i];
								echo '<option';
								if ( is_string($areas) ){
									$areas = explode(",",$areas);
								}
								if ( in_array($thisAreaId, $areas) === true ){
									echo ' selected';
								}
								echo ' value="' . $thisAreaId . '">' . $thisAreaName . '</option>';
							}
							
						?>
						</select>
					</label>
				</div>
			</div>
			
			<div class="row">
				<div class="large-12 columns">
					<label for="area">Amenities
						<select multiple name="amenities[]" id="amenities"><?
							$amenityOptions = array("Doorman", "Dishwasher", "Elevator", "Gym", "Laundry In Bldg", "Washer/Dryer");
							$amenityIds = array("doorman", "dishwasher", "elevator", "gym", "laundry", "washer_dryer");
							for ($i = 0; $i < count($amenityOptions); $i++) {
								echo '<option';
								if ( is_string($amenities) ){
									$amenities = explode(",", $amenities);
								}
								if ( isset($amenities) && in_array($amenityIds[$i], $amenities) ){
									echo ' selected';
								}
								echo ' value="' . $amenityIds[$i] . '">' . $amenityOptions[$i] . '</option>';
							}
							
						?>
						</select>
					</label>
				</div>
			</div>

			<div class="row" style="text-align:center;">
				<a role="button" aria-label="submit form" href="#" class="button" onclick="document.getElementById('mainForm').submit();return false;">Save</a>
			</div>
			
		</form>
		
		<script src="http://www.parsecdn.com/js/parse-1.2.12.min.js"></script>
		<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1/jquery.min.js"></script>
	
	</body>
</html>