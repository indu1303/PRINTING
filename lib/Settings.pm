#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Copyright Idrivesafely.com, Inc. 2006
# All Rights Reserved.  Licensed Software.
#
# THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF Idrivesafely.com, Inc.
# The copyright notice above does not evidence any actual or
# intended publication of such source code.
#
# PROPRIETARY INFORMATION, PROPERTY OF Idrivesafely.com, Inc.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#!/usr/bin/perl -w 

package Settings;

use lib qw(/ids/tools/PRINTING/lib);
use strict;
=pod

=head1 NAME

Printing

=head1 Synopsis

Keeper of all settings and hardcoded values.  These values will be referred to by all parts of the module.

=head1 METHODS

=head2 new

Declare a new instance of this class.  No parameters need to be passed in

=cut

sub new
{
	my $pkg 	= shift;
	my $class 	= ref($pkg) || $pkg;

	my $self = 
        {
            COURSE_AGGREGATE_OVERRIDE => { 1 =>{ 
						35003 => 'North Carolina AAA-Approved Online Traffic Safety Course' 
						},
					  2 =>{ 
						44001 => 'Texas Online Parent-Taught Driver Education Course #109',
						 },
					 },
            FEDEX        => { DIP     => { ACCOUNT => 268931309, METER => 3984297 ,USERCREDENTIAL=>'2ABsdmiG6kEeVv2L',PASSWORD=>'53PUPnXyyhq0jy0sxLi1TfpgN'},
		              TSTG    => { ACCOUNT => 330889624, METER => 8095286 ,USERCREDENTIAL=>'TuxrTY3hZtztNpdI',PASSWORD=>'UWzDpKJ7RPQ8NE3RqzIyWcdDz'},
                              AZTS    => { ACCOUNT => 353452363, METER => 8095331 ,USERCREDENTIAL=>'VQlFvKBhOz60bsGU',PASSWORD=>'BFg5JFTWru4ouFjSGMEYBm7kP'},
			       DPS     => { ACCOUNT => 364221924, METER => 3984379 ,USERCREDENTIAL=>'SJROTCwPDyoQ5fXs',PASSWORD=>'YuZqIHu9q4TwnCXXV7WeecriP'},
                              AHST    => { ACCOUNT => 463598380, METER => 100536480 ,USERCREDENTIAL=>'dQAsS8ih2fOShJhT',PASSWORD=>'2JeMgEtEdjHXPWQxZLwGNXtCS'},
                              HTS     => { ACCOUNT => 463598169, METER => 100536462 ,USERCREDENTIAL=>'LF44vOmsMRJ4CG7A',PASSWORD=>'syKWUnFDEYX9dQfQVtdV4lutO'},
			      AAADIP  => { ACCOUNT => 268931309, METER => 3984297 ,USERCREDENTIAL=>'2ABsdmiG6kEeVv2L',PASSWORD=>'53PUPnXyyhq0jy0sxLi1TfpgN'},
			      DVD     => { ACCOUNT => 268931309, METER => 3984297 ,USERCREDENTIAL=>'2ABsdmiG6kEeVv2L',PASSWORD=>'53PUPnXyyhq0jy0sxLi1TfpgN'},
			      TAKEHOME=> { ACCOUNT => 268931309, METER => 3984297 ,USERCREDENTIAL=>'2ABsdmiG6kEeVv2L',PASSWORD=>'53PUPnXyyhq0jy0sxLi1TfpgN'},
			      USI_ONLINE=>{ ACCOUNT => 268931309, METER => 3984297 ,USERCREDENTIAL=>'2ABsdmiG6kEeVv2L',PASSWORD=>'53PUPnXyyhq0jy0sxLi1TfpgN'},
			      SS      => { ACCOUNT => 268931309, METER => 3984297 ,USERCREDENTIAL=>'2ABsdmiG6kEeVv2L',PASSWORD=>'53PUPnXyyhq0jy0sxLi1TfpgN'},
			      AARP    => { ACCOUNT => 268931309, METER => 103287032 ,USERCREDENTIAL=>'zBnoxtZj7oYgPRd0',PASSWORD=>'nKYKB0otvNitc0vRHhLDCphBj'},
			     DRIVERSED=> { ACCOUNT => 228429775, METER => 107995588 ,USERCREDENTIAL=>'89ZlNJx29MsqPov6',PASSWORD=>'6CAwidiUMeEpvGoheuwPWdsnn'},
            		     EDRIVING => { ACCOUNT => 268931309, METER => 3984297 ,USERCREDENTIAL=>'2ABsdmiG6kEeVv2L',PASSWORD=>'53PUPnXyyhq0jy0sxLi1TfpgN'},
                           },
            USPS        => { 
			DIP     => { ACCOUNT => 998750, REQUESTERID => 'lidr' ,PASSWORD=>'i love coffe and cream'},
			   },
	    USPS_ALLOWED_IPADDRESS => {'10.10.90.75' =>1 },
            NO_PRINT_CERT_PROCESSING_ID => {11=>1, 12=>1, 15=>1, 22=>1, },

	    CTSI_COUNTY                 => {1=>1, 9=>1, 10=>1, 15=>1,  21=>1, 18940=>1, 18958=>1, 25=>1, 28=>1, 30=>1, 18970=>1, 18976=>1, 36=>1, 39=>1, 40=>1, 41=>1, 18985=>1, 48=>1, 56=>1, 54=>1 },

	    COURSEAGGREGATESHELLMAP => { DIP => {
						2001 => 2000, 2002 => 2000, 2003 => 2000, 3001 => 3000, 3002 => 3000, 3003 => 3000, 3004 => 3000, 3005 => 3000, 3006 => 3000,3011 => 3000, 3012 => 3000, 3013 => 3000, 3014 => 3000, 3015 => 3000, 3016 => 3000,  2011 => 2000, 2012 => 2000, 2013 => 2000,  2031 => 2039, 2032 => 2039, 2033 => 2039  },
				       },
            TEXASPRINTING          => {
					'DIP' =>{ 1001 => 'TX', 1003 => 'TX', 1006 => 'TX',1011 => 'TX',1015=>'TX' },
					'CLASSROOM' =>{ 1005 => 'TX',  1007 => 'TX' },
					'TAKEHOME' =>{ 1011 => 'TX' },
				     },

	    TEEN32COURSES	 =>  {
					44006=>1,
					44007=>1,
				     },
	    NO_PRINT_COURSE        => { 
					'DIP' => {2004 => 1 },
					'TEEN' => {10003 => 1 ,10004 => 1, 10005 => 1, 18003 => 1, 6002 => 1},
					 'AAADIP' => {4007 => 1 },
					# 'DRIVERSED' => {'C0000013' => 1 }, ##Jira - CRM-305
				     },
	    CADMVCOURSES	   => { 'DIP' => {33=>1},
				      },
	    DIRECTOR_OF_SCHOOL_SIGNATURE_NAME => 'michael',
	    DIRECTOR_OF_SCHOOL_TEA_NUMBER => 'michael',
	    DIRECTOR_OF_SCHOOL_SIGNATURE_NAME_DE => 'julionew',
	    DIRECTOR_OF_SCHOOL_TEA_NUMBER_DE => 'julionew',
	    FL_CERT_VERIFICATION_COURSE        => { 
					'DIP' => {2001 => 1, 2002=>1, 2003=>1, 2011=>1, 2012=>1, 2013=>1  , 2031=>1, 2032=>1, 2033=>1},
					'TEEN' => {10003 => 1 ,10004 => 1, 10006=>1, 10007=>1, 10009 => 1, 10010 => 1},
				     },
	    NO_REGULARMAIL_PRINT_COURSE        => { 
					'DIP' => {14005=>1, 7004=>1, 15004=>1, 13002=>1, 30004=>1},
				     },
	    POC_COURSES        => { 
					'DIP' => {52005=>1, 13002=>1, 15004=>1, 30004=>1, 31004=>1, 52005=>1},
				     },
	    NOTTOPRINTFIELD	     => {
						SS=>{
							9005=>{
								2=>1,
								},
						    },
					},
            PRODUCT_ID   => {  DIP => 1, TEEN => 2, FLEET => 3, TSTG => 4, CLASSROOM => 5, AZTS => 7, MATURE => 8, CLASS => 10, AHST => 12, HTS => 13, ADULT => 18, DSMS => 19, AAAFLEET => 16, AAADIP  => 21,CAAFLEET => 26, DIPDVD => 22, TAKEHOME=>25 ,SS => 27,  AARP => 28, AARP_CLASSROOM => 29, USI_ONLINE=>31, FLEET_CA => 37, AARP_VOLUNTEER => 34, AAATEEN => 32, AAA_SENIORS => 38, DRIVERSED => 41, EDRIVING => 42},
            PRODUCT_NAME   => { 1 => 'DIP', 2=>'TEEN', 3 => 'FLEET', 4 => 'TSTG', 5 => 'CLASSROOM', 7 => 'AZTS', 8=> 'MATURE', 10 => 'CLASS', 12 => 'AHST', 13 => 'HTS', 18 => 'ADULT', 19 => 'DSMS', 16 => 'AAAFLEET', 21 => 'AAADIP', 26 => 'CAAFLEET', 22 => 'DIPDVD', 25=>'TAKEHOME' , 27 => 'SS', 28 => 'AARP', 29 => 'AARP_CLASSROOM',31=>'USI_ONLINE', 37 => 'FLEET_CA', 34 => 'AARP_VOLUNTEER', 32=>'AAATEEN', 38 => 'AAA_SENIORS', 41 =>'DRIVERSED',42 =>'EDRIVING' },

            HOSTED_AFFILIATE_PRODUCT_ID   => {  TSTG => 4,  AZTS => 7, AHST=> 12, HTS => 13, AAADIP => 21 , AARP => 28, AARP_CLASSROOM => 29, AARP_VOLUNTEER => 34},
            LOGO_PRINT_PRODUCT   => {  DIP => 'IDS', TEEN => 'IDS', FLEET => 'IDS', CLASSROOM => 'IDS',  MATURE => 'IDS', CLASS => 'IDS',  ADULT => 'IDS', DSMS => 'IDS', TAKEHOME=>'IDS', DRIVERSED => 'DE', EDRIVING => 'EDRIVING'},

            CERT_POOL    => {  1001 => 1001, 1003 => 1001, 1005 => 1005, 1007 => 1001,1006 => 1005, 1011 => 1001 ,1015=>1011 },

	    CERT_POOL_USI    => {  1011 => 1011, 1021 => 1021, 1022 => 1021, 1023 => 1021 , 1024 => 1021,1015=>1011},

	    CERT_POOL_ADULT    => {  44004 => 44004, 44005 => 44004, 44006 => 44004, 44007 => 44004, 44014 => 44004, 44015 => 44004},
	    
	    CERT_POOL_DRIVERSED  => {  C0000063 => 'C0000063', C0000020 => 'C0000020', C0000071 => 'C0000071', BTWTMINI03 => 'C0000071', },

	    CERT_POOL_TEEN    => {  44003 => 44003, 44006=>44006, 44007=>44006},

            OFFICE_CA    => { 
			DEFAULT => {  NAME => 'I DRIVE SAFELY', ADDRESS => '283 4th st Unit 301', CITY => 'Oakland',
                              STATE => 'CA', ZIP => '94607', PHONE    => '(760) 744-3070' },
			DPS     => {  NAME => 'I DRIVE SAFELY', ADDRESS => '7507 ARBODELA COVE', CITY => 'AUSTIN',
                              STATE => 'TX', ZIP => '78745', PHONE    => '(800) 723-1955' },
			TSTG    => {  NAME => 'Traffic School To Go', ADDRESS => '283 4th st Unit 301', CITY => 'Oakland',
                              STATE => 'CA', ZIP => '94607', PHONE    => '888.349.8425' },
			AZTS    => {  NAME => 'Arizona Traffic Schools', ADDRESS => '283 4th st Unit 301', CITY => 'Oakland',
                              STATE => 'CA', ZIP => '94607', PHONE    => '(800) 448-7916' },
			AHST    => {  NAME => 'Affordable Home Study Program', ADDRESS => '300 Carlsbad Village Dr. Ste 108A-289', CITY => 'CARLSBAD',
			      STATE => 'CA', ZIP => '94607', PHONE    => '800.984.7233' },
			HTS     => {  NAME => 'Happy Traffic School', ADDRESS => '7040 Avenida Encinas Suite 104', CITY => 'Oakland',
			      STATE => 'CA', ZIP => '92011', PHONE    => '800.582.8575' },
			FDK     => {  NAME => 'I DRIVE SAFELY', ADDRESS => '4201 FM 1960 WEST, STE. 100', CITY => 'HOUSTON',
			      STATE => 'TX', ZIP => '77068', PHONE    => '(800) 723-1955' },	
			AAADIP => {  NAME => 'AAA Online Driver Improvement', ADDRESS => '283 4th st Unit 301, SUITE 210', CITY => 'Oakland',
			      STATE => 'CA', ZIP => '94607', PHONE    => '(877) 499-9153' },
			AAATEEN => {  NAME => 'AAA HOW TO DRIVE ONLINE', ADDRESS => '283 4th st Unit 301', CITY => 'Oakland',
			      STATE => 'CA', ZIP => '94607', PHONE    => '(877) 499-9153' },
			IDSPOC => {  NAME => 'I DRIVE SAFELY', ADDRESS => '283 4th st Unit 301', CITY => 'Oakland',
                              STATE => 'CA', ZIP => '94607', PHONE    => '(760) 744-3070' },
			AHST_PO    => {  NAME => 'Affordable Home Study Program', ADDRESS => '300 Carlsbad Village Drive, Suite 108A-289', CITY => 'CARLSBAD',
			      STATE => 'CA', ZIP => '94607', PHONE    => '(800) 984-7233' },
			HTS_PO     => {  NAME => 'Happy Traffic School', ADDRESS => '7040 Avenida Encinas, Suite 104', CITY => 'CARLSBAD',
			      STATE => 'CA', ZIP => '92011', PHONE    => '(800) 582-8575' },
			FLEET => {  NAME => 'I DRIVE SAFELY', ADDRESS => '283 4th st Unit 301', CITY => 'Oakland',
                              STATE => 'CA', ZIP => '94607', PHONE    => '(877) 566-6323' },
			TAKEHOME => {  NAME => 'I DRIVE SAFELY', ADDRESS => '283 4th st Unit 301', CITY => 'Oakland',
			      STATE => 'CA', ZIP => '94607', PHONE    => '(800) 505 5095' },
			USI_ONLINE => {  NAME => 'I DRIVE SAFELY', ADDRESS => '283 4th st Unit 301', CITY => 'Oakland',
			      STATE => 'CA', ZIP => '94607', PHONE    => '(800) 505 5095' },
			SS  => {  NAME => 'SellerServer.com', ADDRESS => '283 4th st Unit 301', CITY => 'Oakland',
                              STATE => 'CA', ZIP => '94607', PHONE    => '(866) 378-1587' },
			AARP => {  NAME => 'AARP', ADDRESS => '283 4th st Unit 301', CITY => 'Oakland',
                              STATE => 'CA', ZIP => '94607', PHONE    => '1-800-350-7025' },
			AARP_CLASSROOM => {  NAME => 'AARP', ADDRESS => '283 4th st Unit 301', CITY => 'Oakland',
                              STATE => 'CA', ZIP => '94607', PHONE    => '1-800-350-7025' },
			AARP_VOLUNTEER => {  NAME => 'AARP', ADDRESS => '283 4th st Unit 301', CITY => 'Oakland',
                              STATE => 'CA', ZIP => '94607', PHONE    => '1-800-350-7025' },
			FLEET_CA => {  NAME => 'I DRIVE SAFELY', ADDRESS => '283 4th st Unit 301', CITY => 'Oakland',
                              STATE => 'CA', ZIP => '94607', PHONE    => '(877) 566-6323' },
			DSMS_ADULT_BTW => {  NAME => 'I DRIVE SAFELY', ADDRESS => '283 4th st Unit 301', CITY => 'Oakland',
                              STATE => 'CA', ZIP => '94607', PHONE    => '(888) 522-2226' },
			AAA_SENIORS => {  NAME => 'AAA Driver Training Programs', ADDRESS => '283 4th st Unit 301', CITY => 'Oakland',
			      STATE => 'CA', ZIP => '94607', PHONE    => 'Phone: (866) 895-7290' },
			AAA_SENIORS_FDK  => {  NAME => 'I DRIVE SAFELY', ADDRESS => '4201 FM 1960 WEST, STE. 100', CITY => 'HOUSTON',
			      STATE => 'TX', ZIP => '77068', PHONE    => '(866) 895-7290' },	
			AAA_SENIORS_ADD => {  NAME => 'AAA Driver Training Programs', ADDRESS => '1000 AAA Drive, MS 72', CITY => 'Heathrow',
			      STATE => 'FL', ZIP => '32746', PHONE    => 'Phone: (866) 895-7290' },
			AAA_SENIORS_ADDTW => {  NAME => 'AAA Driver Training Programs', ADDRESS => '5366 Virginia Beach Blvd', CITY => 'Virginia Beach',
			      STATE => 'VA', ZIP => '23462', PHONE    => 'Phone: (757) 233-3887' },
			AAA_SENIORS_ADDMI => {  NAME => 'AAA Driver Training Programs', ADDRESS => '1 RIVER PLACE', CITY => 'Wilmington',
			      STATE => 'DE', ZIP => '19801', PHONE    => 'Phone: (800)999-4952 x62722, x64120' },
			AAA_TEEN  => {  NAME => 'I DRIVE SAFELY', ADDRESS => '4201 FM 1960 WEST, STE. 100', CITY => 'HOUSTON',
			      STATE => 'TX', ZIP => '77068', PHONE    => '(855) 846-2857' },	
		        DRIVERSED  => {  NAME => 'DriversEd.com', ADDRESS => '283 4th Street, Suite 301', CITY => 'Oakland',
                              STATE=>'CA' , ZIP=>'94607' ,PHONE    => '(510) 433-0606' },
			EDRIVING => {  NAME => 'eDriving', ADDRESS => '283 4th st Unit 301', CITY => 'Oakland',
                              STATE => 'CA', ZIP => '94607', PHONE    => '(760) 744-3070' },
			DRIVERSEDTX  => {  NAME => 'www.driversed.com', ADDRESS => '4201 FM 1960 WEST, STE. 100', CITY => 'HOUSTON',
			      STATE => 'TX', ZIP => '77068', PHONE    => '(888) 651-2886' },	
			IDS_OAKLAND_NEW => {  NAME => 'I DRIVE SAFELY', ADDRESS => '283 4th Street, Suite 301', CITY => 'Oakland',
                              STATE => 'CA', ZIP => '94607', PHONE    => '(800) 735-2929' },
			AARP  => {  NAME => 'AARP', ADDRESS => '4201 FM 1960 WEST, STE. 100', CITY => 'HOUSTON',
			      STATE => 'TX', ZIP => '77068', PHONE    => '(800) 350-7025' },	

			    },	
	     NON_WEST_COAST_STATES_OFFICE_ADDRESS   => {
			      TAKEHOME     => {  NAME => 'I DRIVE SAFELY', ADDRESS => '4201 FM 1960 WEST, STE. 100', CITY => 'HOUSTON',
				STATE => 'TX', ZIP => '77068', PHONE    => '(800) 505 5095' },
			      USI_ONLINE     => {  NAME => 'I DRIVE SAFELY', ADDRESS => '4201 FM 1960 WEST, STE. 100', CITY => 'HOUSTON',
				STATE => 'TX', ZIP => '77068', PHONE    => '(800) 505 5095' },
			      SS     => {  NAME => 'SellerServer.com', ADDRESS => '4201 FM 1960 WEST, STE. 100', CITY => 'HOUSTON',
                              STATE => 'TX', ZIP => '77068', PHONE    => '(866) 378-1587' },
			      AARP	   => { NAME => 'AARP', ADDRESS => '4201 FM 1960 WEST', ADDRESS1 =>  ', STE. 100', ADDRESS2 => ' ', CITY => 'HOUSTON', STATE => 'TX', ZIP => '77068', PHONE    => '1-800-350-7025' },
			      AARP_CLASSROOM	   => { NAME => 'AARP', ADDRESS => '4201 FM 1960 WEST', ADDRESS1 =>  ', STE. 100', ADDRESS2 => ' ', CITY => 'HOUSTON', STATE => 'TX', ZIP => '77068', PHONE    => '1-800-350-7025' },
			      AARP_VOLUNTEER	   => { NAME => 'AARP', ADDRESS => '4201 FM 1960 WEST', ADDRESS1 =>  ', STE. 100', ADDRESS2 => ' ', CITY => 'HOUSTON', STATE => 'TX', ZIP => '77068', PHONE    => '1-800-350-7025' },
			      AAA_SENIORS => {  NAME => 'AAA Driver Training Programs', ADDRESS => '4201 FM 1960 WEST, STE. 100', CITY => 'HOUSTON',
			      STATE => 'TX', ZIP => '77068', PHONE    => '(866) 895-7290' },	
			      AAA_TEEN  => {  NAME => 'I DRIVE SAFELY', ADDRESS => '4201 FM 1960 WEST, STE. 100', CITY => 'HOUSTON',
			      STATE => 'TX', ZIP => '77068', PHONE    => '(855) 846-2857' },	
		              DRIVERSED  => {  NAME => 'DriversEd.com', ADDRESS => '4201 FM 1960 WEST,STE 100', CITY => 'HOUSTON',
                              STATE=>'TX' , ZIP=>'77068' ,PHONE    => '(888)-651-2886' },
			      EDRIVING     => {  NAME => 'eDriving', ADDRESS => '4201 FM 1960 WEST, STE. 100', CITY => 'HOUSTON',
                              STATE => 'TX', ZIP => '77068', PHONE    => '(800) 723-1955' },
			    },

            PRINTING_API => {  DIP => 'DIP', TEEN => 'Teen', FLEET => 'Fleet', TSTG => 'TSTG', CLASSROOM => 'Classroom', AZTS => 'AZTS' ,'MATURE' => 'Mature' , 'CLASS' => 'Class', AHST => 'AHST', HTS => 'HTS', ADULT => 'Adult', DSMS=>'DSMS', AAAFLEET => 'AAAFleet', CAAFLEET => 'CAAFleet', DIPDVD => 'DIPDVD', TAKEHOME=>'TakeHome', SS=>'SellerServer', AARP => 'AARP', AARP_CLASSROOM => 'AARPClassroom',USI_ONLINE=>'USIOnline', AAADIP => 'AAADIP', FLEET_CA => 'FleetCA', AARP_VOLUNTEER => 'AARPVolunteer', DSMSBTW => 'DSMSBTW', AAATEEN => 'AAATeen',  AAA_SENIORS => 'AAASeniors', DRIVERSED => 'DriversEd', EDRIVING =>'EDriving'},
            CERTIFICATE_MODULE => {  DIP => 
					{
					DEFAULT =>'California',
					35003 => 'AAA',
					35004 => 'AAA',
					35005 => 'AAA',
					35006 => 'AAA',
					41008 => 'AAA',
					26004 => 'AAA',
					1003  => 'Texas',
					1011  => 'Texas',
					1001  => 'Texas',
					1015  => 'Texas',
					1007  => 'Texas',
					1006  => 'Texas',
					40004 => 'NewYork',
					40005 => 'NewYork',
					},
				     TEEN =>
					{
						DEFAULT => 'Teen',
						5001    => 'CATeen',
						5002    => 'CATeen',
						5003    => 'CATeen',
						6001    => 'COTeen',
						6002    => 'COTeen',
						44003   => 'TXTeen',
						44006   => 'TXTeen32',
						44007   => 'TXTeen32',
						39002   => 'PATeen',
						16003   => 'INTeen',
					},
				     AAATEEN =>
					{
						DEFAULT => 'AAATeen',
						5002    => 'AAACATeen',
                                             	5013    => 'AAACATeen',
					},
				     MATURE => 
					{
						DEFAULT => 'MatureCertificate',
						200005  => 'CAMature',
						400005  => 'CAMature',
						100005  => 'CAMature',
                                        },
				     FLEET => 
					{
						DEFAULT => 'FleetCertificate',
					},
				     CLASSROOM => 
					{
						DEFAULT => 'Texas',
						1008 => 'California',
						1009 => 'California',
						1005 => 'Texas',
						1009 => 'Texas',
						1007 => 'Texas',
                                        },
				     TSTG => 
					{
						DEFAULT => 'TSTGCertificate',
					},
				     AZTS => 
					{
						DEFAULT => 'AZTSCertificate',
					},
				     CLASS =>  	 
                                         { 	 
                                                 DEFAULT => 'NewYork', 	 
                                         },
				     AHST => 
					{
						DEFAULT => 'AHSTCertificate',
					},
				     HTS => 
					{
						DEFAULT => 'HTSCertificate',
					},
			             DSMS =>     
					{
						DEFAULT => 'NewYork',
					},
			             DSMSBTW =>     
					{
						DEFAULT => 'CADSMS',##For now, both modules names are same(Monday, July 08 2013, Rajesh)
						'CA'	=> 'CADSMS',
					},
				     ADULT =>
					{
						DEFAULT => 'TXAdult',
					},
				     AAAFLEET => 
					{
						DEFAULT => 'AAAFleetCertificate',
					},
				     AAADIP => 
					{
						DEFAULT => 'AAADIPCertificate',
					},
				     CAAFLEET =>
					{
						DEFAULT => 'CAAFleetCertificate',
					},
				     DIPDVD => 
					{
						DEFAULT => 'NewYork',
					},
				      TAKEHOME => 
                                        {
                                        	DEFAULT =>'California',
                                        	1011  => 'Texas',
                                        	40004 => 'NewYork',
					},
				      USI_ONLINE => 
                                        {
                                        	DEFAULT =>'California',
                                        	40004 => 'NewYork',
					},
				      SS => 
                                        {
                                        	DEFAULT =>'SellerServer',
                                        	1021  => 'SellerServerTABC',
                                        	1022  => 'SellerServerTABC',
                                        	1023  => 'SellerServerTABC',
                                        	1024  => 'SellerServerTABC',
                                        	40005 => 'SellerServerNY',
                                        	40006 => 'SellerServerNY',
					},
					AARP =>
                                        {
                                                DEFAULT =>'AARP',
						33011 => 'AARPNY',
                                                33001 =>'AARPNY',
						48011  =>'AARPVA',
                                                48001  =>'AARPVA',
						5011 => 'AARPCA',
						5001 => 'AARPCA',
						5012 => 'AARPCA',
						5002 => 'AARPCA',
						5003 => 'AARPCA',
                                        },
					AARP_CLASSROOM =>
                                        {
                                                DEFAULT =>'AARPNYClassroom',
                                        },
					AARP_VOLUNTEER =>
                                        {
                                                DEFAULT =>'AARPVolunteerCertificate',
                                        },
				     FLEET_CA => 
					{
						DEFAULT => 'CAFleetCertificate',
					},
				     AAA_SENIORS =>
					{
						DEFAULT => 'AAASeniors',
						5002	=> 'AAACASeniors',
					},
				     DRIVERSED =>
					{
						DEFAULT => 'DETXAdult',
						C0000013 => 'DECOTeen',
						C0000057 => 'DENVTeen',
						C0000034 => 'DECATeen',
						C0000055 => 'DECAMature',
						C0000061 => 'DEMatureCertificate',
						C0000023 => 'DENVTeen',
						C0000018 => 'DEDIP',
						C0000056 => 'DENVTeen',
						C0000022 => 'DEDIP',
						C0000025 => 'DENVTeen',
						C0000053 => 'DENVTeen',
						C0000022_VA => 'DENVTeen',
						C0000020 => 'DETexas',
						C0000067 => 'DEOHTeen',
						C0000071 => 'DETXTeen32',
						BTWTMINI03 => 'DEBTWTXTeen32',
						BTWTMINI03_I => 'DEBTWTXTeen32Insurance',
					},
				},
					
	    NOTARYCOURSES =>{
				 DIP => {1001 => 1,1002 => 1,1003 => 1, 1004 => 1, 1005 => 1, 1006 => 1, 1011 => 1, 1015=>1},
				 TAKEHOME => {1011 => 1},
			    },
	    NOPRINTFORRETURNMAIL => {
				 	DIP 	 =>	{1011 => 1,1015 => 1, 1006=>1},
				 	TAKEHOME => 	{1011 => 1},
				 	CLASSROOM=> 	{1007 => 1, 1005=>1},
				 	MATURE	 => 	{200005 => 1, 400005=>1},
				 	TEEN	 => 	{44003 => 1, 5002=>1, 5003=>1},
				 	AAATEEN	 => 	{5002=>1,5013=>1},
				 	SS	 => 	{1021 =>1, 1022=> 1, 1023 => 1, 1024 =>1},
				 	ADULT	 => 	{44007 =>1, 44006=>1,44004=>1},
				 	AARP	 => 	{5001 =>1, 5002=>1, 5003=>1,5011 =>1, 5012=>1},
				 	AAA_SENIORS => 	{5002 => 1},

				    },
	    WORKBOOKCOURSES =>{
				 AHST => {90011 => 1,90012 => 1,90013 => 1, 90014 => 1, 90015 => 1, 90016 => 1, 90017 => 1, 90018},
				 HTS  => {80011 => 1,80012 => 1,80013 => 1, 80014 => 1, 80015 => 1, 80016 => 1, 80017 => 1, 80018},
			    },
	    PREMIUMDELIVERY => {
				 DIP    => { 2 => 1007, 7 => 1006, 11 => 1004 ,22=>1036, 23=>1037},
				 MATURE => { 2 => 1001, 7 => 1003, 11 => 1004 },
				 TSTG   => { 2 => 1007, 7 => 1006, 11 => 1004 },
				 AZTS   => { 2 => 1007, 7 => 1006, 11 => 1004 },
				 TEEN   => { 2 => 1001, 3 => 1002, 4 => 1003 },
				 AAATEEN   => { 2 => 1001, 3 => 1002, 4 => 1003 },
				 AHST   => { 2 => 1007, 7 => 1006, 11 => 1004 },
				 HTS    => { 2 => 1007, 7 => 1006, 11 => 1004 },
				 ADULT  => { 2 => 1012, 7 => 1011, 11 => 1013 },
				 AAADIP  => { 2 => 1012, 7 => 1011, 11 => 1013 },	
				 TAKEHOME  => { 2 => 1012, 7 => 1011, 11 => 1013 },	
				 USI_ONLINE  => { 2 => 1012, 7 => 1011, 11 => 1013 },	
				 SS        => { 2 => 1012, 7 => 1011, 11 => 1013 },	
				 AARP	=> { 5 => 1015, 4 => 1014, 6 => 1016 },
				 AARP_CLASSROOM => { 5 => 1015, 4 => 1014, 6 => 1016 },
				 AAA_SENIORS   => { 2 => 1001, 3 => 1002, 4 => 1003 },
				 DRIVERSED => { 2 => 1007, 7 => 1006, 11 => 1004 ,22=>1036, 23=>1037, 26 => 1000},
			       },
	    DELIVERYMAP    => {
				TEEN =>      { 2 => 7, 3 => 2, 4 => 11 },
				AAATEEN =>      { 2 => 7, 3 => 2, 4 => 11 },
				#MATURE =>    { 2 => 7, 3 => 2, 4 => 11 },
				CLASSROOM => { 104 => 7, 101 => 2, 102 => 11 },
				CLASS     => { 104 => 7, 101 => 2, 102 => 11 },
				DSMS      => { 101 => 2, 1000 => 7, 1001 => 2, 1002 => 7, 1003 => 2, 1004 => 11, 1002 => 51 }, ##51: FEDEX_GROUND
				AARP	 => { 4 => 7, 5 => 2, 6 => 11 , 2 =>12 }, 
				AARP_CLASSROOM => { 4 => 7, 5 => 2, 6 => 11 }, 
				AAA_SENIORS =>      { 2 => 7, 3 => 2, 4 => 11 },
			      },
	    EMAIL_DELIVERY_ID => {
				 DIP     => {12=>1},
				 TSTG    => {12=>1},
				 AZTS    => {12=>1},
				 TEEN    => {12=>1},
				 AAATEEN => {12=>1},
				 AHST    => {12=>1},
				 HTS     => {12=>1},
				 AAADIP  => {12=>1},
				 TAKEHOME  => {12=>1},
				 SS  => {12=>1,23=>1},
				AARP	 => {2 =>1},
				AARP_VOLUNTEER	 => {2 =>1},
				 ADULT  => {12=>1},
				},
	    FAXCOURSE =>{
				 DIP => {},
				 FLEET => {55010 => 1,55011=>1,55013 => 1,55014=>1 },

			},
	    DOWNLOADCOURSE =>{
				 DRIVERSED => { C0000063 => 1},

			},
	    RGLPRINTLABELCOURSE =>{

					TEEN => {44003 => 1},
					DRIVERSED => {C0000034 => 1, C0000020 => 1, C0000013 => 1, C0000067 => 1},
					MATURECA => {C0000055 => 1},##To check for coverhseet lable printing for DE CA Mature
				},
	    THIRDPARTYCERTIFICATE =>{
					TEEN => {11003 => 1},
				},
	    CERT_MSG_TOP=>{
				DIP => {
						30003 => 'OFFICIAL COPY',
						26004 => 'INSURANCE COPY',
						20001 => 'INSURANCE COPY',
						2014  => 'INSURANCE COPY',
					    	39004 => 'INSURANCE COPY',
					    	14005 => ' ',
						1013  => ' ',
						COUPON => {
								'CEMAID' => {
										13001 => 'INSURANCE COPY',
									    },
							 },
				       },
				TEEN =>{
						44002 => 'DPS COPY',
						39002 => 'OFFICIAL COPY',
				       },
				MATURE =>{	
						100010 => 'INSURANCE COPY',
						100048 => 'INSURANCE COPY',
					 },
				FLEET =>{
						55012 => 'INSURANCE COPY',
				       },
				AAADIP =>{
                                                42004 => 'INSURANCE COPY',
                                       },
				DRIVERSED =>{
                                                2201 => 'INSURANCE COPY',
                                                21001 => 'INSURANCE COPY',
                                                23001 => 'INSURANCE COPY',
                                                1001 => 'INSURANCE COPY',
                                                37001 => 'INSURANCE COPY',
                                       },
			 },
	    CERT_MSG_BOTTOM=>{
				DIP  => {
						26004 => 'STUDENT COPY',
						20001 => 'STUDENT COPY',
						15005 => 'INSURANCE COPY',
					}, 
				TEEN =>{
						44002 => 'STUDENT COPY',
						39002 => 'STUDENT COPY',
				       },
				MATURE =>{	
						100010 => 'STUDENT COPY',
						100048 => 'STUDENT COPY',
					 },
				FLEET =>{
						55012 => 'STUDENT COPY',
				       },
				DRIVERSED =>{
                                                21001 => 'STUDENT COPY',
                                                23001 => 'STUDENT COPY',
                                                1001 => 'STUDENT COPY',
                                                37001 => 'STUDENT COPY',
                                       },
			 },
	    STCPRINTCOVER_REGS    => { 
					 'DIP' =>{ 67 => 1},				
					 'TSTG'=>{ 67 => 1},				
					 'AHST'=>{ 67 => 1},				
					 'HST' =>{ 67 => 1},				
					 'TAKEHOME' =>{ 67 => 1},				
		                     },
	    REGULATORMAP	=> {
					105995	 =>	140,
					105979	 =>	144,
					105977	 =>	142,
					105976	 =>	143,
					105975	 =>	141,
					105972	 =>	143,
					105970	 =>	143,
					105969	 =>	144,
					105968	 =>	140,
					105967	 =>	143,
					105938	=>	101939,
					105939	=>	61,
					105940	=>	78,
					105941	=>	64,
					105942	=>	80,
					105943	=>	74,
					105944	=>	71,
					105945	=>	88,
					105946	=>	61,
					105947	=>	77,
					105948	=>	60,
					105949	=>	81,
					105950	=>	273,
					105951	=>	88,
					105952	=>	84,
					105953	=>	61,
				   },

	    OCPSCOURSE =>   {
				DIP       => {1006 => 1},
				CLASSROOM => {1005 => 1},
	
			    },
	    CLASSROOMCOURSE         => { 1005 => 'TX',  1007 => 'TX', 1008 => 'CA',1009 => 'CA'},

	    FAX_SERVER              => { HOST => '172.20.2.215', PWD => 'ids', USER => 'ids'},

	    FEDEXKINKOS         =>      { DIP => {
						NONTX =>{FL => 1, VA =>1, NC=>1, NY =>1},
						 },
					 TAKEHOME => {
                                                NONTX =>{FL => 1, VA =>1, NC=>1, NY =>1},
                                                 },
					},

	    NISNTSACOURSE           => {
					DIP => {
						15 =>1,16=>1,25=>1,26=>1,
						},
					TSTG =>{
						60004=>1, 60005=>1,
						},
					AHST =>{
						90002=>1, 90003=>1,90006=>1, 90007=>1,90012=>1, 90013=>1,90016=>1, 90017=>1,
						},
					HTS =>{
						80002=>1, 80003=>1,80006=>1, 80007=>1,80012=>1, 80013=>1,80016=>1, 80017=>1,
						},
					},
	   SIGNATUREURL             => {
						DIP => 'http://crm.idrivesafely.com/userdocs/dip/SIGNATURE',
				       },
	   CRMURL             => {
						DIP => 'http://crm.idrivesafely.com',
						NEW => 'http://crmnew.idrivesafely.com'
				       },
	   DRIVERSED_CONSTRAINTS => {
					PARAMETERS => {
							DEFAULT => {
									SCHOOLID =>'DRVEDCA', COURSEID =>'C0000063'
								   },
							COURSEID_SCHOOLS => {
								C0000018 => 'WTS',
								C0000023_NM => 'WTS',
								C0000022 => 'WTS',
								C0000022_VA => 'DRVEDCA',
								C0000020 => 'WTS',
								C0000025_MI => 'WTS',
							},							
						     },
					HOST	=> {
							PROD => 'ids-gateway.driversed.com', 
							BETA => 'ids-gateway.driversed.com'},
					URL     => {    
							PROD => 'http://ids-gateway.driversed.com/Certificates/WaitingToBePrinted.svc',
							BETA => 'http://ids-gateway.driversed.com/beta/Certificates/WaitingToBePrinted.svc',
							
							PROD_GET_OH_CERTIFICATES => 'http://ids-gateway.driversed.com/Certificates/PDFCertificatesService.ashx',
							BETA_GET_OH_CERTIFICATES => 'http://ids-gateway.driversed.com/beta/Certificates/PDFCertificatesService.ashx',
						    },
				  },
	   DRIVERSED_DELIVERY_METHOD => {
						RMS=> 1, CMS => 23, FE3STX => 26 , FE3S => 26, FESTX  => 11, FES=> 11, FES2D => 7, FESON => 2, FESONM => 11, RMSTRAC => 24,
					},
	   DRIVERSED_COURSE_MAPPING  => {
						'C0000063' => 44006,
						'C0000013' => 6001,
						'C0000057' => 34001,
						'C0000034' => 5001,
						'C0000055' => 200005,
						'C0000061' => 6100,
						'C0000023' => 23001,
						'C0000018' => 7001,
						'C0000056' => 1001,
						'C0000022' => 2201,
						'C0000025' => 37001,
						'C0000053' => 21001,
						'C0000022_VA' => 46002,
						'C0000020' => 411003,
						'C0000067' => 4136002,
						'C0000071' => 244007,
						'BTWTMINI03' => 244007,
						'BTWTMINI03_I' => 344007,
					},
	   DRIVERSED_COURSES         => {
						'TXADULT' => {
								C0000063 => 1,
							     },
						'COTEEN' => {
								C0000013 => 1,
							     },
						'NVTEEN' => {
								C0000057 => 1,
							     },
						'CATEEN' => {
								C0000034 => 1,
							     },
						'CAMATURE' => {
								C0000055 => 1,
							     },
						'COMATURE' => {
								C0000061 => 1,
							     },
						'MNTEEN' => {
								C0000023 => 1,
							     },
						'NVDIP' => {
								C0000018 => 1,
							     },
						'AZTEEN' => {
								C0000056 => 1,
							     },
						'NMDIP' => {
								C0000023_NM => 1,
							     },
						'NJDIP' => {
								C0000022 => 1,
							     },
						'OKTEEN' => {
								C0000025 => 1,
							     },
						'HSCTEEN' => {
								C0000053 => 1,
							     },
						'VATEEN' => {
								C0000022_VA => 1,
							     },
						'TXDIP' => {
								C0000020 => 1,
							     },
						'OHTEEN' => {
								C0000067 => 1,
							     },
						'TXTEEN' => {
								C0000071 => 1,
							     },
						'TXTEENBTWTRANSFER' => {
								BTWTMINI03 => 1,
							     },
						'TXTEENBTWTRANSFER_INSURANCE' => {
								BTWTMINI03_I => 1,
							     },
					},
	   DRIVERSED_BTW_OFFERED_STATES => { CA=>1 },
	   TEEN_PA_COURSE_PRINT_AFFILIATE_EXCLUDE => '386,397,530,251',
						
	    TEMPLATESPATH => $printerSite::SITE_TEMPLATES_PATH,
	    OH_NONRESIDENT_FAXNUMBER => '16147524748',
  	   # OH_NONRESIDENT_FAXNUMBER => '17607443072',

	    MONTH_NUM   => { 'JAN' => '01', 'FEB' => '02', 'MAR' => '03', 'APR' => '04', 'MAY' => '05', 'JUN' => '06',
                 'JUL' => '07', 'AUG' => '08', 'SEP' => '09', 'OCT' => '10', 'NOV' => '11', 'DEC' => '12' },

					
			     
	    DBCONNECTION => { 
				DIP => {
						DBNAME   => $printerSite::DIP_DATABASE,
						USER     => $printerSite::DIP_DATABASE_USER,
						PASSWORD => $printerSite::DIP_DATABASE_PASSWORD,
						HOST     => $printerSite::DIP_DATABASE_HOST,
						ORACLEDB => 0,
				       },
				TSTG => {
						DBNAME   => $printerSite::TSTG_DATABASE,
						USER     => $printerSite::TSTG_DATABASE_USER,
						PASSWORD => $printerSite::TSTG_DATABASE_PASSWORD,
						HOST     => $printerSite::TSTG_DATABASE_HOST,
						ORACLEDB => 0,
				       },
				AZTS => {
						DBNAME   => $printerSite::AZTS_DATABASE,
						USER     => $printerSite::AZTS_DATABASE_USER,
						PASSWORD => $printerSite::AZTS_DATABASE_PASSWORD,
						HOST     => $printerSite::AZTS_DATABASE_HOST,
						ORACLEDB => 0,
				       },
				TEEN => {
						DBNAME   => $printerSite::TEEN_DATABASE,
						USER     => $printerSite::TEEN_DATABASE_USER,
						PASSWORD => $printerSite::TEEN_DATABASE_PASSWORD,
						HOST     => $printerSite::TEEN_DATABASE_HOST,
						ORACLEDB => 0,
				       },
				AAATEEN => {
						DBNAME   => $printerSite::AAATEEN_DATABASE,
						USER     => $printerSite::AAATEEN_DATABASE_USER,
						PASSWORD => $printerSite::AAATEEN_DATABASE_PASSWORD,
						HOST     => $printerSite::AAATEEN_DATABASE_HOST,
						ORACLEDB => 0,
				       },
				FLEET => {
						DBNAME   => $printerSite::FLEET_DATABASE,
						USER     => $printerSite::FLEET_DATABASE_USER,
						PASSWORD => $printerSite::FLEET_DATABASE_PASSWORD,
						HOST     => $printerSite::FLEET_DATABASE_HOST,
						ORACLEDB => 0,
				       },
				CLASSROOM => {
						DBNAME   => $printerSite::CLASSROOM_DATABASE,
						USER     => $printerSite::CLASSROOM_DATABASE_USER,
						PASSWORD => $printerSite::CLASSROOM_DATABASE_PASSWORD,
						HOST     => $printerSite::CLASSROOM_DATABASE_HOST,
						ORACLEDB => 0,
				       },
				CRMDB => {
						DBNAME   => $printerSite::CRM_DATABASE,
						USER     => $printerSite::CRM_DATABASE_USER,
						PASSWORD => $printerSite::CRM_DATABASE_PASSWORD,
						HOST     => $printerSite::CRM_DATABASE_HOST,
						ORACLEDB => 0,
				       },
				CLASS => {  	 
                                                 DBNAME   => $printerSite::CLASS_DATABASE, 	 
                                                 USER     => $printerSite::CLASS_DATABASE_USER, 	 
                                                 PASSWORD => $printerSite::CLASS_DATABASE_PASSWORD, 	 
                                                 HOST     => $printerSite::CLASS_DATABASE_HOST, 	 
                                                 ORACLEDB => 0, 	 
  	 
                                         },
				AHST => {
						DBNAME   => $printerSite::AHST_DATABASE,
						USER     => $printerSite::AHST_DATABASE_USER,
						PASSWORD => $printerSite::AHST_DATABASE_PASSWORD,
						HOST     => $printerSite::AHST_DATABASE_HOST,
						ORACLEDB => 0,
				       },
				HTS => {
						DBNAME   => $printerSite::HTS_DATABASE,
						USER     => $printerSite::HTS_DATABASE_USER,
						PASSWORD => $printerSite::HTS_DATABASE_PASSWORD,
						HOST     => $printerSite::HTS_DATABASE_HOST,
						ORACLEDB => 0,
				       },
				DSMS => {
						DBNAME   => $printerSite::DSMS_DATABASE,
  	                                        USER     => $printerSite::DSMS_DATABASE_USER,
  	                                        PASSWORD => $printerSite::DSMS_DATABASE_PASSWORD,
  	                                        HOST     => $printerSite::DSMS_DATABASE_HOST,
  	                                        ORACLEDB => 0,
					},
				DSMSBTW => {
						DBNAME   => $printerSite::DSMS_DATABASE,
  	                                        USER     => $printerSite::DSMS_DATABASE_USER,
  	                                        PASSWORD => $printerSite::DSMS_DATABASE_PASSWORD,
  	                                        HOST     => $printerSite::DSMS_DATABASE_HOST,
  	                                        ORACLEDB => 0,
					},
				ADULT => {
						DBNAME   => $printerSite::ADULT_DATABASE,
						USER     => $printerSite::ADULT_DATABASE_USER,
						PASSWORD => $printerSite::ADULT_DATABASE_PASSWORD,
						HOST     => $printerSite::ADULT_DATABASE_HOST,
						ORACLEDB => 0,
				       },
				AAAFLEET => {
						DBNAME   => $printerSite::AAAFLEET_DATABASE,
						USER     => $printerSite::AAAFLEET_DATABASE_USER,
						PASSWORD => $printerSite::AAAFLEET_DATABASE_PASSWORD,
						HOST     => $printerSite::AAAFLEET_DATABASE_HOST,
						ORACLEDB => 0,
				},
				AAADIP => {
						DBNAME   => $printerSite::AAADIP_DATABASE,
						USER     => $printerSite::AAADIP_DATABASE_USER,
						PASSWORD => $printerSite::AAADIP_DATABASE_PASSWORD,
						HOST     => $printerSite::AAADIP_DATABASE_HOST,
						ORACLEDB => 0,
				},
				CAAFLEET => {
                                                DBNAME   => $printerSite::CAAFLEET_DATABASE,
                                                USER     => $printerSite::CAAFLEET_DATABASE_USER,
                                                PASSWORD => $printerSite::CAAFLEET_DATABASE_PASSWORD,
                                                HOST     => $printerSite::CAAFLEET_DATABASE_HOST,
                                                ORACLEDB => 0,
                                },
				DIPDVD => {
                                                DBNAME   => $printerSite::DIPDVD_DATABASE,
                                                USER     => $printerSite::DIPDVD_DATABASE_USER,
                                                PASSWORD => $printerSite::DIPDVD_DATABASE_PASSWORD,
                                                ORACLEDB => 0,
						STOREPROCEDUREDB => 1,
                                },
				TAKEHOME => {
						DBNAME   => $printerSite::TAKEHOME_DATABASE,
						USER     => $printerSite::TAKEHOME_DATABASE_USER,
						PASSWORD => $printerSite::TAKEHOME_DATABASE_PASSWORD,
						HOST     => $printerSite::TAKEHOME_DATABASE_HOST,
						ORACLEDB => 0,
				},
				SS => {
						DBNAME   => $printerSite::TAKEHOME_DATABASE,
						USER     => $printerSite::TAKEHOME_DATABASE_USER,
						PASSWORD => $printerSite::TAKEHOME_DATABASE_PASSWORD,
						HOST     => $printerSite::TAKEHOME_DATABASE_HOST,
						ORACLEDB => 0,
				},
				AARP => {
                                                DBNAME   => $printerSite::AARP_DATABASE,
                                                USER     => $printerSite::AARP_DATABASE_USER,
                                                PASSWORD => $printerSite::AARP_DATABASE_PASSWORD,
                                                HOST     => $printerSite::AARP_DATABASE_HOST,
                                                ORACLEDB => 0,
                                },
				AARP_CLASSROOM => {
                                                DBNAME   => $printerSite::AARP_CLASSROOM_DATABASE,
                                                USER     => $printerSite::AARP_CLASSROOM_DATABASE_USER,
                                                PASSWORD => $printerSite::AARP_CLASSROOM_DATABASE_PASSWORD,
                                                HOST     => $printerSite::AARP_CLASSROOM_DATABASE_HOST,
                                                ORACLEDB => 0,
                                },
				AARP_VOLUNTEER => {
                                                DBNAME   => $printerSite::AARP_VOLUNTEER_DATABASE,
                                                USER     => $printerSite::AARP_VOLUNTEER_DATABASE_USER,
                                                PASSWORD => $printerSite::AARP_VOLUNTEER_DATABASE_PASSWORD,
                                                HOST     => $printerSite::AARP_VOLUNTEER_DATABASE_HOST,
                                                ORACLEDB => 0,
				},
                                USI_ONLINE => {
                                                DBNAME   => $printerSite::USI_ONLINE_DATABASE,
                                                USER     => $printerSite::USI_ONLINE_DATABASE_USER,
                                                PASSWORD => $printerSite::USI_ONLINE_DATABASE_PASSWORD,
                                                HOST     => $printerSite::USI_ONLINE_DATABASE_HOST,
                                                ORACLEDB => 0,
                                },
				FLEET_CA => {
						DBNAME   => $printerSite::FLEET_CA_DATABASE,
						USER     => $printerSite::FLEET_CA_DATABASE_USER,
						PASSWORD => $printerSite::FLEET_CA_DATABASE_PASSWORD,
						HOST     => $printerSite::FLEET_CA_DATABASE_HOST,
				},
				AAA_SENIORS => {
						DBNAME   => $printerSite::AAA_SENIORS_DATABASE,
						USER     => $printerSite::AAA_SENIORS_DATABASE_USER,
						PASSWORD => $printerSite::AAA_SENIORS_DATABASE_PASSWORD,
						HOST     => $printerSite::AAA_SENIORS_DATABASE_HOST,
						ORACLEDB => 0,
				       },
                                DRIVERSED => {
                                                DBNAME   => $printerSite::DRIVERSED_DATABASE,
                                                USER     => $printerSite::DRIVERSED_DATABASE_USER,
                                                PASSWORD => $printerSite::DRIVERSED_DATABASE_PASSWORD,
                                                HOST     => $printerSite::DRIVERSED_DATABASE_HOST,
                                                ORACLEDB => 0,
                                       },
                                EDRIVING => {
                                                DBNAME   => $printerSite::EDRIVING_DATABASE,
                                                USER     => $printerSite::EDRIVING_DATABASE_USER,
                                                PASSWORD => $printerSite::EDRIVING_DATABASE_PASSWORD,
                                                HOST     => $printerSite::EDRIVING_DATABASE_HOST,
                                                ORACLEDB => 0,
                                       },


			    },

	    CTSI_SUBMISSION_ERRORS => { 'casenumber' => 'Invalid Case Number',
		                        'courtid' => 'Invalid Court Id',
					'certificateduedate' => 'Invalid Due Date',
					'completiondate' => 'Invalid Completion Date',
					'defendantlastname' => 'Please correct your Last Name',
					'defendantfirstname' => 'Please correct your First Name',
					'defendantdlnumber' => 'Invalid Driver\'s License',
					'defendantdlstate' => 'Invalid DL State',
					'defendantdob' => 'Invalid Date of Birth',
					'defendantaddress' => 'Invalid Address',
					'defendantcity' => 'Invalid City',
					'defendantstate' => 'Invalid State',
					'defendantzip' => 'Invalid Zip Code',
					'defendantemail' => 'Invalid Email',
					'defendantphone' => 'Invalid Phone Number',
				      },	 		    
	    LA_CERT_COURSE_DESC    => {  
                              		AHST    => { 	90001 => 'English Internet',
							90002 => 'English Internet',
							90003 => 'English Internet',
							90004 => 'English Internet',
							90005 => 'Spanish Internet',
							90006 => 'Spanish Internet',
							90007 => 'Spanish Internet',
							90008 => 'Spanish Internet',
							90011 => 'English Workbook',
							90012 => 'English Workbook',
							90013 => 'English Workbook',
							90014 => 'English Workbook',
							90015 => 'Spanish Workbook',
							90016 => 'Spanish Workbook',
							90017 => 'Spanish Workbook',
							90018 => 'Spanish Workbook',
						   },
                              		HTS     => {    80001 => 'English Internet',
                                                        80002 => 'English Internet',
                                                        80003 => 'English Internet',
                                                        80004 => 'English Internet',
                                                        80005 => 'Spanish Internet',
                                                        80006 => 'Spanish Internet',
                                                        80007 => 'Spanish Internet',
                                                        80008 => 'Spanish Internet',
                                                        80011 => 'English Workbook',
                                                        80012 => 'English Workbook',
                                                        80013 => 'English Workbook',
                                                        80014 => 'English Workbook',
                                                        80015 => 'Spanish Workbook',
                                                        80016 => 'Spanish Workbook',
                                                        80017 => 'Spanish Workbook',
                                                        80018 => 'Spanish Workbook',
 
						   },
                           },
	   UPSELLCUSTOMS => {2117=>1,2118=>2,2119=>3},		   
	   UPSELLTYPES	=> {
		   	DOWNLOAD=>2117,
			EMAIL=>2118,
			MAIL=>2119,
		   	DOWNLOAD1=>5240,
			EMAIL1=>5243,
			MAIL1=>5242,

			MAILOVA=>2156, ##For Variation - IDSUIUX-243, for FEDED OVA for POC
		},
	   NCCOURSEAAACOUNTIES => {24112=>1, 23959=> 1, 94800=> 1 },
	   TEEN_COLORADO_COURSES => { 6001=>'COTeen', 6002=>'COTeen' },
	   INDIANA_FLASHCOURSE => { 25005=>1, 25006=>1 },
	   NEVADACOURSES => { 7003=>1, 7004=>1, 7005=>1, 7006=>1},
           KENTUCKY_FLASHCOURSE	=> 27005,
           TAKEHOME_KENTUCKY_FLASHCOURSE	=> 27004,
	   WEST_COAST_STATES => { FC=>1},
	   RHS_ADDRESS_STATES => { SC => 1, ME =>1 },
	   CERT_ORDERS_MAP	=> { 'RED_CERT' => 2, 'BLUE_CERT' => 3, 'FEDEX' => 15, 'TXADULT_CERT' => 45, 'CATEEN_CERT' => 10, 'CAMATURE_CERT' => '11', 'TX_DIP' => 4 , 'TX_OCPS' => 5, 'FL_BDI' => 7, 'FL_BDI_CO' => 8, 'NM_DIP' =>9, 'FL_TEEN_TLSAE' => 17,'TX_TAKEHOME' => 31 , 'TX_SS'=>32, 'CAAARP_CERT' => 30 ,'TX_ADULT'=>46,'CATEEN_CERT'=>47, 'TX_TEEN'=>48, 'COTEEN_CERT' => 49 , 'USPS' => 50, DE_TX_ADULT => 51, 'TX_TEEN32'=>52},
	   WHITE_PAPER_CERTS	=> { 
					TEEN => { 'CO' => 1 },
				},
	   ORDERING_COURSE_ITEM_MAPS => { 
	   					'TX' => { 1011=>1, 1012=>1, 1015=>1},
						'TX_OCPS' => { 1006=>1},
						'FL_BDI' => { 2011 =>1 ,2031 =>1},
						'FL_BDI_CO' => { 2012=>1, 2032=>1},
						'NM_DIP' => { 5003 =>1, 5004=>1, 5005=>1, 5006=>1},
						'TX_TAKEHOME' => {1011=>1},
						'TX_TEEN' => {44003=>1},
						'TX_SS' => {1021=>1},
						'TX_ADULT' => {44004=>1, 44005=>1, 44006=>1, 44007=>1},
						'DE_TX_ADULT' => {C0000063 => 1},
						'DE_TX_DIP' => {C0000020 => 1},
                                                'TX_TEEN32' => {44006 => 1, 44007=>1}, 
					},	
	   FLTEENTLSAECOURSE => { 10006 => 1,10007 => 1, 10009 => 1, 10010 => 1 },
	   OKLAHOMA_CITY_COURT	=> 106001,
	   TAKEHOME_INDIANA_FLASHCOURSE => { 25005=>1, 25006=>1 },
	   AAA_ERS_MODULE_COURSES  => { 66033=>1, 66034=>1, 66035=>1, 66036=>1 },
	   SS_TABC_COURSES  => { 1021=>1, 1022=>1, 1023=>1, 1024=>1 },
	   INSTRUCTORINFO => {
		'Sunday' => {'TEMPLATE'=>'SS_TABC_Template_Louis.pdf'},
		'Monday' => {'TEMPLATE'=>'SS_TABC_Template_Rebecca.pdf'},
		'Tuesday' => {'TEMPLATE'=>'SS_TABC_Template_Rebecca.pdf'},
		'Wednesday' => {'TEMPLATE'=>'SS_TABC_Template_Formeco.pdf'},
		'Thursday' => {'TEMPLATE'=>'SS_TABC_Template_Formeco.pdf'},
		'Friday' => {'TEMPLATE'=>'SS_TABC_Template_Louis.pdf'},
		'Saturday' => {'TEMPLATE'=>'SS_TABC_Template_Rebecca.pdf'},
	},
	DE_TX_TEEN32_COC_REASONS  => { 'DEDS'=>1, 'OTHERDS' => '1', 'PARENTTAUGHTOPT' => 1, 'PARENTTAUGHTCOURSE' => 1, INSURANCE => 1 },
	TEEN_VA_DISTRICT8_ZIPCODES => '22205, 22213, 20190, 22182, 22042, 22181, 22035, 20181, 20152, 20141, 20109, 22191, 22306, 22153, 22315, 22030, 22032, 22308, 22311, 22027, 20148, 20164, 20180, 20110, 20143, 22314, 20135, 22309, 22066, 22134, 22203, 22079, 22150, 20124, 20170, 22046, 22312, 22307, 22302, 22304, 22185, 20176, 20197, 20165, 22026, 22192, 22201, 22209, 20151, 22043, 22310, 22015, 22041, 22031, 20117, 20175, 22125, 22305, 22211, 22204, 22207, 22124, 22033, 20191, 22180, 20171, 22003, 22102, 20194, 22039, 20137, 20118, 22025, 22193, 20169, 22301, 22206, 22101, 22214, 22303, 22060, 20184, 20132, 20105, 20111, 22202, 20120, 20121, 22151, 22044, 22152, 20166, 20147, 20158, 20129, 20155, 20112, 20136, 22172',
	NEW_EMAIL_POC_STATES	=> { 
		'DIP' => {'MI' => 1, },
		'TEEN' => { 'FL' => 1,},
	},
	CERTIFICATE_ON_WHITE_PAPER => {
		1 => {
			1011 =>1, 1006=>1, 1015 =>1,
		},
		25 =>{
			1011=>1, 
		},
		5 =>{
			1005=>1, 1007=>1,
		},
	},


        };

	bless ($self, $class);

	return $self;
}

