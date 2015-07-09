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

$message = "";
$enableWrite = 1; // flip this bit to enable changing the user's UserInquiry object

	
if ( $_POST && isset($_GET['user_session']) ){
	
	// -----
	// PARSE FORM
	// -----
	$user_session = $_GET['user_session'];
	//echo "<!-- user_session: " . $user_session . " -->";
	
	$price_min = $_POST['priceLow'];
	$price_max = $_POST['priceHigh'];
	$replaceArray = array("$",".00");
	$withArray = array("","");
	$price_min = str_replace($replaceArray,$withArray,$price_min);
	$price_max = str_replace($replaceArray,$withArray,$price_max);
	
	$beds = "";
	if(isset($_POST['beds'])) {
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
	}
	//	echo "<!-- amenities[]: " . $amenities . " -->"; // to validate
	// --

	// -------
	// USER - become the session user
	// -------
	$user = null;
	try {
		$user = ParseUser::become($user_session);
	} catch (ParseException $ex) {
		$message = "There was an error authenticating you. Try logging out.";
	}
	
	
	// Retrieve the UserInquiry by User ID
	$userInquiryObj = null;
	if ( $user ){
		
		$query = new ParseQuery("UserInquiry");
		$userObjectId = $user->getObjectId();
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
		} catch (ParseException $ex) {
			echo "failed to find obj";
		}
		//echo "<!-- sucesfully retrieved " . $userInquiryObj->get('InquiryParameters') . ' -->';
		// --

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
		// --
	
		// Actually go ahead and set the new preferences	
		// echo '<!-- ready to write new prefs - ' . $inquiryParameterString . ' -->';
		if ( $enableWrite == 1 ){
			$userInquiryObj->set('InquiryParameters', $inquiryParameterString);
			$userInquiryObj->set("enabled", true);
			try {
				$userInquiryObj->save();
				$message = 'Successfully updated your preferences!';
			} catch (ParseException $ex) {  
				// Execute any logic that should take place if the save fails.
				// error is a ParseException object with an error code and message.
				$message = 'Oops, something went wrong. <!-- ' . $ex->getMessage() . ' -->';
			}
		}
}
	// --

}


?>

<!DOCTYPE html>
<html class="no-js">
	<head>
		<meta charset="utf-8">
		<meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
		<title></title>
		<meta name="description" content="">
		<meta name="viewport" content="width=device-width">
		<link rel="stylesheet" href="css/normalize.css">
		<link rel="stylesheet" href="css/foundation.min.css">
		<link rel="stylesheet" href="css/app.css">
	</head>
	<body>
		<?
		if ( $message != "" ){
			echo '<div class="row"><div class="panel callout radius">';
			  echo '<h5>'.$message.'</h5>';
			  //echo '<p>Its a little ostentatious, but useful for important content.</p>'
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
					        <input type="text" name="priceLow" id="priceLow" placeholder="$" required>
						</div>
					</div>
				</div>
				<div class="large-6 columns">
					<label>&nbsp;</label>
					<div class="row collapse postfix-radius">
					    <div class="small-9 columns">
					        <input type="text" name="priceHigh" id="priceHigh" placeholder="$" required>
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
						<select id="beds" name="beds">
							<option value="0">Studio</option>
							<option value="1">1 Bedroom</option>
							<option value="2">2 Bedroom</option>
							<option value="3">3 Bedroom</option>
							<option value="4">4 Bedroom</option>
						</select>
					</label>
				</div>
			</div>
			
			<div class="row">
				<div class="large-12 columns">
					<label for="area">Neighborhoods
						<select multiple id="area" name="area[]">
							<option value="102"><b>All Downtown</b></option>
							<option value="112">Battery Park City</option>
							<option value="103">Chelsea</option>
							<option value="163">West Chelsea</option>
							<option value="110">Chinatown</option>
							<option value="111">Two Bridges</option>
							<option value="103">Civic Center</option>
							<option value="117">East Village</option>
							<option value="104">Financial District</option>
							<option value="114">Fulton/Seaport</option>
							<option value="158">Flatiron</option>
							<option value="159">NoMad</option>
							<option value="113">Gramercy Park</option>
							<option value="116">Greenwich Village</option>
							<option value="118">Noho</option>
							<option value="108">Little Italy</option>
							<option value="109">Lower East Side</option>
							<option value="162">Nolita</option>
							<option value="107">Soho</option>
							<option value="106">Stuyvesant Town/PCV</option>
							<option value="105">Tribeca</option>
							<option value="157">West Village</option>
							<option value="300"><b>Brooklyn</b></option>
							<option value="306">Boerum Hill</option>
							<option value="305">Brooklyn Heights</option>
							<option value="321">Caroll Gardens</option>
							<option value="364">Clinton Hill</option>
							<option value="322">Cobble Hill</option>
							<option value="325">Crown Heights</option>
							<option value="307">Dumbo</option>
							<option value="303">Downtown Brooklyn</option>
							<option value="304">Fort Greene</option>
							<option value="319">Park Slope</option>
							<option value="326">Prospect Heights</option>
							<option value="318">Red Hook</option>
							<option value="302">Williamsburg</option>
							<option value="400"><b>Queens</b></option>
							<option value="401">Astoria</option>
							<option value="428">Bayside</option>
							<option value="415">Forest Hills</option>
							<option value="430">Little Neck</option>
							<option value="402">Long Island City</option>
							<option value="404">Woodside</option>
						</select>
					</label>
				</div>
			</div>
			
			<div class="row">
				<div class="large-12 columns">
					<label for="area">Amenities
						<select multiple name="amenities[]" id="amenities">
							<option value="doorman">Doorman</option>
							<option value="dishwasher">Dishwasher</option>
							<option value="elevator">Elevator</option>
							<option value="gym">Gym</option>
							<option value="laundry">Laundry In Building</option>
							<option value="washer_dryer">Washer / Dryer</option>
						</select>
					</label>
				</div>
			</div>

			<div class="row">
				<!--<input type="submit" value="Save">-->
				<a role="button" aria-label="submit form" href="#" class="button" onclick="document.getElementById('mainForm').submit(); return false;">Save</a>
			</div>
			
		</form>
		
		<script src="http://www.parsecdn.com/js/parse-1.2.12.min.js"></script>
		<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1/jquery.min.js"></script>
		<script src="app.js"></script>
	
	</body>
</html><?php

echo '<!-- end -->';

?>