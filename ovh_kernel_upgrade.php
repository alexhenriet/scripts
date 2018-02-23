<?php

$currentVersion = php_uname('r');
printf("Current kernel version: %s\n", $currentVersion);
preg_match('/^([0-9]+\.[0-9]+)\.([0-9]+)-(.+-.*)$/', $currentVersion, $matches);
$majorVersion = $matches[1];
$currentMinorVersion = $matches[2];
$suffix = $matches[3];

$ftp = ftp_connect('ftp.ovh.net');
ftp_login($ftp, 'anonymous', 'user@example.com');
ftp_chdir($ftp, '/made-in-ovh/bzImage');
$files = ftp_nlist($ftp, '.');
$minorVersion = null;
foreach ($files as $file) {
  if (preg_match('/^' . $majorVersion . '\.([0-9]+)$/', $file, $matches)) {
    if ($matches[1] > $minorVersion) {
      $minorVersion = $matches[1];
    }	  
  }
}
$lastVersion = $majorVersion . '.' . $minorVersion;
printf("Last available version: %s\n", $lastVersion);
if ($currentMinorVersion >= $minorVersion) {
  printf("Nothing to update, terminating.\n");
  exit(0);
}
$bzFile = sprintf('bzImage-%s-%s', $lastVersion, $suffix);
$mapFile = sprintf('System.map-%s-%s', $lastVersion, $suffix);
ftp_chdir($ftp, $lastVersion);
printf("Downloading bzFile: /tmp/%s\n", $bzFile);
if (!is_file($bzFile)) {
  ftp_get($ftp, '/tmp/' . $bzFile, $bzFile, FTP_BINARY);
}
printf("Download mapFile: /tmp/%s\n", $mapFile);
if (!is_file($mapFile)) {
  ftp_get($ftp, '/tmp/' . $mapFile, $mapFile, FTP_BINARY);
}
ftp_close($ftp);
printf("TODO:\n");
printf("1. mv /tmp/*%s-%s /boot/\n", $lastVersion, $suffix);
printf("2. update-grub\n");
printf("3. reboot\n");