##### Create accessor methods.  Unfortunately perl does not support 
##### private methods like other OOP languages, but we can always fake
##### them

=pod

=head2 getCourseAggregateOverride

=cut

sub getCourseAggregateOverride
{
    my $self = shift;
    my ($courseId,$product) = @_;
    return $self->{COURSE_AGGREGATE_OVERRIDE}->{$product}->{$courseId};
}

=pod

=head2 getNoPrintCertProcessingId

Get all cert processing ids which will not print

=cut

sub getNoPrintCertProcessingId
{
    my $self = shift;
    return $self->{NO_PRINT_CERT_PROCESSING_ID};
}

=pod

=head2 getFedex

Get a particular Fedex Account / Meter number.  If no id is passed in, default to DIP

=cut

sub getFedex
{
    my $self = shift;
    my ($id) = @_;
    if ($id){
        if(!exists $self->{FEDEX}->{$id}){
                $id='DIP';
        }
        return $self->{FEDEX}->{$id};
    }

    return  $self->{FEDEX}->{DIP};
}

sub getUSPS
{
    my $self = shift;
    my ($id) = @_;
    if ($id){
        if(!exists $self->{USPS}->{$id}){
                $id='DIP';
        }
        return $self->{USPS}->{$id};
    }

    return  $self->{USPS}->{DIP};
}

