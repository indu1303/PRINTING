package printerSite;

use strict;
use vars qw(
            @ISA @EXPORT $SITE_ORACLEHOME $SITE_ORACLESID $SITE_ORACLEUSER $SITE_ORACLEPASS
            $SITE_PROD_URL $SITE_PROD_URL_SECURE $SITE_PROD_IMAGE_URL $SITE_PROD_IMAGE_URL_SECURE 
            $SITE_FEDEX_SERVER $SITE_PROD_IMAGE_AFFILIATES_URL_SECURE $SITE_PROD_IMAGE_AFFILIATES_URL
            $CRM_DATABASE $CRM_DATABASE_HOST $CRM_DATABASE_USER $CRM_DATABASE_PASSWORD $SITE_PRINTING_PATH 
	    $DIP_DATABASE $DIP_DATABASE_HOST $DIP_DATABASE_USER $DIP_DATABASE_PASSWORD 
	    $TEEN_DATABASE $TEEN_DATABASE_HOST $TEEN_DATABASE_USER $TEEN_DATABASE_PASSWORD 
	    $AZTS_DATABASE $AZTS_DATABASE_HOST $AZTS_DATABASE_USER $AZTS_DATABASE_PASSWORD 
	    $TSTG_DATABASE $TSTG_DATABASE_HOST $TSTG_DATABASE_USER $TSTG_DATABASE_PASSWORD 
	    $FLEET_DATABASE $FLEET_DATABASE_HOST $FLEET_DATABASE_USER $FLEET_DATABASE_PASSWORD 
	    $CLASSROOM_DATABASE $CLASSROOM_DATABASE_HOST $CLASSROOM_DATABASE_USER $CLASSROOM_DATABASE_PASSWORD 
	    $PRINTING_DATABASE $PRINTING_DATABASE_HOST $PRINTING_DATABASE_USER $PRINTING_DATABASE_PASSWORD 
	    $SITE_ADMIN_LOG_DIR $SITE_PNG_PATH $SITE_TEMPLATES_PATH 
	    $CLASS_DATABASE $CLASS_DATABASE_HOST $CLASS_DATABASE_USER $CLASS_DATABASE_PASSWORD 
	    $AHST_DATABASE $AHST_DATABASE_HOST $AHST_DATABASE_USER $AHST_DATABASE_PASSWORD 
	    $HTS_DATABASE $HTS_DATABASE_HOST $HTS_DATABASE_USER $HTS_DATABASE_PASSWORD 
            $SITE_PROD_MATURE_URL $SITE_PROD_TEEN_URL $SITE_PROD_AHST_URL $SITE_PROD_HTS_URL $SITE_PROD_ADULT_URL
            $DIP_SUPPORT_NUMBER $MATURE_SUPPORT_NUMBER $AHST_SUPPORT_NUMBER $HTS_SUPPORT_NUMBER
	    $DSMS_DATABASE $DSMS_DATABASE_USER $DSMS_DATABASE_PASSWORD $DSMS_DATABASE_HOST
	    $ADULT_DATABASE $ADULT_DATABASE_USER $ADULT_DATABASE_PASSWORD $ADULT_DATABASE_HOST
	    $AAAFLEET_DATABASE $AAAFLEET_DATABASE_USER $AAAFLEET_DATABASE_PASSWORD $AAAFLEET_DATABASE_HOST
	    $CAAFLEET_DATABASE $CAAFLEET_DATABASE_USER $CAAFLEET_DATABASE_PASSWORD $CAAFLEET_DATABASE_HOST
	    $AAADIP_DATABASE $AAADIP_DATABASE_USER $AAADIP_DATABASE_PASSWORD $AAADIP_DATABASE_HOST
	    $AAATEEN_DATABASE $AAATEEN_DATABASE_USER $AAATEEN_DATABASE_PASSWORD $AAATEEN_DATABASE_HOST
	    $DIPDVD_DATABASE $DIPDVD_DATABASE_USER $DIPDVD_DATABASE_PASSWORD
	    $TAKEHOME_DATABASE $TAKEHOME_DATABASE_USER $TAKEHOME_DATABASE_PASSWORD $TAKEHOME_DATABASE_HOST
	    $USI_ONLINE_DATABASE $USI_ONLINE_DATABASE_USER $USI_ONLINE_DATABASE_PASSWORD $USI_ONLINE_DATABASE_HOST
	    $AARP_DATABASE $AARP_DATABASE_USER $AARP_DATABASE_PASSWORD $AARP_DATABASE_HOST	
	    $AARP_CLASSROOM_DATABASE $AARP_CLASSROOM_DATABASE_USER $AARP_CLASSROOM_DATABASE_PASSWORD $AARP_CLASSROOM_DATABASE_HOST $FLEET_CA_DATABASE $FLEET_CA_DATABASE_USER $FLEET_CA_DATABASE_PASSWORD $FLEET_CA_DATABASE_HOST
	    $AARP_VOLUNTEER_DATABASE $AARP_VOLUNTEER_DATABASE_USER $AARP_VOLUNTEER_DATABASE_PASSWORD $AARP_VOLUNTEER_DATABASE_HOST
	    $SCORM_DATABASE $SCORM_DATABASE_USER $SCORM_DATABASE_PASSWORD $SCORM_DATABASE_HOST 
            $AAA_SENIORS_DATABASE $AAA_SENIORS_DATABASE_USER $AAA_SENIORS_DATABASE_PASSWORD $AAA_SENIORS_DATABASE_HOST	
	    $DRIVERSED_DATABASE $DRIVERSED_DATABASE_USER $DRIVERSED_DATABASE_PASSWORD $DRIVERSED_DATABASE_HOST
	    $EDRIVING_DATABASE $EDRIVING_DATABASE_USER $EDRIVING_DATABASE_PASSWORD $EDRIVING_DATABASE_HOST
            );

