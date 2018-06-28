-- MySQL dump 10.10
--
-- Host: localhost    Database: printing
-- ------------------------------------------------------
-- Server version	5.0.21-standard

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `printing_attendance_reason`
--



--
-- Table structure for table `printing_course_fields`
--

DROP TABLE IF EXISTS `printing_course_fields`;
CREATE TABLE `printing_course_fields` (
  `course_id` int(11) NOT NULL,
  `field_id` int(11) NOT NULL,
  `rank` int(11) NOT NULL,
  `product_id` int(11) NOT NULL Default 1,
  PRIMARY KEY  (`course_id`,`field_id`,`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `printing_course_fields`
--


/*!40000 ALTER TABLE `printing_course_fields` DISABLE KEYS */;
LOCK TABLES `printing_course_fields` WRITE;
INSERT INTO `printing_course_fields` VALUES (1004,1,1,1),(1004,2,2,1),(1004,3,3,1),(1004,4,4,1),(1004,5,5,1),(1004,6,6,1),(1009,1,1,1),(1009,2,2,1),(1009,3,3,1),(1009,4,4,1),(1009,5,5,1),(1009,6,6,1),(13,1,1,1),(13,8,2,1),(13,3,3,1),(13,9,4,1),(13,5,5,1),(13,10,6,1),(13,7,7,1),(14,1,1,1),(14,8,2,1),(14,3,3,1),(14,9,4,1),(14,5,5,1),(14,10,6,1),(14,7,7,1),(2001,1,1,1),(2001,14,2,1),(2001,3,3,1),(2001,9,4,1),(2001,5,5,1),(2001,10,6,1),(2001,18,7,1),(2001,6,8,1),(2002,1,1,1),(2002,14,2,1),(2002,3,3,1),(2002,9,4,1),(2002,5,5,1),(2002,10,6,1),(2002,7,7,1),(2003,1,1,1),(2003,12,2,1),(2003,3,3,1),(2003,11,4,1),(2003,5,5,1),(2003,7,6,1),(2003,13,7,1),(2004,1,1,1),(2004,2,2,1),(2004,3,3,1),(2004,5,4,1),(2005,1,1,1),(2005,2,2,1),(2005,3,3,1),(2005,5,4,1),(2005,7,5,1),(2005,9,6,1),(2005,14,7,1),(2005,19,8,1),(3001,1,1,1),(3001,8,2,1),(3001,3,3,1),(3001,9,4,1),(3001,5,5,1),(3001,7,6,1),(3001,6,7,1),(3001,20,8,1),(7001,1,1,1),(7001,8,2,1),(7001,3,3,1),(7001,9,4,1),(7001,5,5,1),(7001,7,6,1),(7001,2,7,1),(7001,21,8,1),(5003,1,1,1),(5003,8,2,1),(5003,3,3,1),(5003,9,4,1),(5003,5,5,1),(5003,16,6,1),(5003,7,7,1),(6001,1,1,1),(6001,8,2,1),(6001,3,3,1),(6001,9,4,1),(6001,5,5,1),(6001,7,6,1),(6003,1,1,1),(6003,2,2,1),(6003,3,3,1),(6003,4,4,1),(6003,5,5,1),(6003,6,6,1),(8001,1,1,1),(8001,8,2,1),(8001,3,3,1),(8001,9,4,1),(8001,5,5,1),(8001,7,6,1),(8001,19,7,1),(13001,1,1,1),(13001,2,2,1),(13001,3,3,1),(13001,5,4,1),(15002,1,1,1),(15002,2,2,1),(15002,3,3,1),(15002,4,4,1),(15002,5,5,1),(15002,6,6,1),(15003,1,1,1),(15003,8,2,1),(15003,3,3,1),(15003,9,4,1),(15003,5,5,1),(15003,7,6,1),(20001,1,1,1),(20001,8,2,1),(20001,3,3,1),(20001,9,4,1),(20001,5,5,1),(20001,7,6,1),(20010,1,1,1),(20010,2,2,1),(20010,3,3,1),(20010,9,4,1),(20010,5,5,1),(20010,7,6,1),(34001,1,1,1),(34001,8,2,1),(34001,3,3,1),(34001,9,4,1),(34001,5,5,1),(34001,2,1,2),(34001,3,2,2),(34001,5,4,2),(34001,23,5,2),(34001,24,6,2),(5001,2,1,2),(5001,3,2,2),(5001,5,3,2),(5001,11,4,2),(55001,1,2,1),(55001,2,3,1),(55001,3,4,1),(55001,17,5,1),(55001,5,6,1),(56002,1,1,1),(56002,8,2,1),(56002,3,3,1),(56002,9,4,1),(56002,5,5,1),(60001,1,1,4),(60001,8,2,4),(60001,3,3,4),(60001,9,4,4),(60001,5,5,4),(60001,10,6,4),(60001,7,7,4),(60002,1,1,4),(60002,8,2,4),(60002,3,3,4),(60002,9,4,4),(60002,5,5,4),(60002,10,6,4),(60002,7,7,4),(35003,1,1,1),(35003,2,2,1),(35003,5,3,1),(35003,7,4,1),(35003,10,5,1),(35003,3,6,1),(61001,1,1,7),(61001,8,2,7),(61001,3,3,7),(61001,9,4,7),(61001,5,5,7),(55001,1,2,3),(55001,2,3,3),(55001,3,4,3),(55001,17,5,3),(55001,5,6,3),(55008,1,1,3),(55008,2,2,3),(55008,3,3,3),(55008,4,4,3),(55008,5,5,3),(55008,6,6,3),(100010,1,1,8),(100010,3,2,8),(100010,5,3,8),(100010,2,4,8),(37001,2,1,2),(37001,3,2,2),(37001,5,3,2),(37001,23,4,2),(37001,24,5,2),(37001,25,6,2),(37001,26,7,2),(1001,2,1,2),(1001,3,2,2),(1001,5,4,2),(1001,23,5,2),(1001,24,6,2),(1008,1,1,5),(1008,2,2,5),(1008,3,3,5),(1008,4,4,5),(1008,5,5,5),(1008,6,6,5),(1009,1,1,5),(1009,2,2,5),(1009,3,3,5),(1009,4,4,5),(1009,5,5,5),(1009,6,6,5),(1009,27,7,5),(1009,28,8,5),(5004,1,1,1),(5004,8,2,1),(5004,3,3,1),(5004,9,4,1),(5004,5,5,1),(5004,16,6,1),(5004,7,7,1),(5004,19,8,1),(30003,1,1,1),(30003,2,2,1),(30003,5,3,1),(30003,3,4,1),(100006,1,1,8),(100006,3,2,8),(100006,5,3,8),(100006,2,4,8),(44002,22,1,2),(44002,3,2,2),(44002,5,3,2),(44002,2,4,2),(44002,11,4,2),(44002,23,5,2),(55009,1,2,3),(55009,2,3,3),(55009,3,4,3),(55009,17,5,3),(55009,5,6,3),(46002,22,1,2),(46002,3,2,2),(46002,5,3,2),(46002,2,4,2),(100029,1,1,8),(100029,3,2,8),(100029,5,3,8),(100029,2,4,8),(6001,2,1,2),(6001,3,2,2),(3006,1,1,1),(3006,8,2,1),(3006,3,3,1),(3006,9,4,1),(3006,5,5,1),(3006,7,6,1),(3006,20,8,1),(100003,1,1,8),(100003,2,4,8),(100003,3,2,8),(100003,5,3,8),(25003,1,1,1),(25003,2,2,1),(25003,5,3,1),(25003,3,4,1),(25003,8,5,1),(25003,9,6,1),(25003,29,7,1),(49003,1,1,1),(49003,2,2,1),(49003,5,3,1),(49003,3,4,1),(49003,8,5,1),(49003,9,6,1),(49003,29,7,1);
UNLOCK TABLES;
/*!40000 ALTER TABLE `printing_course_fields` ENABLE KEYS */;

--
-- Table structure for table `printing_course_header`
--

DROP TABLE IF EXISTS `printing_course_header`;
CREATE TABLE `printing_course_header` (
  `course_id` int(11) NOT NULL,
  `header_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL Default 1,
  PRIMARY KEY  (`course_id`,`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `printing_course_header`
--


/*!40000 ALTER TABLE `printing_course_header` DISABLE KEYS */;
LOCK TABLES `printing_course_header` WRITE;
INSERT INTO `printing_course_header` VALUES (1004,1,1),(1009,1,1),(13,3,1),(14,5,1),(2001,2,1),(2002,2,1),(2003,2,1),(2004,2,1),(2005,6,1),(3001,24,1),(7001,8,1),(5003,3,1),(6003,3,1),(8001,3,1),(13001,4,1),(15002,3,1),(15003,3,1),(20001,3,1),(20010,3,1),(34001,3,1),(34001,10,2),(55001,7,1),(56002,3,1),(5001,12,2),(60001,7,4),(60002,5,4),(61001,3,7),(35003,11,1),(55001,7,3),(55008,1,3),(100010,26,8),(37001,14,2),(1001,10,2),(1008,1,5),(1009,1,5),(5004,3,1),(30003,19,1),(100006,20,8),(44002,21,2),(55009,22,1),(46002,23,2),(100029,25,8),(6001,14,2),(3006,24,1),(100003,27,8),(25003,28,1),(49003,29,1);
UNLOCK TABLES;
/*!40000 ALTER TABLE `printing_course_header` ENABLE KEYS */;

--
-- Table structure for table `printing_fields`
--

DROP TABLE IF EXISTS `printing_fields`;
CREATE TABLE `printing_fields` (
  `field_id` int(11) NOT NULL auto_increment,
  `definition` varchar(128) NOT NULL,
  `default` varchar(128) NOT NULL,
  `xpos` int(11) NOT NULL,
  `data_map` varchar(128) DEFAULT NULL,
  `citation` tinyint(1)  DEFAULT 0,
  PRIMARY KEY  (`field_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `printing_fields`
--


/*!40000 ALTER TABLE `printing_fields` DISABLE KEYS */;
LOCK TABLES `printing_fields` WRITE;
INSERT INTO `printing_fields` VALUES (1,'Driver License','',39,'DRIVERS_LICENSE',0),(2,'Date Of Birth','',43,'DATE_OF_BIRTH',0),(3,'Completion Date','',30,'COMPLETION_DATE',0),(4,'TEA Course Number','',15,'TEA_COURSE_NUMBER',0),(5,'Student Id','',52,'USER_ID',0),(6,'Attendance Reason','',19,'REGULATOR_DEF',0),(7,'Court','',70,'REGULATOR_DEF',0),(8,'Case/Citation/Docket #','',8,'CITATION_NUMBER',1),(9,'Due Date','',56,'DUE_DATE',1),(10,'County','',64,'COUNTY_DEF',0),(11,'Enrollment Date','',32,'LOGIN_DATE',0),(12,'Social Security No.','',21,'SOCIAL_SECURITY_NUMBER',1),(13,'Suspension Reason','',18,'REASON_FOR_SUSPENSION',1),(14,'Ticket Number','',37,'CITATION_NUMBER',1),(15,'CTSI Course Number','HS2016',12,null,0),(16,'Social Security #','',30,'SOCIAL_SECURITY_NUMBER',1),(17,'Corporate Sponsor','',22,'ACCOUNT_NAME',0),(18,'Circuit Court','',45,'CIRCUIT_COURT',0),(19,'Course Length','',37,'COURSE_LENGTH',0),(20,'DMV Clinic Code','0386',29,null,0),(21,'NV-DMV License Code','TS000025547',7,null,0),(22,'Email','',69,'EMAIL',0),(23,'Course Name','DRIVERS EDUCATION',41,null,0),(24,'Course License','PRDS00027648','35',null,0),(25,'Control Number','',35,'CONTROLNUMBER',0),(26,'Learners Permit','',34,'LEARNERSPERMIT',0),(27,'School-Classroom','',23,'LOCATION_ID',0),(28,'Instructor','',54,'INSTRUCTOR_NAME',0),(29,'Course Provider','I DRIVE SAFELY',32,null,0);
UNLOCK TABLES;
/*!40000 ALTER TABLE `printing_fields` ENABLE KEYS */;

--
-- Table structure for table `printing_header`
--

DROP TABLE IF EXISTS `printing_header`;
CREATE TABLE `printing_header` (
  `header_id` int(11) NOT NULL auto_increment,
  `header` varchar(256) NOT NULL,
  PRIMARY KEY  (`header_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `printing_header`
--


/*!40000 ALTER TABLE `printing_header` DISABLE KEYS */;
LOCK TABLES `printing_header` WRITE;
INSERT INTO `printing_header` VALUES (1,'THIS CERTIFIES THE FOLLOWING PERSON COMPLETED AN APPROVED DRIVING SAFETY COURSE'),(2,'THIS CERTIFIES THE FOLLOWING PERSON COMPLETED THE IDS PROGRAM FOR DRIVER IMPROVEMENT (4-hour BDI)'),(3,'THIS CERTIFIES THE FOLLOWING PERSON COMPLETED AN APPROVED HOME STUDY TRAFFIC SAFETY COURSE'),(4,'THIS CERTIFIES THE FOLLOWING PERSON COMPLETED AN IDAHO 6 HOUR POINT REDUCTION PROGRAM'),(5,'I DRIVE SAFELY ONLINE TRAFFIC SCHOOL ENGLISH COURSE - [!IDS::COUNTY!], [!IDS::REGULATOR!]'),(6,'THIS CERTIFIES THE FOLLOWING PERSON COMPLETED THE IDS PROGRAM FOR DRIVER IMPROVEMENT (8-hour BDI)'),(7,'THIS CERTIFIES THE FOLLOWING PERSON COMPLETED THE [!IDS::COURSE DESC!] COURSE'),(8,'THIS CERTIFIES THE FOLLOWING PERSON COMPLETED AN APPROVED 5-HOUR TRAFFIC SAFETY COURSE'),(9,'THIS CERTIFIES THE FOLLOWING PERSON COMPLETED A STATE OF [!IDS::STATE!] CERTIFIED DRIVER EDUCATION COURSE'),(10,''),(11,'THIS CERTIFIES THE FOLLOWING PERSON HAS COMPLETED A AAA-APPROVED ONLINE TRAFFIC SAFETY COURSE'),(12,'THIS CERTIFIES THE FOLLOWING PERSON COMPLETED AN ONLINE HOME STUDY DRIVER EDUCATION COURSE'),(13,'THIS CERTIFIES THE FOLLOWING PERSON COMPLETED NORTH CAROLINA APPROVED DRIVING SAFETY COURSE'),(14,'THIS CERTIFIES THE FOLLOWING PERSON HAS COMPLETED A 30-HOUR OKLAHOMA APPROVED DRIVER EDUCATION COURSE<BR>AND 55 HOURS OF BEHIND THE WHEEL'),(15,'THIS CERTIFIES THE FOLLOWING PERSON COMPLETED AN APPROVED ONLINE MATURE DRIVING SAFETY COURSE'),(16,'THIS CERTIFIES THE FOLLOWING PERSON COMPLETED AN OHIO ADULT REMEDIAL DRIVER COURSE'),(17,'THIS CERTIFIES THE FOLLOWING PERSON COMPLETED AN APPROVED ONLINE MATURE DRIVING SAFETY COURSE'),(18,'THIS CERTIFIES THE FOLLOWING PERSON HAS COMPLETED A 30-HOUR COLORADO APPROVED DRIVER EDUCATION COURSE'),(19,'THIS CERTIFIES THE FOLLOWING PERSON HAS COMPLETED A BHS APPROVED DRIVER IMPROVEMENT COURSE'),(20,'THIS CERTIFIES THE FOLLOWING PERSON HAS COMPLETED A MATURE DRIVER EDUCATION COURSE APPROVED BY THE COLORADO DEPARTMENT OF REVENUE'),(21,'THIS CERTIFIES THE FOLLOWING PERSON HAS COMPLETED A DPS APPROVED DRIVER EDUCATION COURSE AND 14 HOURS OF<BR>BEHIND-THE-WHEEL'),(22,'THIS CERTIFIES THE FOLLOWING PERSON HAS COMPLETED THE IDS VAN DRIVING SAFETY COURSE'),(23,'THIS CERTIFIES THE FOLLOWING PERSON HAS COMPLETED <BR> A 30-HOUR VIRGINIA APPROVED HOME-SCHOOLED DRIVER EDUCATION COURSE'),(24,'THIS CERTIFIES THE FOLLOWING PERSON COMPLETED A DMV APPROVED 8-HOUR HOME STUDY TRAFFIC SAFETY COURSE'),(25,'THIS CERTIFIES THE FOLLOWING PERSON COMPLETED A NEVADA DMV CERTIFIED MATURE DRIVER EDUCATION COURSE'),(26,'THIS CERTIFIES THE FOLLOWING PERSON HAS COMPLETED A FLORIDA DHSMV APPROVED ONLINE SENIOR CITIZEN DISCOUNT<BR>INSURANCE COURSE'),(27,'THIS CERTIFIES THE FOLLOWING PERSON HAS COMPLETED AN ONLINE SENIOR CITIZEN DISCOUNT INSURANCE COURSE'),(28,'THIS CERTIFIES THE FOLLOWING PERSON HAS COMPLETED AN INDIANA BMV APPROVED BASIC DRIVER SAFETY COURSE'),(29,'THIS CERTIFIES THE FOLLOWING PERSON COMPLETED THE 4 HOUR UTAH ONLINE TRAFFIC SCHOOL PROGRAM');
UNLOCK TABLES;
/*!40000 ALTER TABLE `printing_header` ENABLE KEYS */;

--
-- Table structure for table `printing_printers`
--

DROP TABLE IF EXISTS `printing_printers`;
CREATE TABLE `printing_printers` (
  `printer_id` int(11) NOT NULL auto_increment,
  `printer_key` char(2) NOT NULL,
  `printer_type` varchar(4) NOT NULL,
  `printer_name` varchar(16) NOT NULL,
  `printer_ip` varchar(16) NOT NULL,
  PRIMARY KEY  (`printer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `printing_printers`
--


/*!40000 ALTER TABLE `printing_printers` DISABLE KEYS */;
LOCK TABLES `printing_printers` WRITE;
INSERT INTO `printing_printers` VALUES (1,'TX','PNG','HP-PNG-TX','172.20.2.19'),(2,'TX','PDF','HP-PDF-TX','172.20.2.19'),(3,'TX','TXT','hp8000-tx','172.20.2.19'),(4,'CA','PNG','HP-PNG','172.20.2.19'),(5,'CA','PDF','HP-PDF','172.20.2.19'),(6,'CA','TXT','hp8000','172.20.2.19'),(7,'TX','PDF2','HP-PDF2-TX','172.20.2.19'),(8,'CA','PDF2','HP-PDF2','172.20.2.19');
UNLOCK TABLES;


--
-- Table structure for table `printing_course_alias`
--

DROP TABLE IF EXISTS `printing_course_alias`;
CREATE TABLE `printing_course_alias` (
  `course_id` int(11)  NOT NULL,
  `alias_course_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL Default 1,
  PRIMARY KEY  (`course_id`,`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


INSERT INTO `printing_course_alias` VALUES (1006,1003,1),(1001,1003,1),(1008 , 1004,1),(1,13,1),(2 , 13 ,1),(5 , 13 ,1),(6 , 13,1),(11 , 13,1),(12 , 13,1),(15 , 13,1),(16 , 13,1),(1010 , 1004,1),(3002,3001,1),(6002,6001,1),(3003,3001,1),(3004,3001,1),(3005,3001,1),(7002,7001,1),(5001,5003,1),(5002,5003,1),(5005,5003,1),(5006,5003,1),(6003,6001,1),(6004,6003,1),(15001,15003,1),(55000,55001,1),(55002,55001,1),(55003,55001,1),(55006,55001,1),(55005,55001,1),(55007,55001,1),(60003,60001,4),(60006,60001,4),(60009,60001,4),(60010,60002,4),(60011,60001,4),(60030,60001,4),(60020,60001,4),(20002,20001,1),(55008,1004,1),(61002,61001,7),(61003,61001,7),(55000,55001,3),(55002,55001,3),(55003,55001,3),(55006,55001,3),(55005,55001,3),(55007,55001,3),(1007,1005,5),(17,14,1);

--
-- Table structure for table `printing_course_alias`
--

DROP TABLE IF EXISTS `printing_course_disclaimer`;
CREATE TABLE `printing_course_disclaimer` (
  `course_id` int(11)  NOT NULL,
  `disclaimer_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL Default 1,
  PRIMARY KEY  (`course_id`,`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

LOCK TABLES `printing_course_disclaimer` WRITE;
INSERT INTO `printing_course_disclaimer` VALUES (1004,2,1),(1009,2,1),(13,2,1),(14,2,1),(2001,1,1),(2002,1,1),(2003,1,1),(2004,1,1),(2005,1,1),(3001,2,1),(7001,2,1),(5003,2,1),(6003,2,1),(8001,2,1),(13001,2,1),(15002,2,1),(15003,2,1),(20001,2,1),(20010,2,1),(34001,2,1),(34001,3,2),(55001,2,1),(56002,2,1),(5001,2,2),(60001,2,4),(60002,2,4),(61001,2,7),(35003,2,1),(55001,2,3),(55008,2,3),(100010,2,8),(37001,4,2),(1001,5,2),(1008,2,5),(1009,2,5),(5004,2,1),(30003,2,1),(100006,2,8),(44002,2,2),(55009,2,3),(46002,2,2),(100029,2,8),(6001,4,2),(3006,2,1),(100003,2,8),(25003,2,1),(49003,2,1);

UNLOCK TABLES;
--
-- Table structure for table `printing_course_header`
--

DROP TABLE IF EXISTS `printing_course_signature`;
CREATE TABLE `printing_course_signature` (
  `course_id` int(11) NOT NULL,
  `signature_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL Default 1,
  PRIMARY KEY  (`course_id`,`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT INTO `printing_course_signature` VALUES (1004,1,1),(1009,1,1),(13,2,1),(14,2,1),(2001,1,1),(2002,1,1),(2003,1,1),(2004,1,1),(2005,1,1),(3001,1,1),(7001,1,1),(5003,1,1),(6003,1,1),(8001,1,1),(13001,1,1),(15002,1,1),(15003,1,1),(20001,1,1),(20010,1,1),(34001,1,1),(34001,2,2),(55001,1,1),(56002,1,1),(5001,1,2),(60001,1,4),(60002,2,4),(61001,1,7),(35003,1,1),(55001,1,3),(55008,1,3),(100010,1,8),(37001,2,2),(1001,2,2),(1008,1,5),(1009,1,5),(5004,1,1),(30003,1,1),(100006,1,8),(44002,2,2),(55009,1,3),(46002,2,2),(100029,1,8),(6001,2,2),(3006,1,1),(100003,1,8),(25003,1,1),(49003,1,1);
--
-- Table structure for table `printing_printers`
--

DROP TABLE IF EXISTS `printing_signature`;
CREATE TABLE `printing_signature` (
  `signature_id` int(11) NOT NULL auto_increment,
  `instructor` varchar(64) NOT NULL,
  `instructor_signature` tinyint(1),
  `student_signature` tinyint(1),
  `x_offset` int(1),
  PRIMARY KEY  (`signature_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT INTO `printing_signature` values (1,'(Authorized Signature of I DRIVE SAFELY)',1,0,NULL),(2,'(Rick Hernandez, CEO - I DRIVE SAFELY)'  ,1,1,NULL),(3,'(Authorized Signature of I DRIVE SAFELY)' ,1,1,NULL);

--
-- Table structure for table `printing_disclaimer`
--

DROP TABLE IF EXISTS `printing_disclaimer`;
CREATE TABLE `printing_disclaimer` (
  `disclaimer_id` int(11) NOT NULL auto_increment,
  `disclaimer` varchar(255) NOT NULL,
  PRIMARY KEY  (`disclaimer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `printing_header`
--


/*!40000 ALTER TABLE `printing_header` DISABLE KEYS */;
LOCK TABLES `printing_disclaimer` WRITE;
INSERT INTO `printing_disclaimer` VALUES (1,'IN COMPLIANCE WITH SECTION 318.1451,~FLORIDA STATUTES - RULE CHAPTER NO: 15A-8.001-8.018.'),(2,'I CERTIFY UNDER PENALTY OF PERJURY THAT, TO THE BEST OF MY KNOWLEDGE,~THE FOREGOING IS TRUE AND CORRECT.~(PERJURY IS PUNISHABLE BY IMPRISONMENT, FINE OR BOTH)'),(3,'THIS CERTIFIES THE FOLLOWING PERSON COMPLETED A 30 HR~DRIVER EDUCATION COURSE IN COMPLIANCE WITH~THE STATE OF NEVADA'),(4,'THIS CERTIFIES THE FOLLOWING PERSON HAS COMPLETED A 30-HOUR~OKLAHOMA APPROVED DRIVER EDUCATION COURSE~AND 55 HOURS OF BEHIND THE WHEEL'),(5,'THIS CERTIFIES THE FOLLOWING PERSON COMPLETED A 30 HR~DRIVER EDUCATION COURSE IN COMPLIANCE WITH~THE STATE OF COLORADO');
UNLOCK TABLES;


DROP TABLE IF EXISTS `printing_template_type`;
CREATE TABLE `printing_template_type` (
  `template_type_id` int(11)  NOT NULL,
  `template_type` varchar(10) NOT NULL,
  PRIMARY KEY  (`template_type_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT INTO printing_template_type values(1,'PDF'),(2,'TEXT/HTML');

DROP TABLE IF EXISTS `printing_course_templates`;
CREATE TABLE `printing_course_templates` (
  `course_id` int(11)  NOT NULL,
  `top_template` varchar(100) NOT NULL,
  `bottom_template` varchar(100),
  `coversheet_template` varchar(100),
  `template_type_id` int(11) NOT NULL Default 1,
  `product_id` int(11) NOT NULL Default 1,
  `default_course_id` int(11)  Default 0,
  PRIMARY KEY  (`course_id`,`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT INTO `printing_course_templates` VALUES (1003,'TX_Template.pdf','','DIP_Email_Accompany.tmpl',1,1,0), (1004,'CA_Template_Court.pdf','CA_Template_Student.pdf','DIP_Email_Accompany.tmpl',1,1,0),(1009,'CA_Template_Court.pdf','CA_Template_Student.pdf','DIP_Email_Accompany.tmpl',1,1,0),(13,'CA_Template_Court.pdf','CA_Template_Student.pdf','DIP_Email_Accompany.tmpl',1,1,0),(14,'CA_Template_Court.pdf','CA_Template_Student.pdf','DIP_Email_Accompany.tmpl',1,1,0),(2001,'CA_Template_Court.pdf','CA_Template_Student.pdf','DIP_Email_Accompany.tmpl',1,1,0),(2002,'CA_Template_Court.pdf','CA_Template_Student.pdf','DIP_Email_Accompany.tmpl',1,1,0),(2003,'CA_Template_Court.pdf','CA_Template_Student.pdf','DIP_Email_Accompany.tmpl',1,1,0),(2004,'CA_Template_Court.pdf','CA_Template_Student.pdf','DIP_Email_Accompany.tmpl',1,1,0),(2005,'CA_Template_Court.pdf','CA_Template_Student.pdf','DIP_Email_Accompany.tmpl',1,1,0),(3001,'CA_Template_Court.pdf','CA_Template_Student.pdf','DIP_Email_Accompany.tmpl',1,1,0),(7001,'CA_Template_Court.pdf','CA_Template_Student.pdf','DIP_Email_Accompany.tmpl',1,1,0),(5003,'CA_Template_Court.pdf','CA_Template_Student.pdf','DIP_Email_Accompany.tmpl',1,1,0),(6003,'CA_Template_Court.pdf','CA_Template_Student.pdf','DIP_Email_Accompany.tmpl',1,1,0),(8001,'CA_Template_Court.pdf','CA_Template_Student.pdf','DIP_Email_Accompany.tmpl',1,1,0),(13001,'CA_Template_Court.pdf','CA_Template_Student.pdf','DIP_Email_Accompany.tmpl',1,1,0),(15002,'CA_Template_Court.pdf','CA_Template_Student.pdf','DIP_Email_Accompany.tmpl',1,1,0),(15003,'CA_Template_Court.pdf','CA_Template_Student.pdf','DIP_Email_Accompany.tmpl',1,1,0),(20001,'DE_Certificate.tmpl','','DE_CoverSheet.tmpl',2,1,0),(20010,'CA_Template_Court.pdf','CA_Template_Student.pdf','DIP_Email_Accompany.tmpl',1,1,0),(34001,'CA_Template_Court.pdf','CA_Template_Student_Teen.pdf','TEEN_Email_Accompany.tmpl',1,2,0),(34001,'CA_Template_Court.pdf','CA_Template_Student.pdf','DIP_Email_Accompany.tmpl',1,1,0),(55001,'CA_Template_Court.pdf','CA_Template_Student.pdf','DIP_Email_Accompany.tmpl',1,1,0),(56002,'CA_Template_Court.pdf','CA_Template_Student.pdf','DIP_Email_Accompany.tmpl',1,1,1),(60001,'TSTG_Template_Court.pdf','TSTG_Template_Student.pdf','TSTG_Email_Accompany.tmpl',1,4,1),(60002,'TSTG_Template_Court.pdf','TSTG_Template_Student.pdf','TSTG_Email_Accompany.tmpl',1,4,0),(61001,'AZTS_Template_Court.pdf','AZTS_Template_Student.pdf','AZTS_Email_Accompany.tmpl',1,7,1),(35003,'AAA_Template_Court.pdf','AAA_Template_Student.pdf','DIP_Email_Accompany.tmpl',1,1,0),(55001,'CA_Template_Court.pdf','CA_Template_Student.pdf','DIP_Email_Accompany.tmpl',1,3,1),(55008,'CA_Template_Court.pdf','CA_Template_Student.pdf','DIP_Email_Accompany.tmpl',1,3,0),(100010,'CA_Template_Court.pdf','CA_Template_Student.pdf','DIP_Email_Accompany.tmpl',1,8,0),(37001,'CA_Template_Court.pdf','CA_Template_Student_Teen.pdf','TEEN_Email_Accompany.tmpl',1,2,0),(5001,'','','',1,2,0),(1001,'CA_Template_Court.pdf','CA_Template_Student_Teen.pdf','TEEN_Email_Accompany.tmpl',1,2,1),(1005,'TX_Template.pdf','','DIP_Email_Accompany.tmpl',1,5,0), (1008,'CA_Template_Court.pdf','CA_Template_Student.pdf','DIP_Email_Accompany.tmpl',1,5,1),(1009,'CA_Template_Court.pdf','CA_Template_Student.pdf','DIP_Email_Accompany.tmpl',1,5,0),(5004,'CA_Template_Court.pdf','CA_Template_Student.pdf','DIP_Email_Accompany.tmpl',1,1,0),(30003,'ME_Template_Court.pdf','ME_Template_Student.pdf','DIP_Email_Accompany.tmpl',1,1,0),(100006,'CA_Template_Court.pdf','CA_Template_Student.pdf','DIP_Email_Accompany.tmpl',1,8,0),(55009,'CA_Template_Court.pdf','CA_Template_Student.pdf','DIP_Email_Accompany.tmpl',1,3,0),(100029,'CA_Template_Court.pdf','CA_Template_Student.pdf','DIP_Email_Accompany.tmpl',1,8,0),(6001,'CO_TEEN_Template_Court.pdf','','',1,2,0),(3006,'CA_Template_Court.pdf','CA_Template_Student.pdf','DIP_Email_Accompany.tmpl',1,1,0),(100003,'CA_Template_Court.pdf','CA_Template_Student.pdf','DIP_Email_Accompany.tmpl',1,8,1),(25003,'CA_Template_Court.pdf','CA_Template_Student.pdf','DIP_Email_Accompany.tmpl',1,1,0),(49003,'CA_Template_Court.pdf','CA_Template_Student.pdf','DIP_Email_Accompany.tmpl',1,1,0);
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

--
-- Table structure for table `printing_course_miscellaneous_data`
--

DROP TABLE IF EXISTS `printing_course_miscellaneous_data`;
CREATE TABLE `printing_course_miscellaneous_data` (
  `field_id` int(11) NOT NULL,   
  `course_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `value` varchar(128) NULL,
  PRIMARY KEY  (`course_id`,`product_id`,`field_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `printing_course_miscellaneous_data`
--


LOCK TABLES `printing_course_miscellaneous_data` WRITE;
INSERT INTO `printing_course_miscellaneous_data` VALUES (13,'41004','1','License Reinstatement'),(4,'1009','1','SP225'),(19,'1001','1','6 Hours'),(19,'1002','1','6 Hours'),(19,'1003','1','6 Hours'),(19,'1004','1','6 Hours'),(19,'1006','1','6 Hours'),(19,'1009','1','6 Hours'),(19,'1010','1','6 Hours'),(19,'2001','1','4 Hours'),(19,'2002','1','4 Hours'),(19,'2003','1','4 Hours'),(19,'2004','1','4 Hours'),(19,'4001','1','2 Hours'),(19,'4002','1','6 Hours'),(19,'5001','1','6 Hours'),(19,'5002','1','6 Hours'),(19,'5003','1','6 Hours'),(19,'5004','1','6 Hours'),(19,'5005','1','6 Hours'),(19,'5006','1','6 Hours'),(19,'7001','1','5 Hours'),(19,'7002','1','5 Hours'),(19,'13001','1','6 Hours'),(19,'20001','1','6 Hours'),(19,'20002','1','6 Hours'),(19,'34001','1','4 Hours'),(19,'20010','1','6 Hours'),(19,'14002','1','6 Hours'),(19,'14003','1','6 Hours'),(19,'14004','1','6 Hours'),(19,'14005','1','4 Hours'),(19,'14006','1','4 Hours'),(19,'14007','1','4 Hours'),(19,'51004','1','4 Hours'),(19,'51007','1','4 Hours'),(19,'35003','1','8 Hours'),(19,'41003','1','8 Hours'),(19,'41004','1','8 Hours'),(19,'41005','1','8 Hours'),(6,1009,1,'Continuing Education'),(6,1009,5,'INSERVICE'),(6,3001,1,'Add Safe Driving Points(VOL)'),(6,3002,1,'Insurance Discount(INS)'),(6,3003,1,'DMV Mandated'),(6,3004,1,'Fine/Fee Reduction(NCT)'),(6,3005,1,'Point Dismissal(YCT)'),(6,3006,1,'Court-Referred for Non-Residents'),(6,2001,1,'Elected to Attend'),(4,1010,1,'CP225'),(4,1008,5,'CP225'),(4,55008,3,'CP225'),(15,60001,4,'HS2020'),(23,44002,2,'Texas Online Parent-Taught Driver Education Course #109'),(15,13,1,'HS2016');
UNLOCK TABLES;