=pod

=head2 getProductId

Get the product id for CRM Reporting purposes.  If no id is passed in, default to DIP

=cut

sub getProductId
{
    my $self = shift;
    my ($id) = @_;

    if ($id)    {   return $self->{PRODUCT_ID}->{$id};  }
    return  $self->{PRODUCT_ID}->{DIP};
}


=pod

=head2 getCertPoolCourse

This function tells whether or not the course id has to be pulled from the certificate pool.  If the course needs to be pulled from the certificate pool, check to see if the course needs to be aliased for another course.  For example, course id 1003 or course 1007 is aliased to 1001 so query the database for course id 1001.  

If the course id is not to be pulled from the certificate pool, return undefined

=cut

sub getCertPoolCourse
{
    my $self = shift;
    my ($id) = @_;

    if ($id)    {   return $self->{CERT_POOL}->{$id};  }
    return  $self->{PRODUCT_ID}->{DIP};
}

=pod

=head1 getOfficeCa

Return the address of the california office in hash form:
NAME ADDRESS CITY STATE ZIP PHONE

=cut

sub getOfficeCa
{
    my $self = shift;
    my ($product,$fedexKinkos, $noPhoneNumber) = @_;
    if(!$product){
    	$product='DEFAULT';
    }
   my $officeAddress = '';
   if($fedexKinkos && $fedexKinkos eq '2') {
    	$officeAddress = $self->{OFFICE_CA}->{DEFAULT};
   } elsif($fedexKinkos && $fedexKinkos eq '1'){
        $officeAddress = $self->{OFFICE_CA}->{FDK};
   }elsif(exists $self->{OFFICE_CA}->{$product}){
	$officeAddress = $self->{OFFICE_CA}->{$product};
   }else{
    	$officeAddress = $self->{OFFICE_CA}->{DEFAULT};
   }
   if($noPhoneNumber) {
	$officeAddress->{PHONE} = '';
   }
   return $officeAddress;
}