#require Exporter;
#@ISA = qw( Exporter );
#@Export = qw();

$SITE_ORACLEHOME                        = '/opt/oracle/product/9.2.0.10';
$SITE_ORACLESID                         = 'oracle1';
$SITE_ORACLEUSER                        = 'web';
$SITE_ORACLEPASS                        = 'web';

###################  Add a couple of entries for the CRM
$CRM_DATABASE                           = 'crm';
$CRM_DATABASE_HOST                      = '192.168.1.7';
$CRM_DATABASE_USER                      = 'crm';
$CRM_DATABASE_PASSWORD                  = 'ids';
$SITE_FEDEX_SERVER                      = '172.20.2.155';
$SITE_ADMIN_LOG_DIR                     = '/www/logs/admin';

$SITE_PROD_URL                          = 'http://www.idrivesafely.com';
$SITE_PROD_URL_SECURE                   = 'https://www.idrivesafely.com';
$SITE_PROD_IMAGE_URL                    = '/newsite/images';
$SITE_PROD_IMAGE_URL_SECURE             = '/newsite/images';

$SITE_PROD_IMAGE_AFFILIATES_URL         = '/images';
$SITE_PROD_IMAGE_AFFILIATES_URL_SECURE  = '/images';
$SITE_PNG_PATH                          = '/ids/tools/PRINTING/PNG';          
$SITE_TEMPLATES_PATH                    = '/ids/tools/PRINTING/templates';          
$SITE_PRINTING_PATH                     = '/ids/tools/PRINTING';
$DIP_DATABASE                           = 'rajesh_dip';
$DIP_DATABASE_USER                      = 'rajesh_dip';
$DIP_DATABASE_PASSWORD                  = 'rajesh_dip';
$DIP_DATABASE_HOST                      = '192.168.1.7';
$TEEN_DATABASE                          = 'teen';
$TEEN_DATABASE_USER                     = 'teen';
$TEEN_DATABASE_PASSWORD                 = 'teen';
$TEEN_DATABASE_HOST                     = '192.168.1.7';
$AZTS_DATABASE                          = 'azts';
$AZTS_DATABASE_USER                     = 'azts';
$AZTS_DATABASE_PASSWORD                 = 'azts';
$AZTS_DATABASE_HOST                     = '192.168.1.7';
$TSTG_DATABASE                          = 'tstg';
$TSTG_DATABASE_USER                     = 'tstg';
$TSTG_DATABASE_PASSWORD                 = 'tstg';
$TSTG_DATABASE_HOST                     = '192.168.1.7';
$FLEET_DATABASE                         = 'fleet';
$FLEET_DATABASE_USER                    = 'fleet';
$FLEET_DATABASE_PASSWORD                = 'fleet';
$FLEET_DATABASE_HOST                    = '192.168.1.7';
$CLASSROOM_DATABASE                     = 'classroom';
$CLASSROOM_DATABASE_USER                = 'classroom';
$CLASSROOM_DATABASE_PASSWORD            = 'classroom';
$CLASSROOM_DATABASE_HOST                = '192.168.1.7';
$PRINTING_DATABASE                      = 'crm';
$PRINTING_DATABASE_USER                 = 'crm';
$PRINTING_DATABASE_PASSWORD             = 'ids';
$PRINTING_DATABASE_HOST                 = '192.168.1.7';
$CLASS_DATABASE                         = 'class';
$CLASS_DATABASE_USER                    = 'class';
$CLASS_DATABASE_PASSWORD                = 'class';
$CLASS_DATABASE_HOST                    = '192.168.1.7';
$AHST_DATABASE                          = 'ahst';
$AHST_DATABASE_USER                     = 'ahst';
$AHST_DATABASE_PASSWORD                 = 'ahst';
$AHST_DATABASE_HOST                     = '192.168.1.7';
$HTS_DATABASE                           = 'hts';
$HTS_DATABASE_USER                      = 'hts';
$HTS_DATABASE_PASSWORD                  = 'hts';
$HTS_DATABASE_HOST                      = '192.168.1.7';

