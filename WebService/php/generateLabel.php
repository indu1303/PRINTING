<?php
date_default_timezone_set("America/Los_Angeles");
require_once('/ids/tools/PRINTING/WebService/php/nusoap.php');
$server = new soap_server;
$server->register('generateLabel');

function generateLabel($UserCredential,$password,$AccountNumber,$MeterNumber,$CustomerTransactionId,$ServiceType,$OfficePerson,$OfficeCompanyName,$OfficeAddress,$OfficeCity,$OfficeState,$OfficeZip,$OfficePhone,$RecipientName,$RecipientCompanyName,$RecipientAddress,$RecipientAddress2,$RecipientCity,$RecipientState,$RecipientZip,$RecipientPhone,$CustomerReference,$signature=0) {

$zipLength=strlen($RecipientZip);
if($zipLength<5){
        $pref='';
        for($j=1;$j<=5-$zipLength;$j++){
	        $pref .='0';
        }
	$RecipientZip=$pref. $RecipientZip;
}

define('SITE_PNG_PATH','/ids/tools/PRINTING/PNG/');

$newline = "<br />";

ini_set("soap.wsdl_cache_enabled", "0");

$specialRequested=array('Weight' => array('Value' => 1, 'Units' => 'LB'),'CustomerReferences'=>array('CustomerReferenceType'=>'CUSTOMER_REFERENCE','Value'=>$CustomerReference));
$dropOffType='REGULAR_PICKUP';
$currDay=Date('w');
if($currDay == 6){
	$dropOffType='DROP_BOX';
}

if($signature){
	$specialRequested=array('SpecialServicesRequested'=>array('SpecialServiceTypes'=>array('SIGNATURE_OPTION'),'SignatureOptionDetail' => array('OptionType'=>'DIRECT')),'Weight' => array('Value' => 1, 'Units' => 'LB'),'CustomerReferences'=>array('CustomerReferenceType'=>'CUSTOMER_REFERENCE','Value'=>$CustomerReference));
}

$PackagingType = 'FEDEX_ENVELOPE';	
if($ServiceType =='FEDEX_GROUND') {
	$PackagingType = 'YOUR_PACKAGING';
}
$client = new SoapClient('http://localhost/ShipService_v2.wsdl', array('trace' => 1));
$request['WebAuthenticationDetail'] = array('UserCredential' =>  array('Key' => $UserCredential, 'Password' => $password));
$request['AuthenticationDetail'] = array('UserCredential' => $UserCredential); 
$request['ClientDetail'] = array('AccountNumber' => $AccountNumber, 'MeterNumber' => $MeterNumber);
$request['TransactionDetail'] = array('CustomerTransactionId' => $CustomerTransactionId);
$request['Version'] = array('ServiceId' => 'ship', 'Major' => '2', 'Intermediate' => '0', Minor => '0');
$request['RequestedShipment'] = array('ShipTimestamp' => date('c'),
                                                            'DropoffType' => $dropOffType, 
                                                                'ServiceType' => $ServiceType, 
                                                                'PackagingType' => $PackagingType,
                                                                'TotalWeight' => array('Value' => 0, 'Units' => 'LB'), 
                                                                'PreferredCurrency' => 'USD',
                                                                'Shipper' => array('Contact' => array('PersonName' => $OfficePerson,
                                                                                                      'CompanyName' => $OfficeCompanyName,
                                                                                                      'PhoneNumber' => $OfficePhone),
                                                                                   'Address' => array('StreetLines' => array($OfficeAddress),
                                                                                                      'City' => $OfficeCity,
                                                                                                      'StateOrProvinceCode' => $OfficeState,
                                                                                                      'PostalCode' => $OfficeZip,
                                                                                                      'CountryCode' => 'US')),
                                                                'Recipient' => array('Contact' => array('PersonName' => $RecipientName,
                                                                                                        'CompanyName' => $RecipientCompanyName,
                                                                                                        'PhoneNumber' => $RecipientPhone),
                                                                                     'Address' => array('StreetLines' => array($RecipientAddress,$RecipientAddress2),
                                                                                                        'City' => $RecipientCity,
                                                                                                        'StateOrProvinceCode' => $RecipientState,
                                                                                                        'PostalCode' => $RecipientZip,
                                                                                                        'CountryCode' => 'US'),
                                                                                                        'Residential' => true),
                                                                'Origin' => array('Address' => array('StreetLines' => array($OfficeAddress),
                                                                                  'City' => $OfficeCity,
                                                                                  'StateOrProvinceCode' =>  $OfficeState,
                                                                                  'PostalCode' => $OfficeZip,
                                                                                  'CountryCode' => 'US')),
                                                                'ShippingChargesPayment' => array('PaymentType' => 'SENDER', 
                                                                                                  'Payor' => array('AccountNumber' => $AccountNumber,
                                                                                                                   'CountryCode' => 'US')),
                                                                'LabelSpecification' => array('LabelFormatType' => 'COMMON2D', 
                                                                                              'ImageType' => 'PNG','CustomerSpecifiedDetail'=>array('MaskedData'=>'SHIPPER_ACCOUNT_NUMBER')), 
                                                                'RateRequestTypes' => array('ACCOUNT'), 
                                                                'PackageCount' => 1,
								'RequestedPackages'=>$specialRequested);
try
{
    $response = $client->processShipment($request);  // FedEx web service invocation
    if ($response->HighestSeverity != 'FAILURE' && $response->HighestSeverity != 'ERROR')
    {
	$trackingNumber=$response->CompletedShipmentDetail->CompletedPackageDetails->TrackingId->TrackingNumber.'.png';
        $fp = fopen(SITE_PNG_PATH.$trackingNumber, 'wb');   
        fwrite($fp, $response->CompletedShipmentDetail->CompletedPackageDetails->Label); //Create PNG or PDF file
        fclose($fp);
	return 'TRACKING_NUMBER:' .$response->CompletedShipmentDetail->CompletedPackageDetails->TrackingId->TrackingNumber;
    }
    else
    {
	$error='';
        foreach ($response->Notifications as $notification)
        {
		if($notification->Message){
			if($notification->Code == '6580' || $notification->Code == '6533'){
				continue;
			}
		        $error .= $notification->Message . "  ";
		}else{
			$error = $notification . " ";
		}
        }
	return "FEDEXERROR:".$error;
    }


} catch (SoapFault $exception) {
	if("SOAP-ERROR: Encoding: Element 'Intermediate' has fixed value '1' (value '0' is not allowed)" !=  $exception->faultstring)
	{
		$error=$exception->faultstring;
	}else{
		$error='UNKNOWN';
  	}
	return "FEDEXERROR:" .$error;

}
}
$HTTP_RAW_POST_DATA = isset($HTTP_RAW_POST_DATA) ? $HTTP_RAW_POST_DATA : '';
$server->service($HTTP_RAW_POST_DATA);
?>