sub getDateTimeInANSI {
        my ($sec,$min,$hour,$mday,$mon,$year) = (localtime(time()))[0,1,2,3,4,5];
        $year +=1900;
        $mon++;
        $mday=sprintf('%.2d',$mday);
        $mon=sprintf('%.2d',$mon);
        $hour=sprintf('%.2d',$hour);
        $min=sprintf('%.2d',$min);
        $sec=sprintf('%.2d',$sec);
        my $currDate="$year-$mon-$mday $hour:$min:$sec";
        return $currDate;
}
sub getDateTime {
    my @month = qw(JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC);
    my ($sec,$min,$hour,$mday,$mon,$year) = (localtime(time()))[0,1,2,3,4,5];
    $year +=1900;
    return "$mday-$month[$mon]-$year $hour:$min:$sec";
}

sub getDate {
    my($inc) = @_;
    $inc = (defined $inc) ? $inc : 0;
    my @month = qw(JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC);
    my $time = time() + 86400 * $inc;
    my ($mday,$mon,$year) = (localtime($time))[3,4,5];
    $year +=1900;
    return "$mday-$month[$mon]-$year";
}

sub getDateFormat {
    my($inc) = @_;
    $inc = (defined $inc) ? $inc : 0;
    my $time = time() + 86400 * $inc;
    my ($mday,$mon,$year) = (localtime($time))[3,4,5];
    $mon++;
    if($mon<10){
	$mon='0' . $mon;	
    }
    if($mday<10){
	$mday='0' . $mday;	
    }
    $year +=1900;
    return "$mon/$mday/$year";
}
sub pSendMail{
    my($to, $from, $subject, $message) = @_;
    my @emailList;

    if(ref($to) eq 'ARRAY'){
        @emailList = @$to;
    } else {
        push @emailList, $to;
    }

    my @validEmailList;
    for(@emailList){
        if(pValidEmail($_)){
            push @validEmailList, $_;
        }
    }

    if(@validEmailList){

        for my $email(@validEmailList){
            my $msg = MIME::Lite->new(
                                      From => 'reports@IDriveSafely.com',
                                      To => $email,
                                      Subject => $subject,
                                      Type => 'TEXT',
                                      Data => $message
                                      );
		$msg->send('sendmail', '/usr/lib/sendmail -t -oi -oem -f reports@IDriveSafely.com');
        }
        return "Email Sent to: $to<br>";
    }
    return '';
}