$SITE_PROD_MATURE_URL                   = 'http://mature.idrivesafely.com';
$SITE_PROD_TEEN_URL                     = 'http://teen.idrivesafely.com';
$SITE_PROD_AHST_URL                     = 'http://www.affordablehomestudy.com';
$SITE_PROD_HTS_URL                      = 'http://happytrafficschool.com';
$SITE_PROD_ADULT_URL                    = 'http://adultdriversed.idrivesafely.com';
$DIP_SUPPORT_NUMBER                     = '1-800-723-1955';
$MATURE_SUPPORT_NUMBER                  = '1-800-448-7916';
$AHST_SUPPORT_NUMBER                    = '1-800-260-2295';
$HTS_SUPPORT_NUMBER                     = '1-800-582-8025';

$DSMS_DATABASE                          = 'dsms';
$DSMS_DATABASE_USER                     = 'dsms';
$DSMS_DATABASE_PASSWORD                 = 'dsms';
$DSMS_DATABASE_HOST                     = '192.168.1.7';

$ADULT_DATABASE                          = 'adult';
$ADULT_DATABASE_USER                     = 'adult';
$ADULT_DATABASE_PASSWORD                 = 'adult';
$ADULT_DATABASE_HOST                     = '192.168.1.7';

$AAAFLEET_DATABASE                      = 'aaa';
$AAAFLEET_DATABASE_USER                 = 'aaa';
$AAAFLEET_DATABASE_PASSWORD             = 'aaa';
$AAAFLEET_DATABASE_HOST                 = '192.168.1.7';

$AAADIP_DATABASE                      = 'aaadip';
$AAADIP_DATABASE_USER                 = 'aaadip';
$AAADIP_DATABASE_PASSWORD             = 'aaadip';
$AAADIP_DATABASE_HOST                 = '192.168.1.7';

