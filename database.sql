CREATE TABLE IF NOT EXISTS `mh_brakes` (
    `id` int(10) NOT NULL AUTO_INCREMENT,
    `plate` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
    `wheel_lf` int(10) NOT NULL DEFAULT 0,
    `wheel_rf` int(10) NOT NULL DEFAULT 0,
    `wheel_lr` int(10) NOT NULL DEFAULT 0,
    `wheel_rr` int(10) NOT NULL DEFAULT 0,
    `line_empty` int(10) NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC; 