sub pValidEmail{
    my ($email) = @_;
    if (defined $email && length($email) > 6 && $email =~ /^.*\@.*\..*$/){
        return $email;
    }
    return undef;
}

sub getCertificateModule{
  my $self=shift;
  my ($productId,$courseId, $segmentNameMap)=@_;
        my $moduleName='California';   #### Set for Default;
        if(!$courseId){
                $courseId='DEFAULT';
        }
	if($segmentNameMap){
		$productId=$segmentNameMap;
	}
        if(exists $self->{CERTIFICATE_MODULE}->{$productId}->{$courseId}){
                $moduleName= $self->{CERTIFICATE_MODULE}->{$productId}->{$courseId}
        }elsif(exists $self->{CERTIFICATE_MODULE}->{$productId}->{DEFAULT}){
                $moduleName= $self->{CERTIFICATE_MODULE}->{$productId}->{DEFAULT}
	}
        return $moduleName;	
}

sub getPrintingDetails {
	my $self = shift;
	my ($productId,$st,$printingType)=@_;
	my $media=0;
	my $printer=0;
        if(exists $self->{PRINTERS}->{PRINTINGDATA}->{$productId}->{$st}->{$printingType}->{PRINTIERID} &&  $self->{PRINTERS}->{PRINTINGDATA}->{$productId}->{$st}->{$printingType}->{PRINTIERID}){

              my $printerId=$self->{PRINTERS}->{PRINTINGDATA}->{$productId}->{$st}->{$printingType}->{PRINTIERID};
              $printer=$self->{PRINTERS}->{$printerId}->{PRINTER_NAME};
              $media=$self->{PRINTERS}->{$printerId}->{TRAY};
        }else{
              my $printerId=$self->{PRINTERS}->{PRINTINGDATA}->{0}->{XX}->{$printingType}->{PRINTIERID};
              $printer=$self->{PRINTERS}->{$printerId}->{PRINTER_NAME};
              $media=$self->{PRINTERS}->{$printerId}->{TRAY};
        }
	return ($printer,$media);
}