$AAATEEN_DATABASE                      = 'aaateen';
$AAATEEN_DATABASE_USER                 = 'aaateen';
$AAATEEN_DATABASE_PASSWORD             = 'aaateen';
$AAATEEN_DATABASE_HOST                 = '192.168.1.7';

$CAAFLEET_DATABASE                      = 'caa';
$CAAFLEET_DATABASE_USER                 = 'caa';
$CAAFLEET_DATABASE_PASSWORD             = 'caa';
$CAAFLEET_DATABASE_HOST                 = '192.168.1.7';

$DIPDVD_DATABASE                      = 'FOUNDATIONDB';
$DIPDVD_DATABASE_USER                 = 'foundationuser';
$DIPDVD_DATABASE_PASSWORD             = 'ragnar0s';

$TAKEHOME_DATABASE                      = 'usi';
$TAKEHOME_DATABASE_USER                 = 'usi';
$TAKEHOME_DATABASE_PASSWORD             = 'usi';
$TAKEHOME_DATABASE_HOST                 = '192.168.1.7';

$USI_ONLINE_DATABASE                      = 'usi_diponline';
$USI_ONLINE_DATABASE_USER                 = 'usi_diponline';
$USI_ONLINE_DATABASE_PASSWORD             = 'usi_diponline';
$USI_ONLINE_DATABASE_HOST                 = '192.168.1.7';

$AARP_DATABASE                      = 'aarp';
$AARP_DATABASE_USER                 = 'aarp';
$AARP_DATABASE_PASSWORD             = 'aarp';
$AARP_DATABASE_HOST                 = '192.168.1.7'; 

$AARP_CLASSROOM_DATABASE                = 'aarp_classroom';
$AARP_CLASSROOM_DATABASE_USER           = 'aarp_classroom';
$AARP_CLASSROOM_DATABASE_PASSWORD       = 'aarp_classroom';
$AARP_CLASSROOM_DATABASE_HOST           = '192.168.1.7';

$FLEET_CA_DATABASE                      = 'fleet_ca';
$FLEET_CA_DATABASE_USER                 = 'fleet_ca';
$FLEET_CA_DATABASE_PASSWORD             = 'fleet_ca';
$FLEET_CA_DATABASE_HOST                 = '192.168.1.7';

$AARP_VOLUNTEER_DATABASE                      = 'aarp_vol';
$AARP_VOLUNTEER_DATABASE_USER                 = 'aarp_vol';
$AARP_VOLUNTEER_DATABASE_PASSWORD             = 'aarp_vol';
$AARP_VOLUNTEER_DATABASE_HOST                 = '192.168.1.7';

$SCORM_DATABASE                      = 'idsscorm';
$SCORM_DATABASE_USER                 = 'idsscorm';
$SCORM_DATABASE_PASSWORD             = 'idsscorm';
$SCORM_DATABASE_HOST                 = '192.168.1.7';

$AAA_SENIORS_DATABASE           = 'aaa_seniors';
$AAA_SENIORS_DATABASE_USER      = 'aaa_seniors';
$AAA_SENIORS_DATABASE_PASSWORD  = 'aaa_seniors';
$AAA_SENIORS_DATABASE_HOST      = '192.168.1.7';

$DRIVERSED_DATABASE           = 'driversed';
$DRIVERSED_DATABASE_USER      = 'driversed';
$DRIVERSED_DATABASE_PASSWORD  = 'driversed';
$DRIVERSED_DATABASE_HOST      = '192.168.1.7';

$EDRIVING_DATABASE           = 'rajesh_dip';
$EDRIVING_DATABASE_USER      = 'rajesh_dip';
$EDRIVING_DATABASE_PASSWORD  = 'rajesh_dip';
$EDRIVING_DATABASE_HOST      = '192.168.1.7';

1;
