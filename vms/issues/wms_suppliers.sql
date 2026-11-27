CREATE TABLE `suppliers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `websites_id` int(11) DEFAULT NULL,
  `supplier_name` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `supplier_short_name` varchar(200) DEFAULT NULL,
  `supplier_abn` varchar(20) DEFAULT NULL,
  `bank_acc_name` varchar(50) DEFAULT NULL,
  `bank_name` varchar(100) DEFAULT NULL,
  `bank_bsb` varchar(50) DEFAULT NULL,
  `bank_acc_number` varchar(30) DEFAULT NULL,
  `payment_term` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2043 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC