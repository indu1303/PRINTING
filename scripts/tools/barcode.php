<?php 
               $data ='<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><GenerateBarCode xmlns="http://tempuri.org/"><BCodeValue>'.$argv[1].'</BCodeValue></GenerateBarCode></soap:Body></soap:Envelope>';
#		$url = "http://192.168.1.89/Code39BarCodeWS/Service.asmx";
		$url = "http://10.10.90.67/Code39BarCodeWS/Service.asmx";
		$length = strlen($data);
		$params = array('http' => array(
                          'method' => 'POST',
                          'content' => $data,
			  'header'=> 'Content-Type: text/xml; charset=utf-8',
			'Content-length' => $length,
			'SOAPAction'=> 'http://tempuri.org/GenerateBarCode'
                       ));
                $ctx = stream_context_create($params);
                $fp = @fopen($url, 'rb', false, $ctx);
                if (!$fp) {
                        throw new Exception("Problem with $url, $php_errormsg");
                }
                $response = @stream_get_contents($fp);
                if ($response === false) {
                        throw new Exception("Problem reading data from $url, $php_errormsg");
                }
		$fp = fopen('/tmp/barcode.xml', 'w');
        	fwrite($fp, "$response"); //Create PNG or PDF file
        	fclose($fp);
		if (file_exists('/tmp/barcode.xml')) 
		{
			$p = xml_parser_create();
			xml_parse_into_struct($p, $response, $vals, $index);
			xml_parser_free($p);
			foreach ($vals as $key => $val)
			{
				if ($val['tag'] == 'GENERATEBARCODERESULT')
				{
					$content = $val['value'];
					header("Content-type :image/jpg");
					echo base64_decode($content);
					unlink('/tmp/barcode.xml');
				}
			}
		}
?>