sub getCertPoolCourseForUSI
{
    my $self = shift;
    my ($id) = @_;

    if ($id)    {   return $self->{CERT_POOL_USI}->{$id};  }
    return undef;
}

sub getCertPoolCourseForAdult
{
    my $self = shift;
    my ($id) = @_;

    if ($id)    {   return $self->{CERT_POOL_ADULT}->{$id};  }
    return undef;
}



sub getCertPoolCourseForDriversEd
{
    my $self = shift;
    my ($id) = @_;

    if ($id)    {   return $self->{CERT_POOL_DRIVERSED}->{$id};  }
    return undef;
}


sub getCertPoolCourseForTeen
{
    my $self = shift;
    my ($id) = @_;

    if ($id)    {   return $self->{CERT_POOL_TEEN}->{$id};  }
    return undef;
}

sub encryptId {
        my $self = shift;
        my ($val) = @_;
	if(!defined $val || !length($val)){
		return $val;
	}
	my $x = int(rand 7) + 2;
	my $y = int(rand 3) + 2;
	return $x . sprintf('%X', ($val*$x*$y)) . $y;
}

=pod

=head1 AUTHOR

hari@ed-ventures-online.com

=head1 SVN INFO

=item $URL: http://galileo/svn/PRINTING/trunk/lib/Settings.pm $

=item $Author: rajesh $

=item $Date: 2009/12/03 13:50:39 $

=item $Rev: 71 $

=cut

1;
