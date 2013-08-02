-- phpMyAdmin SQL Dump
-- version 2.10.0.2
-- http://www.phpmyadmin.net
-- 
-- 主机: localhost
-- 生成日期: 2013 年 06 月 22 日 00:28
-- 服务器版本: 5.0.27
-- PHP 版本: 4.3.11RC1-dev

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";

-- 
-- 数据库: `biyifei_development`
-- 

-- --------------------------------------------------------

-- 
-- 表的结构 `flightlines`
-- 

CREATE TABLE `flightlines` (
  `id` int(11) NOT NULL auto_increment,
  `fltcombin` varchar(255) collate utf8_unicode_ci default NULL,	-- 航班号组合如[CA1301CA1310,CA2301CA2310]或[CZ3339,CZ3338]
  `traveltype` tinyint(1) NOT NULL,	-- 1或2或3分别表示ow或rt或自定义行程
  `prikey_id` int(11) NOT NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `index_flightlines_on_prikey_id` (`prikey_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=1 ;

-- 
-- 导出表中的数据 `flightlines`
-- 


-- --------------------------------------------------------

-- 
-- 表的结构 `prices`
-- 

CREATE TABLE `prices` (
  `id` int(11) NOT NULL auto_increment,
  `flightline_id` int(11) NOT NULL,
  `hashid_date` int(8) NOT NULL,	-- 20130901
  `hashvalue_bunk` text collate utf8_unicode_ci,	-- JSON
  `hashvalue_price` text collate utf8_unicode_ci,	-- JSON
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `index_prices_on_flightline_id` (`flightline_id`),
  KEY `index_prices_on_hashid_date` (`hashid_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=1 ;

-- 
-- 导出表中的数据 `prices`
-- 


-- --------------------------------------------------------

-- 
-- 表的结构 `prikeys`
-- 

CREATE TABLE `prikeys` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) collate utf8_unicode_ci default NULL,	-- 带航空公司查询can/lax/ow/cz/20130901/
  `querykey_id` int(11) NOT NULL,
  `hashid_date` int(8) NOT NULL,	-- 20130901
  `hashvalue_flts` varchar(255) collate utf8_unicode_ci default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `index_prikeys_on_name` (`name`),
  KEY `index_prikeys_on_querykey_id` (`querykey_id`),
  KEY `index_prikeys_on_hashid_date` (`hashid_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=1 ;

-- 
-- 导出表中的数据 `prikeys`
-- 


-- --------------------------------------------------------

-- 
-- 表的结构 `querykeys`
-- 

CREATE TABLE `querykeys` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) collate utf8_unicode_ci NOT NULL,	-- 不带航空公司查询can/lax/ow/20130901/
  `carriercode` varchar(255) collate utf8_unicode_ci default NULL,	-- [CZ,CA,HU,KE]
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `index_querykeys_on_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=1 ;

-- 
-- 导出表中的数据 `querykeys`
-- 


-- --------------------------------------------------------

-- 
-- 表的结构 `schema_migrations`
-- 

CREATE TABLE `schema_migrations` (
  `version` varchar(255) collate utf8_unicode_ci NOT NULL,
  UNIQUE KEY `unique_schema_migrations` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- 
-- 导出表中的数据 `schema_migrations`
-- 

INSERT INTO `schema_migrations` (`version`) VALUES 
('20130621142329'),
('20130621142341'),
('20130621142410'),
('20130621142425'),
('20130621142440');

-- --------------------------------------------------------

-- 
-- 表的结构 `segments`
-- 

CREATE TABLE `segments` (
  `id` int(11) NOT NULL auto_increment,
  `flightline_id` int(11) NOT NULL,
  `segnum` int(1) NOT NULL,	-- 航段数量
  `segmentinfo` text collate utf8_unicode_ci,	-- JSON
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `index_segments_on_flightline_id` (`flightline_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=1 ;

-- 
-- 导出表中的数据 `segments`
-- 


-- 
-- 限制导出的表
-- 

-- 
-- 限制表 `flightlines`
-- 
ALTER TABLE `flightlines`
  ADD CONSTRAINT `fk_flightline_prikeys` FOREIGN KEY (`prikey_id`) REFERENCES `prikeys` (`id`);

-- 
-- 限制表 `prices`
-- 
ALTER TABLE `prices`
  ADD CONSTRAINT `fk_price_flightlines` FOREIGN KEY (`flightline_id`) REFERENCES `flightlines` (`id`);

-- 
-- 限制表 `prikeys`
-- 
ALTER TABLE `prikeys`
  ADD CONSTRAINT `fk_prikey_querykeys` FOREIGN KEY (`querykey_id`) REFERENCES `querykeys` (`id`);

-- 
-- 限制表 `segments`
-- 
ALTER TABLE `segments`
  ADD CONSTRAINT `fk_segment_flightlines` FOREIGN KEY (`flightline_id`) REFERENCES `flightlines` (`id`);
